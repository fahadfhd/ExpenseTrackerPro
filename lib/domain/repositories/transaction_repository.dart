import 'package:expensetrackerpro/domain/entities/transaction_item.dart';

abstract class TransactionRepository {
  List<TransactionItem> getTransactions();
}
