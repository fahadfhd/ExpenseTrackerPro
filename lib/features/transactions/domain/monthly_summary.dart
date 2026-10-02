import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';

/// Aggregates for one period. Produced once per data change by
/// [MonthlySummary.compute] and handed to widgets and charts as-is.
///
/// Definitions:
/// * spending = expenses + credit-card expenses − refunds (never below 0
///   per category). Card *payments* and transfers are excluded so card
///   spending is not counted twice.
/// * EMI = loan payments, shown separately from spending.
/// * savings = income − spending − EMI.
/// * borrowed/lent are reported separately and do not affect savings.
/// * pending transactions are excluded from every total except [pending].
class MonthlySummary {
  const MonthlySummary({
    required this.income,
    required this.spending,
    required this.emi,
    required this.cardSpending,
    required this.borrowed,
    required this.lent,
    required this.pending,
    required this.byCategory,
    required this.byDay,
    required this.byAccount,
    required this.byCard,
    required this.transactionCount,
  });

  static const empty = MonthlySummary(
    income: 0,
    spending: 0,
    emi: 0,
    cardSpending: 0,
    borrowed: 0,
    lent: 0,
    pending: 0,
    byCategory: {},
    byDay: {},
    byAccount: {},
    byCard: {},
    transactionCount: 0,
  );

  final int income;
  final int spending;
  final int emi;
  final int cardSpending;
  final int borrowed;
  final int lent;

  /// Outflows recorded as pending (not yet cleared).
  final int pending;

  /// Net spending per category id, largest first.
  final Map<String, int> byCategory;

  /// Spending per calendar day (1-based day of month).
  final Map<int, int> byDay;

  /// Spending paid from each account id.
  final Map<String, int> byAccount;

  /// Spending charged to each card id.
  final Map<String, int> byCard;
  final int transactionCount;

  int get savings => income - spending - emi;

  /// Share of income kept, or null when there was no income.
  double? get savingsRate => income <= 0 ? null : savings / income;

  static MonthlySummary compute(Iterable<Transaction> transactions) {
    var income = 0,
        spending = 0,
        emi = 0,
        card = 0,
        borrowed = 0,
        lent = 0,
        pending = 0,
        count = 0;
    final byCategory = <String, int>{};
    final byDay = <int, int>{};
    final byAccount = <String, int>{};
    final byCard = <String, int>{};

    void add<K>(Map<K, int> map, K key, int value) =>
        map[key] = (map[key] ?? 0) + value;

    for (final tx in transactions) {
      count++;
      final amount = tx.amountMinor;
      if (!tx.isCleared) {
        if (!tx.type.isInflow) pending += amount;
        continue;
      }
      switch (tx.type) {
        case TransactionType.income:
          income += amount;
        case TransactionType.expense:
        case TransactionType.creditCardExpense:
          spending += amount;
          add(byCategory, tx.categoryId, amount);
          add(byDay, tx.date.day, amount);
          if (tx.type == TransactionType.creditCardExpense) {
            card += amount;
            if (tx.creditCardId != null) add(byCard, tx.creditCardId!, amount);
          } else if (tx.accountId != null) {
            add(byAccount, tx.accountId!, amount);
          }
        case TransactionType.refund:
          spending -= amount;
          add(byCategory, tx.categoryId, -amount);
          add(byDay, tx.date.day, -amount);
          if (tx.creditCardId != null) {
            card -= amount;
            add(byCard, tx.creditCardId!, -amount);
          } else if (tx.accountId != null) {
            add(byAccount, tx.accountId!, -amount);
          }
        case TransactionType.loanPayment:
          emi += amount;
        case TransactionType.borrowed:
          borrowed += amount;
        case TransactionType.lent:
          lent += amount;
        case TransactionType.transfer:
        case TransactionType.creditCardPayment:
        case TransactionType.debtRepayment:
        case TransactionType.debtCollection:
          break;
      }
    }

    Map<K, int> positiveSorted<K>(Map<K, int> map) {
      final entries = map.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(entries);
    }

    return MonthlySummary(
      income: income,
      spending: spending < 0 ? 0 : spending,
      emi: emi,
      cardSpending: card < 0 ? 0 : card,
      borrowed: borrowed,
      lent: lent,
      pending: pending,
      byCategory: positiveSorted(byCategory),
      byDay: Map.fromEntries(
        byDay.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      ),
      byAccount: positiveSorted(byAccount),
      byCard: positiveSorted(byCard),
      transactionCount: count,
    );
  }
}
