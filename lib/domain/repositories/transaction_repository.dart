import 'package:expensetrackerpro/domain/entities/transaction_item.dart';

abstract class TransactionRepository {
  Stream<List<TransactionItem>> watchTransactions();

  Future<void> seedInitialTransactions();

  Future<void> upsertTransactions(List<TransactionItem> transactions);

  Future<void> clearTransactions();
}
