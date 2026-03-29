import 'package:expensetrackerpro/domain/entities/transaction_item.dart';

enum TransactionDateFilter { all, today, thisMonth }

class TransactionFilters {
  static List<TransactionItem> apply({
    required List<TransactionItem> transactions,
    required TransactionDateFilter dateFilter,
    required bool upiOnly,
    required bool cardsOnly,
    required bool debitOnly,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final startOfToday = DateTime(
      effectiveNow.year,
      effectiveNow.month,
      effectiveNow.day,
    );
    final startOfMonth = DateTime(effectiveNow.year, effectiveNow.month);

    return transactions.where((transaction) {
      final occurredDay = DateTime(
        transaction.occurredAt.year,
        transaction.occurredAt.month,
        transaction.occurredAt.day,
      );

      if (dateFilter == TransactionDateFilter.today &&
          occurredDay != startOfToday) {
        return false;
      }

      if (dateFilter == TransactionDateFilter.thisMonth &&
          transaction.occurredAt.isBefore(startOfMonth)) {
        return false;
      }

      final normalized = [
        transaction.source,
        transaction.merchant,
        transaction.category,
        ...transaction.sourceChannels,
      ].join(' ').toLowerCase();

      if (upiOnly &&
          !normalized.contains('upi') &&
          !normalized.contains('gpay') &&
          !normalized.contains('google pay') &&
          !normalized.contains('phonepe') &&
          !normalized.contains('paytm')) {
        return false;
      }

      if (cardsOnly &&
          !normalized.contains('card') &&
          !normalized.contains('credit card') &&
          !normalized.contains('visa') &&
          !normalized.contains('mastercard') &&
          !normalized.contains('amex')) {
        return false;
      }

      if (debitOnly && transaction.isCredit) {
        return false;
      }

      return true;
    }).toList();
  }
}
