import 'package:kept/features/transactions/domain/transaction.dart';

/// How transactions move account balances and card outstanding.
///
/// This is the only place that encodes those rules. Account balances and card
/// outstanding are stored as running deltas that are updated from these
/// effects atomically with each transaction write, and the "recalculate
/// balances" repair recomputes them from the same function.
class LedgerDelta {
  const LedgerDelta({this.accounts = const {}, this.cards = const {}});

  /// Change in account balance, keyed by account id.
  final Map<String, int> accounts;

  /// Change in card outstanding (amount owed), keyed by card id.
  final Map<String, int> cards;

  bool get isEmpty => accounts.isEmpty && cards.isEmpty;

  LedgerDelta operator +(LedgerDelta other) => LedgerDelta(
    accounts: _merge(accounts, other.accounts),
    cards: _merge(cards, other.cards),
  );

  LedgerDelta operator -() => LedgerDelta(
    accounts: accounts.map((k, v) => MapEntry(k, -v)),
    cards: cards.map((k, v) => MapEntry(k, -v)),
  );

  static Map<String, int> _merge(Map<String, int> a, Map<String, int> b) {
    final result = {...a};
    b.forEach((key, value) => result[key] = (result[key] ?? 0) + value);
    result.removeWhere((_, value) => value == 0);
    return result;
  }
}

abstract final class LedgerEffects {
  static LedgerDelta of(Transaction? tx) {
    // Pending transactions have not moved money yet.
    if (tx == null || !tx.isCleared) return const LedgerDelta();
    final amount = tx.amountMinor;
    final accounts = <String, int>{};
    final cards = <String, int>{};

    void account(String? id, int delta) {
      if (id == null) return;
      accounts[id] = (accounts[id] ?? 0) + delta;
    }

    void card(String? id, int delta) {
      if (id == null) return;
      cards[id] = (cards[id] ?? 0) + delta;
    }

    switch (tx.type) {
      case TransactionType.expense:
      case TransactionType.loanPayment:
      case TransactionType.lent:
      case TransactionType.debtRepayment:
        account(tx.accountId, -amount);
      case TransactionType.income:
      case TransactionType.borrowed:
      case TransactionType.debtCollection:
        account(tx.accountId, amount);
      case TransactionType.transfer:
        account(tx.accountId, -amount);
        account(tx.toAccountId, amount);
      case TransactionType.creditCardExpense:
        card(tx.creditCardId, amount);
      case TransactionType.creditCardPayment:
        card(tx.creditCardId, -amount);
        account(tx.accountId, -amount);
      case TransactionType.refund:
        if (tx.creditCardId != null) {
          card(tx.creditCardId, -amount);
        } else {
          account(tx.accountId, amount);
        }
    }
    return LedgerDelta(accounts: accounts, cards: cards);
  }

  /// Delta to apply when [before] is replaced by [after]. Either may be null
  /// for create/delete.
  static LedgerDelta change(Transaction? before, Transaction? after) =>
      of(after) + -of(before);

  /// Totals over a full history, used by the balance repair job.
  static LedgerDelta total(Iterable<Transaction> transactions) =>
      transactions.fold(const LedgerDelta(), (sum, tx) => sum + of(tx));
}
