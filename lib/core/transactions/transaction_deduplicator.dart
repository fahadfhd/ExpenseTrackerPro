import 'dart:math';

import 'package:expensetrackerpro/domain/entities/transaction_item.dart';

class TransactionDeduplicator {
  static const _mergeWindow = Duration(hours: 2);

  static List<TransactionItem> deduplicate(List<TransactionItem> transactions) {
    final sorted = [...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final merged = <TransactionItem>[];
    for (final transaction in sorted) {
      final index = merged.indexWhere(
        (existing) => _isDuplicate(existing, transaction),
      );

      if (index == -1) {
        merged.add(transaction);
      } else {
        merged[index] = _merge(merged[index], transaction);
      }
    }

    merged.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return merged;
  }

  static bool _isDuplicate(TransactionItem a, TransactionItem b) {
    if (_normalizeMerchant(a.merchant) != _normalizeMerchant(b.merchant)) {
      return false;
    }

    if (a.amount != b.amount || a.isCredit != b.isCredit) {
      return false;
    }

    final difference = a.occurredAt.difference(b.occurredAt).abs();
    return difference <= _mergeWindow;
  }

  static TransactionItem _merge(
    TransactionItem primary,
    TransactionItem secondary,
  ) {
    final latest = primary.occurredAt.isAfter(secondary.occurredAt)
        ? primary.occurredAt
        : secondary.occurredAt;
    final mergedSources = {
      ...primary.sourceChannels.map(_normalizeSource),
      ...secondary.sourceChannels.map(_normalizeSource),
      _normalizeSource(primary.source),
      _normalizeSource(secondary.source),
    }.where((value) => value.isNotEmpty).toList()..sort();

    return TransactionItem(
      id: primary.id,
      merchant: primary.merchant,
      amount: max(primary.amount, secondary.amount),
      category: primary.category != 'Uncategorized'
          ? primary.category
          : secondary.category,
      source: _composeSourceLabel(mergedSources),
      occurredAt: latest,
      isCredit: primary.isCredit,
      sourceChannels: mergedSources,
    );
  }

  static String _normalizeMerchant(String merchant) {
    return merchant.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _normalizeSource(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('gmail') || normalized.contains('mail')) {
      return 'gmail';
    }
    if (normalized.contains('sms')) {
      return 'sms';
    }
    return normalized.trim();
  }

  static String _composeSourceLabel(List<String> sources) {
    if (sources.isEmpty) return 'Unknown source';

    return sources
        .map((source) {
          switch (source) {
            case 'gmail':
              return 'Gmail';
            case 'sms':
              return 'SMS';
            default:
              return source;
          }
        })
        .join(' + ');
  }
}
