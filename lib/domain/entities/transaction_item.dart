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
    this.sourceChannels = const [],
  });

  final String id;
  final String merchant;
  final int amount;
  final String category;
  final String source;
  final DateTime occurredAt;
  final bool isCredit;
  final List<String> sourceChannels;

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(
      occurredAt.year,
      occurredAt.month,
      occurredAt.day,
    );
    final timeStr = DateFormat('h:mm a').format(occurredAt);

    if (transactionDay == today) {
      return 'Today, $timeStr';
    }

    if (transactionDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeStr';
    }

    return '${DateFormat('dd MMM').format(occurredAt)}, $timeStr';
  }

  Map<String, dynamic> toMap() {
    return {
      'merchant': merchant,
      'amount': amount,
      'category': category,
      'source': source,
      'occurredAt': occurredAt.toIso8601String(),
      'isCredit': isCredit,
      'sourceChannels': sourceChannels,
    };
  }

  factory TransactionItem.fromMap(String id, Map<String, dynamic> map) {
    final channels = (map['sourceChannels'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

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
      sourceChannels: channels.isEmpty
          ? [(map['source'] as String? ?? 'unknown').toLowerCase()]
          : channels,
    );
  }
}
