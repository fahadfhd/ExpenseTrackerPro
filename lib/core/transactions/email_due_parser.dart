import 'package:intl/intl.dart';
import 'package:expensetrackerpro/domain/entities/due_item.dart';
import 'package:expensetrackerpro/domain/entities/email_message_item.dart';

class EmailDueParser {
  static final RegExp _amountPattern = RegExp(
    r'(?:INR|Rs\.?|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _dueDatePattern = RegExp(
    r'(?:due on|due date(?: is)?|pay by|payment due on|due by|before)\s*[:\-]?\s*([0-9]{1,2}[\/\-][0-9]{1,2}(?:[\/\-][0-9]{2,4})?)',
    caseSensitive: false,
  );
  static final RegExp _dueDateWithMonthPattern = RegExp(
    r'(?:due on|due date(?: is)?|pay by|payment due on|due by|before)\s*[:\-]?\s*([0-9]{1,2}\s+[a-z]{3,9}\s+[0-9]{2,4})',
    caseSensitive: false,
  );
  static final RegExp _dueIndicatorPattern = RegExp(
    r'\b(credit card bill|card statement|statement is ready|bill due|minimum due|total due|payment due|statement generated|amount due|due amount|outstanding amount|total amount due)\b',
    caseSensitive: false,
  );

  static List<DueItem> parse(List<EmailMessageItem> messages) {
    final dueMap = <String, DueItem>{};
    for (final message in messages) {
      final due = _parseOne(message);
      if (due == null) continue;
      final key =
          '${due.title.toLowerCase()}-${due.amount}-${DateTime(due.dueDate.year, due.dueDate.month, due.dueDate.day).millisecondsSinceEpoch}';
      dueMap[key] = due;
    }

    final dueItems = dueMap.values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return dueItems;
  }

  static DueItem? _parseOne(EmailMessageItem message) {
    final content = '${message.subject} ${message.snippet}'.toLowerCase();
    if (!_dueIndicatorPattern.hasMatch(content)) return null;

    final amountMatch = _amountPattern.firstMatch(content);
    if (amountMatch == null) return null;

    final dueDateMatch =
        _dueDatePattern.firstMatch(content) ??
        _dueDateWithMonthPattern.firstMatch(content);
    final dueDate = _parseDueDate(dueDateMatch?.group(1), message.occurredAt);
    final amount = int.tryParse(
      (amountMatch.group(1) ?? '').replaceAll(',', '').split('.').first,
    );
    if (amount == null) return null;

    return DueItem(
      title: _extractTitle(message),
      amount: amount,
      dueDate: dueDate,
      source: 'Gmail',
    );
  }

  static String _extractTitle(EmailMessageItem message) {
    final sender = message.sender.split('<').first.trim();
    if (sender.isNotEmpty && !sender.contains('@')) {
      return sender;
    }
    return message.subject.trim().isEmpty ? 'Credit card due' : message.subject;
  }

  static DateTime _parseDueDate(String? raw, DateTime fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    final normalizedRaw = raw.trim();
    final normalizedMonthDate = normalizedRaw
        .split(RegExp(r'\s+'))
        .map((part) {
          if (RegExp(r'^\d+$').hasMatch(part)) return part;
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');

    for (final pattern in ['dd MMM yyyy', 'dd MMMM yyyy', 'dd MMM yy']) {
      try {
        return DateFormat(pattern).parseStrict(normalizedMonthDate);
      } catch (_) {
        // Try the next common due-date format.
      }
    }

    final separator = normalizedRaw.contains('/') ? '/' : '-';
    final parts = normalizedRaw.split(separator);
    if (parts.length < 2) return fallback;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = parts.length >= 3
        ? int.tryParse(parts[2].length == 2 ? '20${parts[2]}' : parts[2])
        : fallback.year;

    if (day == null || month == null || year == null) return fallback;
    return DateTime(year, month, day);
  }
}
