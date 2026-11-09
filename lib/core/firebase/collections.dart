/// Sub-collection names under `users/{uid}`. Backup, restore and security
/// rules all key off this list, so new collections must be added here.
abstract final class Collections {
  static const transactions = 'transactions';
  static const accounts = 'accounts';
  static const creditCards = 'credit_cards';
  static const loans = 'loans';
  static const loanPayments = 'loan_payments';
  static const borrowLend = 'borrow_lend';
  static const reminders = 'reminders';
  static const vehicles = 'vehicles';
  static const fuelLogs = 'fuel_logs';
  static const budgets = 'budgets';
  static const recurringTransactions = 'recurring_transactions';
  static const categories = 'categories';
  static const settings = 'settings';

  /// Collections included in backups, in restore order (referenced entities
  /// before the entities that reference them).
  static const backedUp = [
    categories,
    accounts,
    creditCards,
    loans,
    loanPayments,
    borrowLend,
    vehicles,
    fuelLogs,
    budgets,
    recurringTransactions,
    reminders,
    transactions,
  ];
}
