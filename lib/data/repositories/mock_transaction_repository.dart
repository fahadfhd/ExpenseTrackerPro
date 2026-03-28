import 'dart:async';

import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository([List<TransactionItem>? transactions])
    : _controller = StreamController<List<TransactionItem>>.broadcast(),
      _transactions = transactions ?? demoTransactions {
    _controller.add(_transactions);
  }

  static final List<TransactionItem> demoTransactions = [
    TransactionItem(
      id: 'swiggy-1',
      merchant: 'Swiggy',
      amount: 482,
      category: 'Food',
      source: 'HDFC Card • debited',
      occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionItem(
      id: 'uber-1',
      merchant: 'Uber',
      amount: 265,
      category: 'Travel',
      source: 'UPI • debited',
      occurredAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    TransactionItem(
      id: 'amazon-1',
      merchant: 'Amazon',
      amount: 1299,
      category: 'Shopping',
      source: 'ICICI Card • debited',
      occurredAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionItem(
      id: 'salary-1',
      merchant: 'Salary Credit',
      amount: 42000,
      category: 'Income',
      source: 'SBI Account • credited',
      occurredAt: DateTime.now().subtract(const Duration(days: 2)),
      isCredit: true,
    ),
  ];

  final StreamController<List<TransactionItem>> _controller;
  final List<TransactionItem> _transactions;

  @override
  Future<void> seedInitialTransactions() async {
    _controller.add(_transactions);
  }

  @override
  Stream<List<TransactionItem>> watchTransactions() => _controller.stream;
}
