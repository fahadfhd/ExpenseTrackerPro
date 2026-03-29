import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/entities/transaction_item.dart';

class EmailTransactionParser {
  static final RegExp _amountPattern = RegExp(
    r'(?:INR|Rs\.?|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _merchantAtPattern = RegExp(
    r'\b(?:at|to|towards|payee|merchant)\s+([a-z0-9&.\- ]{2,40})',
    caseSensitive: false,
  );
  static final RegExp _upiAppPattern = RegExp(
    r'\b(gpay|google pay|phonepe|paytm|amazon pay)\b',
    caseSensitive: false,
  );
  static final RegExp _debitPattern = RegExp(
    r'\b(debited|spent|paid|purchase|charged|payment successful|txn successful|transaction successful)\b',
    caseSensitive: false,
  );
  static final RegExp _creditPattern = RegExp(
    r'\b(credited|received|refund|salary credited|cashback)\b',
    caseSensitive: false,
  );
  static final RegExp _excludePattern = RegExp(
    r'\b(due|bill due|minimum due|statement|reminder|autopay due|payment reminder|pay by|overdue)\b',
    caseSensitive: false,
  );
  static final Map<String, String> _categoryMap = {
    'swiggy': 'Food',
    'zomato': 'Food',
    'uber': 'Travel',
    'ola': 'Travel',
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'salary': 'Income',
    'upi': 'Transfers',
  };
  static final Map<String, String> _providerMap = {
    'hdfc': 'HDFC Bank',
    'hdfcbank': 'HDFC Bank',
    'sbi': 'SBI',
    'sbicard': 'SBI Card',
    'icici': 'ICICI Bank',
    'axis': 'Axis Bank',
    'axisbank': 'Axis Bank',
    'amex': 'Amex',
    'americanexpress': 'Amex',
    'kotak': 'Kotak',
    'idfc': 'IDFC First',
    'yesbank': 'Yes Bank',
    'indusind': 'IndusInd',
    'googlepay': 'Google Pay',
    'gpay': 'Google Pay',
    'phonepe': 'PhonePe',
    'paytm': 'Paytm',
  };

  static List<TransactionItem> parse(List<EmailMessageItem> messages) {
    return messages.map(_parseOne).whereType<TransactionItem>().toList();
  }

  static TransactionItem? _parseOne(EmailMessageItem message) {
    final content = '${message.subject} ${message.snippet}'.toLowerCase();
    if (_excludePattern.hasMatch(content)) return null;

    final amountMatch = _amountPattern.firstMatch(content);
    if (amountMatch == null) return null;

    final isCredit = _creditPattern.hasMatch(content);
    final isDebit = _debitPattern.hasMatch(content);
    if (!isCredit && !isDebit) return null;

    final parsedAmount = amountMatch.group(1)?.replaceAll(',', '');
    final amount = double.tryParse(parsedAmount ?? '');
    if (amount == null) return null;

    final merchant = _extractMerchant(message, content);
    final category = _inferCategory(content, merchant);
    final bankName = _extractBank(message, content);
    final sourceLabel = bankName.isNotEmpty 
        ? '$bankName • ${isCredit ? 'Credited' : 'Debited'}'
        : 'Gmail • ${isCredit ? 'Credited' : 'Debited'}';

    final id = _buildId(
      merchant: merchant,
      amount: amount.toInt(),
      occurredAt: message.occurredAt,
      isCredit: isCredit,
      source: 'gmail',
    );

    return TransactionItem(
      id: id,
      merchant: merchant,
      amount: amount.toInt(),
      category: category,
      source: sourceLabel,
      occurredAt: message.occurredAt,
      isCredit: isCredit,
      sourceChannels: const ['gmail'],
    );
  }

  static String _extractBank(EmailMessageItem message, String content) {
    final merged = '${message.subject} ${message.sender} ${message.snippet}'.toLowerCase();
    for (final entry in _providerMap.entries) {
      if (merged.contains(entry.key)) {
        return entry.value;
      }
    }
    return '';
  }

  static String _extractMerchant(EmailMessageItem message, String content) {
    final merged = '${message.subject} ${message.sender} ${message.snippet}'
        .toLowerCase();

    for (final entry in _categoryMap.entries) {
      if (merged.contains(entry.key)) {
        return _capitalize(entry.key);
      }
    }

    final upiAppMatch = _upiAppPattern.firstMatch(merged);
    if (upiAppMatch != null) {
      final app = upiAppMatch.group(1) ?? '';
      if (app.isNotEmpty) {
        return _normalizeKnownName(app);
      }
    }

    final merchantMatch = _merchantAtPattern.firstMatch(content);
    if (merchantMatch != null) {
      final candidate = _cleanMerchantCandidate(merchantMatch.group(1) ?? '');
      if (_isUsefulMerchant(candidate)) {
        return candidate;
      }
    }

    for (final entry in _providerMap.entries) {
      if (merged.contains(entry.key)) {
        return entry.value;
      }
    }

    final senderName = message.sender.split('<').first.trim();
    if (senderName.isNotEmpty && !senderName.contains('@')) {
      return senderName;
    }

    final subjectWords = message.subject.trim().split(RegExp(r'\s+'));
    return subjectWords.take(2).join(' ').trim().isEmpty
        ? 'Email transaction'
        : subjectWords.take(2).join(' ');
  }

  static String _inferCategory(String content, String merchant) {
    final normalized = '$content $merchant'.toLowerCase();
    for (final entry in _categoryMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Uncategorized';
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _normalizeKnownName(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return switch (normalized) {
      'googlepay' || 'gpay' => 'Google Pay',
      'phonepe' => 'PhonePe',
      'paytm' => 'Paytm',
      'amazonpay' => 'Amazon',
      _ => _capitalize(value.trim()),
    };
  }

  static String _cleanMerchantCandidate(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'\s+(using|via|for|on|with|ref|upi|card).*$'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9&.\- ]'), '')
        .trim();

    if (cleaned.isEmpty) return cleaned;
    return cleaned
        .split(RegExp(r'\s+'))
        .take(3)
        .map((part) => _capitalize(part.toLowerCase()))
        .join(' ');
  }

  static bool _isUsefulMerchant(String value) {
    final normalized = value.toLowerCase();
    if (normalized.isEmpty) return false;
    const blocked = {
      'upi',
      'account',
      'bank',
      'credit',
      'debit',
      'card',
      'transaction',
      'payment',
    };
    return !blocked.contains(normalized);
  }

  static String _buildId({
    required String merchant,
    required int amount,
    required DateTime occurredAt,
    required bool isCredit,
    required String source,
  }) {
    final normalizedMerchant = merchant.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return '$source-$normalizedMerchant-$amount-${occurredAt.millisecondsSinceEpoch}-${isCredit ? 'credit' : 'debit'}';
  }
}
