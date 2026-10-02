import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';

enum TransactionIssue {
  amountNotPositive,
  amountTooLarge,
  categoryMismatch,
  cardRequired,
  cardNotAllowed,
  sourceAccountRequired,
  destinationAccountRequired,
  sameTransferAccounts,
  loanRequired,
  debtRecordRequired,
  refundTargetAmbiguous,
}

/// Rejects combinations that would corrupt balances, e.g. a credit-card
/// expense without a card, or a transfer into the same account.
abstract final class TransactionValidator {
  /// 100 crore in minor units; guards against fat-finger input overflowing
  /// aggregates.
  static const maxAmountMinor = 1000000000 * 100;

  static List<TransactionIssue> validate(Transaction tx) {
    final issues = <TransactionIssue>[];
    if (tx.amountMinor <= 0) issues.add(TransactionIssue.amountNotPositive);
    if (tx.amountMinor > maxAmountMinor) {
      issues.add(TransactionIssue.amountTooLarge);
    }

    final category = Categories.byId(tx.categoryId);
    switch (tx.type) {
      case TransactionType.expense:
        if (tx.creditCardId != null) issues.add(TransactionIssue.cardNotAllowed);
        if (category.kind != CategoryKind.expense) {
          issues.add(TransactionIssue.categoryMismatch);
        }
      case TransactionType.creditCardExpense:
        if (tx.creditCardId == null) issues.add(TransactionIssue.cardRequired);
        if (category.kind != CategoryKind.expense) {
          issues.add(TransactionIssue.categoryMismatch);
        }
      case TransactionType.income:
        if (tx.creditCardId != null) issues.add(TransactionIssue.cardNotAllowed);
        if (category.kind != CategoryKind.income) {
          issues.add(TransactionIssue.categoryMismatch);
        }
      case TransactionType.transfer:
        if (tx.accountId == null) {
          issues.add(TransactionIssue.sourceAccountRequired);
        }
        if (tx.toAccountId == null) {
          issues.add(TransactionIssue.destinationAccountRequired);
        }
        if (tx.accountId != null && tx.accountId == tx.toAccountId) {
          issues.add(TransactionIssue.sameTransferAccounts);
        }
      case TransactionType.creditCardPayment:
        if (tx.creditCardId == null) issues.add(TransactionIssue.cardRequired);
      case TransactionType.loanPayment:
        if (tx.loanId == null) issues.add(TransactionIssue.loanRequired);
      case TransactionType.refund:
        if (tx.accountId != null && tx.creditCardId != null) {
          issues.add(TransactionIssue.refundTargetAmbiguous);
        }
      case TransactionType.borrowed:
      case TransactionType.lent:
      case TransactionType.debtRepayment:
      case TransactionType.debtCollection:
        if (tx.borrowLendId == null) {
          issues.add(TransactionIssue.debtRecordRequired);
        }
    }
    return issues;
  }
}
