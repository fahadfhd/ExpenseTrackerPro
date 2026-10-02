import 'package:expensetrackerpro/core/transactions/transaction_deduplicator.dart';
import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges same transaction from sms and gmail into one item', () {
    final baseTime = DateTime(2026, 3, 28, 10, 0);
    final transactions = [
      TransactionItem(
        id: 'sms-1',
        merchant: 'Amazon',
        amount: 1299,
        category: 'Shopping',
        source: 'SMS',
        occurredAt: baseTime,
        sourceChannels: const ['sms'],
      ),
      TransactionItem(
        id: 'gmail-1',
        merchant: 'Amazon',
        amount: 1299,
        category: 'Shopping',
        source: 'Gmail',
        occurredAt: baseTime.add(const Duration(minutes: 5)),
        sourceChannels: const ['gmail'],
      ),
    ];

    final result = TransactionDeduplicator.deduplicate(transactions);

    expect(result, hasLength(1));
    expect(result.first.source, 'Gmail + SMS');
    expect(result.first.sourceChannels, containsAll(<String>['gmail', 'sms']));
  });
}
