import 'package:expensetrackerpro/core/transactions/transaction_filters.dart';
import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:flutter_test/flutter_test.dart';

final _demoTransactions = [
  TransactionItem(
    id: 'swiggy-1',
    merchant: 'Swiggy',
    amount: 482,
    category: 'Food',
    source: 'HDFC Card • debited',
    occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
    sourceChannels: const ['sms'],
  ),
  TransactionItem(
    id: 'uber-1',
    merchant: 'Uber',
    amount: 265,
    category: 'Travel',
    source: 'UPI • debited',
    occurredAt: DateTime.now().subtract(const Duration(hours: 8)),
    sourceChannels: const ['sms'],
  ),
  TransactionItem(
    id: 'amazon-1',
    merchant: 'Amazon',
    amount: 1299,
    category: 'Shopping',
    source: 'ICICI Card • debited',
    occurredAt: DateTime.now().subtract(const Duration(days: 1)),
    sourceChannels: const ['sms'],
  ),
  TransactionItem(
    id: 'salary-1',
    merchant: 'Salary Credit',
    amount: 42000,
    category: 'Income',
    source: 'SBI Account • credited',
    occurredAt: DateTime.now().subtract(const Duration(days: 2)),
    isCredit: true,
    sourceChannels: const ['sms'],
  ),
];

void main() {
  test('filters transactions by date and debit state', () {
    final now = DateTime.now();
    final filtered = TransactionFilters.apply(
      transactions: _demoTransactions,
      dateFilter: TransactionDateFilter.today,
      upiOnly: false,
      cardsOnly: false,
      debitOnly: true,
      now: now,
    );

    expect(filtered, hasLength(2));
    expect(filtered.every((item) => item.isCredit == false), isTrue);
    expect(
      filtered.every(
        (item) =>
            item.occurredAt.year == now.year &&
            item.occurredAt.month == now.month &&
            item.occurredAt.day == now.day,
      ),
      isTrue,
    );
  });

  test('filters transactions by card sources', () {
    final filtered = TransactionFilters.apply(
      transactions: _demoTransactions,
      dateFilter: TransactionDateFilter.all,
      upiOnly: false,
      cardsOnly: true,
      debitOnly: false,
    );

    expect(filtered.map((item) => item.merchant), ['Swiggy', 'Amazon']);
  });
}
