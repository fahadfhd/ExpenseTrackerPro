import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  const MockTransactionRepository();

  @override
  List<TransactionItem> getTransactions() {
    return const [
      TransactionItem(
        merchant: 'Swiggy',
        amount: 482,
        category: 'Food',
        dateLabel: 'Today, 8:40 PM',
        source: 'HDFC Card • debited',
      ),
      TransactionItem(
        merchant: 'Uber',
        amount: 265,
        category: 'Travel',
        dateLabel: 'Today, 2:15 PM',
        source: 'UPI • debited',
      ),
      TransactionItem(
        merchant: 'Amazon',
        amount: 1299,
        category: 'Shopping',
        dateLabel: 'Yesterday',
        source: 'ICICI Card • debited',
      ),
      TransactionItem(
        merchant: 'Salary Credit',
        amount: 42000,
        category: 'Income',
        dateLabel: '24 Mar',
        source: 'SBI Account • credited',
        isCredit: true,
      ),
    ];
  }
}
