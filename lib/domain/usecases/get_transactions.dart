import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';

class GetTransactions {
  const GetTransactions(this._repository);

  final TransactionRepository _repository;

  List<TransactionItem> call() => _repository.getTransactions();
}
