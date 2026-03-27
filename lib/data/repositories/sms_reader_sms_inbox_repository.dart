import 'package:expensetrackerpro/domain/entities/sms_message_item.dart';
import 'package:expensetrackerpro/domain/repositories/sms_inbox_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:sms_reader/sms_reader.dart';

class SmsReaderSmsInboxRepository implements SmsInboxRepository {
  const SmsReaderSmsInboxRepository();

  static const _keywords = [
    'debited',
    'credited',
    'inr',
    'upi',
    'a/c',
    'spent',
    'withdrawn',
    'purchase',
    'rs.',
    'rs ',
  ];

  @override
  Future<List<SmsMessageItem>> getRelevantMessages() async {
    if (!_supportsSmsInbox) {
      return const [];
    }

    final inbox = await SmsReader.getInboxSms();
    final filtered = inbox
        .where((message) {
          final body = message.body.toLowerCase();
          return _keywords.any(body.contains);
        })
        .take(20);

    return filtered.map((message) {
      final timestamp = int.tryParse(message.date);
      final date = timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);

      return SmsMessageItem(
        sender: message.address.isEmpty ? 'Unknown sender' : message.address,
        body: message.body,
        dateLabel: _formatDate(date),
      );
    }).toList();
  }

  bool get _supportsSmsInbox =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month ${date.year} • $hour:$minute';
  }
}
