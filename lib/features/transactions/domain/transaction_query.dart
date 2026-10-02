import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';

enum TransactionSort { newest, oldest, largest, smallest }

/// User-chosen filters on top of a date-range query. Immutable; the UI keeps
/// one instance in a provider and replaces it on change.
class TransactionFilter {
  const TransactionFilter({
    this.text = '',
    this.types = const {},
    this.categoryIds = const {},
    this.accountIds = const {},
    this.cardIds = const {},
    this.minAmountMinor,
    this.maxAmountMinor,
    this.sort = TransactionSort.newest,
  });

  final String text;
  final Set<TransactionType> types;
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final Set<String> cardIds;
  final int? minAmountMinor;
  final int? maxAmountMinor;
  final TransactionSort sort;

  /// Number of active non-text filters, for the filter badge.
  int get activeCount =>
      (types.isNotEmpty ? 1 : 0) +
      (categoryIds.isNotEmpty ? 1 : 0) +
      (accountIds.isNotEmpty ? 1 : 0) +
      (cardIds.isNotEmpty ? 1 : 0) +
      (minAmountMinor != null || maxAmountMinor != null ? 1 : 0);

  bool get isEmpty => text.trim().isEmpty && activeCount == 0;

  TransactionFilter copyWith({
    String? text,
    Set<TransactionType>? types,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    Set<String>? cardIds,
    int? Function()? minAmountMinor,
    int? Function()? maxAmountMinor,
    TransactionSort? sort,
  }) => TransactionFilter(
    text: text ?? this.text,
    types: types ?? this.types,
    categoryIds: categoryIds ?? this.categoryIds,
    accountIds: accountIds ?? this.accountIds,
    cardIds: cardIds ?? this.cardIds,
    minAmountMinor: minAmountMinor != null
        ? minAmountMinor()
        : this.minAmountMinor,
    maxAmountMinor: maxAmountMinor != null
        ? maxAmountMinor()
        : this.maxAmountMinor,
    sort: sort ?? this.sort,
  );

  TransactionFilter clearFilters() => TransactionFilter(text: text, sort: sort);
}

abstract final class TransactionQuery {
  /// Applies [filter] to an already date-bounded list.
  ///
  /// [searchText] returns the searchable text of a transaction, including
  /// resolved names (category label, account, card) and formatted
  /// amount/date, so this function stays free of UI and localization
  /// concerns.
  static List<Transaction> apply(
    Iterable<Transaction> transactions,
    TransactionFilter filter, {
    required String Function(Transaction) searchText,
  }) {
    final terms = filter.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final result = transactions.where((tx) {
      if (filter.types.isNotEmpty && !filter.types.contains(tx.type)) {
        return false;
      }
      if (filter.categoryIds.isNotEmpty &&
          !filter.categoryIds.contains(tx.categoryId)) {
        return false;
      }
      if (filter.accountIds.isNotEmpty &&
          !filter.accountIds.contains(tx.accountId) &&
          !filter.accountIds.contains(tx.toAccountId)) {
        return false;
      }
      if (filter.cardIds.isNotEmpty &&
          !filter.cardIds.contains(tx.creditCardId)) {
        return false;
      }
      if (filter.minAmountMinor != null &&
          tx.amountMinor < filter.minAmountMinor!) {
        return false;
      }
      if (filter.maxAmountMinor != null &&
          tx.amountMinor > filter.maxAmountMinor!) {
        return false;
      }
      if (terms.isNotEmpty) {
        final haystack = searchText(tx).toLowerCase();
        if (!terms.every(haystack.contains)) return false;
      }
      return true;
    }).toList();

    result.sort(switch (filter.sort) {
      TransactionSort.newest => (a, b) => b.date.compareTo(a.date),
      TransactionSort.oldest => (a, b) => a.date.compareTo(b.date),
      TransactionSort.largest => (a, b) => b.amountMinor.compareTo(a.amountMinor),
      TransactionSort.smallest => (a, b) =>
          a.amountMinor.compareTo(b.amountMinor),
    });
    return result;
  }
}
