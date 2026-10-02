import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/features/transactions/domain/ledger_effects.dart';
import 'package:expensetrackerpro/features/transactions/domain/monthly_summary.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction_query.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction_validator.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction tx(
  TransactionType type,
  int amount, {
  String id = 't',
  String category = 'food',
  String? account,
  String? toAccount,
  String? card,
  String? loan,
  String? debt,
  DateTime? date,
  TransactionStatus status = TransactionStatus.cleared,
  String description = '',
}) {
  final at = date ?? DateTime(2026, 3, 10);
  return Transaction(
    id: id,
    date: at,
    amountMinor: amount,
    type: type,
    categoryId: category,
    accountId: account,
    toAccountId: toAccount,
    creditCardId: card,
    loanId: loan,
    borrowLendId: debt,
    status: status,
    description: description,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  group('Money', () {
    test('parses user input into minor units', () {
      expect(Money.parse('1,234.5'), 123450);
      expect(Money.parse('₹ 99'), 9900);
      expect(Money.parse('0.07'), 7);
      expect(Money.parse(''), isNull);
      expect(Money.parse('-5'), isNull);
      expect(Money.parse('1.234'), isNull);
      expect(Money.parse('abc'), isNull);
    });

    test('round-trips editable text', () {
      expect(Money.toEditable(123450), '1234.50');
      expect(Money.toEditable(9900), '99');
      expect(Money.parse(Money.toEditable(5)), 5);
    });
  });

  group('LedgerEffects (account balance & card outstanding)', () {
    test('expense and income move the account', () {
      expect(LedgerEffects.of(tx(TransactionType.expense, 500, account: 'a')).accounts, {'a': -500});
      expect(
        LedgerEffects.of(tx(TransactionType.income, 900, account: 'a', category: 'salary')).accounts,
        {'a': 900},
      );
    });

    test('transfer debits source and credits destination', () {
      final d = LedgerEffects.of(
        tx(TransactionType.transfer, 1000, account: 'a', toAccount: 'b'),
      );
      expect(d.accounts, {'a': -1000, 'b': 1000});
    });

    test('card expense raises outstanding; payment lowers it and debits account', () {
      expect(LedgerEffects.of(tx(TransactionType.creditCardExpense, 300, card: 'c')).cards, {'c': 300});
      final pay = LedgerEffects.of(
        tx(TransactionType.creditCardPayment, 300, card: 'c', account: 'a'),
      );
      expect(pay.cards, {'c': -300});
      expect(pay.accounts, {'a': -300});
    });

    test('refund goes back to the card when one is set', () {
      expect(LedgerEffects.of(tx(TransactionType.refund, 50, card: 'c')).cards, {'c': -50});
      expect(LedgerEffects.of(tx(TransactionType.refund, 50, account: 'a')).accounts, {'a': 50});
    });

    test('pending transactions have no effect', () {
      expect(
        LedgerEffects.of(tx(TransactionType.expense, 500, account: 'a', status: TransactionStatus.pending)).isEmpty,
        isTrue,
      );
    });

    test('edit diff reverses the old effect and applies the new one', () {
      final before = tx(TransactionType.expense, 500, account: 'a');
      final after = tx(TransactionType.expense, 700, account: 'b');
      final d = LedgerEffects.change(before, after);
      expect(d.accounts, {'a': 500, 'b': -700});
      expect(LedgerEffects.change(before, before).isEmpty, isTrue);
      expect(LedgerEffects.change(before, null).accounts, {'a': 500});
    });

    test('total equals the sum of individual effects', () {
      final all = [
        tx(TransactionType.income, 10000, account: 'a', category: 'salary'),
        tx(TransactionType.expense, 2500, account: 'a'),
        tx(TransactionType.transfer, 1000, account: 'a', toAccount: 'b'),
        tx(TransactionType.creditCardExpense, 4000, card: 'c'),
        tx(TransactionType.creditCardPayment, 3000, card: 'c', account: 'a'),
      ];
      final total = LedgerEffects.total(all);
      expect(total.accounts, {'a': 3500, 'b': 1000});
      expect(total.cards, {'c': 1000});
    });
  });

  group('TransactionValidator', () {
    test('accepts valid combinations', () {
      expect(TransactionValidator.validate(tx(TransactionType.expense, 1)), isEmpty);
      expect(
        TransactionValidator.validate(tx(TransactionType.creditCardExpense, 1, card: 'c')),
        isEmpty,
      );
    });

    test('rejects invalid combinations', () {
      expect(
        TransactionValidator.validate(tx(TransactionType.expense, 0)),
        contains(TransactionIssue.amountNotPositive),
      );
      expect(
        TransactionValidator.validate(tx(TransactionType.creditCardExpense, 5)),
        contains(TransactionIssue.cardRequired),
      );
      expect(
        TransactionValidator.validate(tx(TransactionType.transfer, 5, account: 'a', toAccount: 'a', category: 'transfer')),
        contains(TransactionIssue.sameTransferAccounts),
      );
      expect(
        TransactionValidator.validate(tx(TransactionType.transfer, 5, account: 'a', category: 'transfer')),
        contains(TransactionIssue.destinationAccountRequired),
      );
      expect(
        TransactionValidator.validate(tx(TransactionType.loanPayment, 5, category: 'loan_emi')),
        contains(TransactionIssue.loanRequired),
      );
      expect(
        TransactionValidator.validate(tx(TransactionType.income, 5, category: 'food')),
        contains(TransactionIssue.categoryMismatch),
      );
      expect(
        TransactionValidator.validate(tx(TransactionType.lent, 5, category: 'debt')),
        contains(TransactionIssue.debtRecordRequired),
      );
    });
  });

  group('MonthlySummary', () {
    test('computes income, spending, EMI, savings and breakdowns', () {
      final s = MonthlySummary.compute([
        tx(TransactionType.income, 100000, category: 'salary', account: 'a'),
        tx(TransactionType.expense, 20000, account: 'a', date: DateTime(2026, 3, 2)),
        tx(TransactionType.creditCardExpense, 15000, card: 'c', category: 'shopping', date: DateTime(2026, 3, 2)),
        tx(TransactionType.refund, 5000, card: 'c', category: 'shopping', date: DateTime(2026, 3, 4)),
        tx(TransactionType.creditCardPayment, 9000, card: 'c', account: 'a', category: 'card_payment'),
        tx(TransactionType.transfer, 7000, account: 'a', toAccount: 'b', category: 'transfer'),
        tx(TransactionType.loanPayment, 30000, loan: 'l', category: 'loan_emi'),
        tx(TransactionType.borrowed, 4000, debt: 'd', category: 'debt'),
        tx(TransactionType.lent, 3000, debt: 'd2', category: 'debt'),
        tx(TransactionType.expense, 999, status: TransactionStatus.pending),
      ]);
      expect(s.income, 100000);
      expect(s.spending, 30000); // 20000 + 15000 − 5000
      expect(s.cardSpending, 10000);
      expect(s.emi, 30000);
      expect(s.savings, 40000);
      expect(s.borrowed, 4000);
      expect(s.lent, 3000);
      expect(s.pending, 999);
      expect(s.byCategory, {'food': 20000, 'shopping': 10000});
      expect(s.byCategory.keys.first, 'food');
      expect(s.byDay, {2: 35000});
      expect(s.byAccount, {'a': 20000});
      expect(s.byCard, {'c': 10000});
      expect(s.savingsRate, closeTo(.4, 1e-9));
    });

    test('empty input gives zeros and no savings rate', () {
      final s = MonthlySummary.compute(const []);
      expect(s.spending, 0);
      expect(s.savingsRate, isNull);
    });
  });

  group('TransactionQuery', () {
    final list = [
      tx(TransactionType.expense, 500, id: '1', description: 'Swiggy dinner', account: 'a', date: DateTime(2026, 3, 1)),
      tx(TransactionType.creditCardExpense, 2500, id: '2', category: 'shopping', card: 'c', description: 'Amazon', date: DateTime(2026, 3, 3)),
      tx(TransactionType.income, 90000, id: '3', category: 'salary', account: 'a', description: 'Salary', date: DateTime(2026, 3, 2)),
    ];
    String text(Transaction t) => '${t.description} ${t.categoryId}';

    test('filters by type, category, account, card and amount', () {
      expect(
        TransactionQuery.apply(list, const TransactionFilter(types: {TransactionType.income}), searchText: text).map((t) => t.id),
        ['3'],
      );
      expect(
        TransactionQuery.apply(list, const TransactionFilter(cardIds: {'c'}), searchText: text).map((t) => t.id),
        ['2'],
      );
      expect(
        TransactionQuery.apply(list, const TransactionFilter(accountIds: {'a'}, maxAmountMinor: 1000), searchText: text).map((t) => t.id),
        ['1'],
      );
    });

    test('search matches every term case-insensitively', () {
      expect(
        TransactionQuery.apply(list, const TransactionFilter(text: 'swiggy FOOD'), searchText: text).map((t) => t.id),
        ['1'],
      );
    });

    test('sorts', () {
      expect(
        TransactionQuery.apply(list, const TransactionFilter(), searchText: text).map((t) => t.id),
        ['2', '3', '1'],
      );
      expect(
        TransactionQuery.apply(list, const TransactionFilter(sort: TransactionSort.largest), searchText: text).map((t) => t.id),
        ['3', '2', '1'],
      );
    });
  });

  group('Transaction serialization', () {
    test('round-trips through a map', () {
      final original = tx(TransactionType.transfer, 1234, account: 'a', toAccount: 'b', category: 'transfer')
          .copyWith(tags: ['x'], notes: 'n');
      final back = Transaction.fromMap('t', original.toMap(userId: 'u'));
      expect(back.amountMinor, 1234);
      expect(back.type, TransactionType.transfer);
      expect(back.toAccountId, 'b');
      expect(back.tags, ['x']);
      expect(back.date, original.date);
    });

    test('migrates schema-1 documents', () {
      final legacy = Transaction.fromMap('g1', {
        'merchant': 'Swiggy',
        'amount': 482,
        'category': 'Food',
        'source': 'HDFC Bank • Debited',
        'occurredAt': '2026-03-29T13:00:00.000',
        'isCredit': false,
        'sourceChannels': ['gmail'],
      });
      expect(Transaction.isLegacy({'merchant': 'x'}), isTrue);
      expect(legacy.amountMinor, 48200);
      expect(legacy.type, TransactionType.expense);
      expect(legacy.categoryId, 'food');
      expect(legacy.description, 'Swiggy');
      expect(legacy.date, DateTime(2026, 3, 29, 13));
      expect(legacy.importSource, 'gmail');

      final income = Transaction.fromMap('g2', {
        'merchant': 'Salary',
        'amount': 42000,
        'category': 'Income',
        'isCredit': true,
        'occurredAt': '2026-03-29T09:00:00.000',
      });
      expect(income.type, TransactionType.income);
      expect(income.categoryId, 'other_income');
    });
  });
}
