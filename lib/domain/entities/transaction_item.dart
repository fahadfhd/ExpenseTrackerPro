import 'package:intl/intl.dart';

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.source,
    required this.occurredAt,
    this.isCredit = false,
  });

  final String id;
  final String merchant;
  final int amount;
  final String category;
  final String source;
  final DateTime occurredAt;
  final bool isCredit;

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(
      occurredAt.year,
      occurredAt.month,
      occurredAt.day,
    );

    if (transactionDay == today) {
      return 'Today, ${DateFormat('h:mm a').format(occurredAt)}';
    }

    if (transactionDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return DateFormat('dd MMM').format(occurredAt);
  }

  Map<String, dynamic> toMap() {
    return {
      'merchant': merchant,
      'amount': amount,
      'category': category,
      'source': source,
      'occurredAt': occurredAt.toIso8601String(),
      'isCredit': isCredit,
    };
  }

  factory TransactionItem.fromMap(String id, Map<String, dynamic> map) {
    return TransactionItem(
      id: id,
      merchant: map['merchant'] as String? ?? 'Unknown merchant',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? 'Uncategorized',
      source: map['source'] as String? ?? 'Unknown source',
      occurredAt:
          DateTime.tryParse(map['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      isCredit: map['isCredit'] as bool? ?? false,
    );
  }
}
