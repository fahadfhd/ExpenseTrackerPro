import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/core/utils/recurrence.dart';
import 'package:expensetrackerpro/features/accounts/data/account_repository.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/borrow_lend/data/debt_repository.dart';
import 'package:expensetrackerpro/features/borrow_lend/domain/debt_record.dart';
import 'package:expensetrackerpro/features/credit_cards/data/credit_card_repository.dart';
import 'package:expensetrackerpro/features/credit_cards/domain/credit_card.dart';
import 'package:expensetrackerpro/features/loans/data/loan_repository.dart';
import 'package:expensetrackerpro/features/loans/domain/emi_engine.dart';
import 'package:expensetrackerpro/features/loans/domain/loan.dart';
import 'package:expensetrackerpro/features/recurring/data/recurring_repository.dart';
import 'package:expensetrackerpro/features/recurring/domain/recurring_rule.dart';
import 'package:expensetrackerpro/features/transactions/data/transaction_repository.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/vehicles/data/vehicle_repository.dart';
import 'package:expensetrackerpro/features/vehicles/domain/vehicle.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets fire-and-forget writes reach the fake store.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeFirebaseFirestore db;
  late DocumentReference<Map<String, dynamic>> user;
  late SyncStatusNotifierForTest status;
  late WriteDispatcher writer;
  late TransactionRepository txRepo;
  late AccountRepository accounts;
  late CreditCardRepository cards;
  final now = DateTime(2026, 3, 15, 12);

  setUp(() {
    db = FakeFirebaseFirestore();
    user = db.collection('users').doc('uid-1');
    status = SyncStatusNotifierForTest();
    writer = WriteDispatcher(status);
    txRepo = TransactionRepository(userDoc: user, writer: writer);
    accounts = AccountRepository(userDoc: user, writer: writer, transactions: txRepo);
    cards = CreditCardRepository(userDoc: user, writer: writer, transactions: txRepo);
  });

  Future<Account> account(String id, {int opening = 0}) async {
    accounts.save(Account(
      id: id,
      name: id,
      type: AccountType.savings,
      openingBalanceMinor: opening,
      createdAt: now,
      updatedAt: now,
    ));
    await settle();
    return Account.fromMap(id, (await user.collection('accounts').doc(id).get()).data()!);
  }

  Future<Account> reloadAccount(String id) async =>
      Account.fromMap(id, (await user.collection('accounts').doc(id).get()).data()!);

  Future<CreditCard> reloadCard(String id) async =>
      CreditCard.fromMap(id, (await user.collection('credit_cards').doc(id).get()).data()!);

  Transaction tx(String id, TransactionType type, int amount, {String? account, String? to, String? card, String category = 'food'}) =>
      Transaction(
        id: id,
        date: now,
        amountMinor: amount,
        type: type,
        categoryId: category,
        accountId: account,
        toAccountId: to,
        creditCardId: card,
        createdAt: now,
        updatedAt: now,
      );

  group('TransactionRepository keeps balances in step', () {
    test('create, edit and delete adjust the account balance', () async {
      await account('a', opening: 100000);
      final expense = tx('t1', TransactionType.expense, 2500, account: 'a');
      txRepo.save(expense);
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 97500);

      final edited = expense.copyWith(amountMinor: 4000);
      txRepo.save(edited, before: expense);
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 96000);

      txRepo.delete(edited);
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 100000);
      expect(status.state.pending, 0);
    });

    test('transfers move money between accounts', () async {
      await account('a', opening: 50000);
      await account('b');
      txRepo.save(tx('t', TransactionType.transfer, 20000, account: 'a', to: 'b', category: 'transfer'));
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 30000);
      expect((await reloadAccount('b')).balanceMinor, 20000);
    });

    test('card expense and bill payment update outstanding and account', () async {
      await account('a', opening: 100000);
      cards.save(CreditCard(
        id: 'c',
        name: 'Card',
        creditLimitMinor: 10000000,
        statementDay: 20,
        dueDay: 8,
        createdAt: now,
        updatedAt: now,
      ));
      await settle();
      txRepo.save(tx('e', TransactionType.creditCardExpense, 30000, card: 'c'));
      txRepo.save(tx('p', TransactionType.creditCardPayment, 10000, card: 'c', account: 'a', category: 'card_payment'));
      await settle();
      final card = await reloadCard('c');
      expect(card.outstandingMinor, 20000);
      expect(card.availableMinor, 10000000 - 20000);
      expect((await reloadAccount('a')).balanceMinor, 90000);
    });

    test('editing an account profile never overwrites its balance', () async {
      final a = await account('a', opening: 1000);
      txRepo.save(tx('t', TransactionType.income, 500, account: 'a', category: 'salary'));
      await settle();
      accounts.save(a.copyWith(name: 'Renamed', updatedAt: now));
      await settle();
      final reloaded = await reloadAccount('a');
      expect(reloaded.name, 'Renamed');
      expect(reloaded.balanceMinor, 1500);
    });

    test('invalid transactions are rejected before writing', () async {
      expect(
        () => txRepo.save(tx('bad', TransactionType.creditCardExpense, 100)),
        throwsA(isA<TransactionValidationException>()),
      );
      await settle();
      expect((await user.collection('transactions').get()).docs, isEmpty);
    });

    test('recalculateBalances repairs drift', () async {
      await account('a', opening: 0);
      txRepo.save(tx('t', TransactionType.income, 700, account: 'a', category: 'salary'));
      await settle();
      await user.collection('accounts').doc('a').update({'ledgerDeltaMinor': 99999});
      await txRepo.recalculateBalances();
      expect((await reloadAccount('a')).balanceMinor, 700);
    });

    test('isInUse protects referenced accounts from deletion', () async {
      await account('a');
      await account('b');
      txRepo.save(tx('t', TransactionType.transfer, 1, account: 'b', to: 'a', category: 'transfer'));
      await settle();
      expect(await accounts.isInUse('a'), isTrue);
      expect(await accounts.isInUse('zzz'), isFalse);
    });

    test('watchRange returns only the requested month, newest first', () async {
      await user.collection('transactions').doc('old').set(
        tx('old', TransactionType.expense, 1).copyWith(date: DateTime(2026, 2, 28)).toMap(userId: 'uid-1'),
      );
      txRepo.save(tx('a', TransactionType.expense, 1).copyWith(date: DateTime(2026, 3, 1)));
      txRepo.save(tx('b', TransactionType.expense, 1).copyWith(date: DateTime(2026, 3, 31, 23)));
      await settle();
      final list = await txRepo.fetchRange(DateRange.month(DateTime(2026, 3)));
      expect(list.map((t) => t.id), ['b', 'a']);
    });

    test('legacy documents are migrated in place', () async {
      await user.collection('transactions').doc('g1').set({
        'merchant': 'Swiggy',
        'amount': 482,
        'category': 'Food',
        'source': 'HDFC • Debited',
        'occurredAt': '2026-03-29T13:00:00.000',
        'isCredit': false,
        'sourceChannels': ['gmail'],
      });
      expect(await txRepo.migrateLegacyDocuments(), 1);
      await settle();
      final data = (await user.collection('transactions').doc('g1').get()).data()!;
      expect(data['schemaVersion'], Transaction.schemaVersion);
      expect(data['amountMinor'], 48200);
      expect(data.containsKey('merchant'), isFalse);
      expect(await txRepo.migrateLegacyDocuments(), 0);
    });
  });

  group('RecurringRepository', () {
    test('generates due occurrences once, even when run twice', () async {
      await account('a', opening: 100000);
      final recurring = RecurringRepository(userDoc: user, writer: writer, transactions: txRepo);
      recurring.save(RecurringRule(
        id: 'rent',
        title: 'Rent',
        type: TransactionType.expense,
        amountMinor: 10000,
        categoryId: 'housing',
        accountId: 'a',
        startDate: DateTime(2026, 1, 5),
        recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly),
        createdAt: now,
        updatedAt: now,
      ));
      await settle();
      expect(await recurring.generateDue(now), 3);
      await settle();
      expect(await recurring.generateDue(now), 0);
      await settle();
      final txs = await user.collection('transactions').get();
      expect(txs.docs.map((d) => d.id).toSet(), {
        'rec_rent_20260105',
        'rec_rent_20260205',
        'rec_rent_20260305',
      });
      expect((await reloadAccount('a')).balanceMinor, 70000);
    });
  });

  group('LoanRepository', () {
    test('paying an installment from an account links a transaction once', () async {
      await account('a', opening: 1000000);
      final loans = LoanRepository(userDoc: user, writer: writer, transactions: txRepo);
      final loan = Loan(
        id: 'l',
        name: 'Car',
        principalMinor: 1200000,
        annualRatePercent: 12,
        installments: 12,
        frequency: EmiFrequency.monthly,
        emiMinor: 106619,
        firstDueDate: DateTime(2026, 2, 5),
        createdAt: now,
        updatedAt: now,
      );
      loans.save(loan);
      loans.payInstallment(loan: loan, number: 1, amountMinor: 106619, date: now, accountId: 'a');
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 1000000 - 106619);

      // Re-recording the same installment with a different amount adjusts
      // by the difference instead of charging twice.
      final previous = await txRepo.fetch(LoanRepository.installmentTransactionId('l', 1));
      loans.payInstallment(
        loan: loan,
        number: 1,
        amountMinor: 110000,
        date: now,
        accountId: 'a',
        previousTransaction: previous,
      );
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 1000000 - 110000);
      final events = await user.collection('loan_payments').get();
      expect(events.docs, hasLength(1));

      // Undoing removes the payment and restores the balance.
      final event = LoanEvent.fromMap(events.docs.single.id, events.docs.single.data());
      loans.clearInstallment(event, linked: await txRepo.fetch(event.transactionId!));
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 1000000);
      expect((await user.collection('loan_payments').get()).docs, isEmpty);
    });
  });

  group('DebtRepository', () {
    test('records, settlements and deletion keep the account consistent', () async {
      await account('a', opening: 50000);
      final debts = DebtRepository(userDoc: user, writer: writer, transactions: txRepo);
      final record = DebtRecord(
        id: 'd',
        direction: DebtDirection.lent,
        personName: 'Ravi',
        amountMinor: 20000,
        date: now,
        accountId: 'a',
        createdAt: now,
        updatedAt: now,
      );
      await debts.save(record);
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 30000);

      debts.addSettlement(record, Settlement(id: 's1', amountMinor: 5000, date: now, accountId: 'a'));
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 35000);
      final stored = DebtRecord.fromMap('d', (await user.collection('borrow_lend').doc('d').get()).data()!);
      expect(stored.outstandingMinor, 15000);
      expect(stored.statusAt(now), DebtStatus.partiallySettled);

      await debts.delete(stored);
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 50000);
      expect((await user.collection('transactions').get()).docs, isEmpty);
    });
  });

  group('VehicleRepository', () {
    test('fuel log recorded as expense, then unlinked on edit', () async {
      await account('a', opening: 100000);
      final vehicles = VehicleRepository(userDoc: user, writer: writer, transactions: txRepo);
      final log = FuelLog(
        id: 'f',
        vehicleId: 'v',
        date: now,
        distanceKm: 300,
        fuelQuantity: 20,
        pricePerUnitMinor: 10000,
        totalCostMinor: 200000 ~/ 10,
        createdAt: now,
      );
      await vehicles.saveFuelLog(log, vehicleName: 'Car', accountId: 'a');
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 80000);
      await vehicles.saveFuelLog(log, vehicleName: 'Car');
      await settle();
      expect((await reloadAccount('a')).balanceMinor, 100000);
      expect((await user.collection('transactions').get()).docs, isEmpty);
    });
  });
}

/// A [SyncStatusNotifier] usable without a ProviderContainer.
class SyncStatusNotifierForTest extends SyncStatusNotifier {
  SyncStatus _state = const SyncStatus();

  @override
  SyncStatus get state => _state;

  @override
  set state(SyncStatus value) => _state = value;
}
