import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';

class UpsertTransactions {
  const UpsertTransactions(this._repository);

  final TransactionRepository _repository;

  Future<void> call(List<TransactionItem> transactions) {
    return _repository.upsertTransactions(transactions);
  }
}
