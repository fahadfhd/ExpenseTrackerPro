import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/transactions/data/transaction_repository.dart';
import 'package:expensetrackerpro/features/transactions/domain/monthly_summary.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return TransactionRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
  );
});

/// The month shown by the dashboard, transaction list and budgets.
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    // Per-user UI state: reset when the signed-in user changes.
    ref.watch(uidProvider);
    return Dates.monthOf(DateTime.now());
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() => state = DateTime(state.year, state.month + 1);

  void select(DateTime month) => state = Dates.monthOf(month);
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

/// Live transactions in a date range, newest first. Bounded by date so only
/// the period on screen is loaded, never the whole history.
final transactionsInRangeProvider = StreamProvider.autoDispose
    .family<List<Transaction>, DateRange>(
      (ref, range) =>
          ref.watch(transactionRepositoryProvider).watchRange(range),
    );

final monthTransactionsProvider = Provider.autoDispose
    .family<AsyncValue<List<Transaction>>, DateTime>(
      (ref, month) =>
          ref.watch(transactionsInRangeProvider(DateRange.month(month))),
    );

final monthlySummaryProvider = Provider.autoDispose
    .family<AsyncValue<MonthlySummary>, DateTime>(
      (ref, month) => ref
          .watch(monthTransactionsProvider(month))
          .whenData(MonthlySummary.compute),
    );

/// Number of months in trend charts.
const trendMonths = 6;

class MonthPoint {
  const MonthPoint(this.month, this.summary);
  final DateTime month;
  final MonthlySummary summary;
}

/// Groups [transactions] into one summary per month of [range], oldest
/// first, including empty months.
List<MonthPoint> monthPoints(DateRange range, Iterable<Transaction> transactions) {
  final buckets = <DateTime, List<Transaction>>{};
  for (
    var m = range.start;
    m.isBefore(range.end);
    m = DateTime(m.year, m.month + 1)
  ) {
    buckets[m] = [];
  }
  for (final tx in transactions) {
    buckets[Dates.monthOf(tx.date)]?.add(tx);
  }
  return [
    for (final e in buckets.entries)
      MonthPoint(e.key, MonthlySummary.compute(e.value)),
  ];
}

/// Builds the searchable text of a transaction: description, notes, person,
/// tags, category, account and card names, amount and dates in the formats
/// people type.
final transactionSearchTextProvider =
    Provider.autoDispose<String Function(Transaction)>((ref) {
      final l10n = ref.watch(l10nProvider);
      final accounts = ref.watch(accountsByIdProvider);
      final cards = ref.watch(cardsByIdProvider);
      final money = ref.watch(currencyFormatterProvider);
      final day = DateFormat('d MMM yyyy');
      return (tx) => [
        tx.description,
        tx.notes,
        tx.counterparty,
        ...tx.tags,
        l10n.categoryLabel(tx.categoryId),
        if (tx.subCategoryId != null) l10n.categoryLabel(tx.subCategoryId),
        l10n.transactionType(tx.type),
        accounts[tx.accountId]?.displayName ?? '',
        accounts[tx.toAccountId]?.displayName ?? '',
        cards[tx.creditCardId]?.displayName ?? '',
        money.format(tx.amountMinor),
        Money.toEditable(tx.amountMinor),
        day.format(tx.date),
        Dates.compactKey(tx.date),
        '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}',
      ].join(' ');
    });

/// Filters applied on the transactions tab.
class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() {
    ref.watch(uidProvider);
    return const TransactionFilter();
  }

  void update(TransactionFilter filter) => state = filter;

  void setText(String text) => state = state.copyWith(text: text);

  void clearFilters() => state = state.clearFilters();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

/// A custom date range on the transactions tab; null follows the selected
/// month.
class CustomRangeNotifier extends Notifier<DateRange?> {
  @override
  DateRange? build() {
    ref.watch(uidProvider);
    return null;
  }

  void set(DateRange? range) => state = range;
}

final customRangeProvider = NotifierProvider<CustomRangeNotifier, DateRange?>(
  CustomRangeNotifier.new,
);

final activeTransactionRangeProvider = Provider<DateRange>(
  (ref) =>
      ref.watch(customRangeProvider) ??
      DateRange.month(ref.watch(selectedMonthProvider)),
);

final visibleTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<Transaction>>>((ref) {
      final range = ref.watch(activeTransactionRangeProvider);
      final filter = ref.watch(transactionFilterProvider);
      final searchText = ref.watch(transactionSearchTextProvider);
      return ref
          .watch(transactionsInRangeProvider(range))
          .whenData(
            (list) => TransactionQuery.apply(
              list,
              filter,
              searchText: searchText,
            ),
          );
    });

/// Optional account/card scope for the dashboard, so every figure and chart
/// can be narrowed to one account or card.
class DashboardScope {
  const DashboardScope({this.accountId, this.cardId});
  final String? accountId;
  final String? cardId;

  bool get isAll => accountId == null && cardId == null;

  bool includes(Transaction tx) {
    if (accountId != null) {
      return tx.accountId == accountId || tx.toAccountId == accountId;
    }
    if (cardId != null) return tx.creditCardId == cardId;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardScope &&
      other.accountId == accountId &&
      other.cardId == cardId;

  @override
  int get hashCode => Object.hash(accountId, cardId);
}

class DashboardScopeNotifier extends Notifier<DashboardScope> {
  @override
  DashboardScope build() {
    // A scope pointing at the previous user's account would zero out the
    // next user's dashboard.
    ref.watch(uidProvider);
    return const DashboardScope();
  }

  void set(DashboardScope scope) => state = scope;
}

final dashboardScopeProvider =
    NotifierProvider<DashboardScopeNotifier, DashboardScope>(
      DashboardScopeNotifier.new,
    );

final dashboardSummaryProvider = Provider.autoDispose<AsyncValue<MonthlySummary>>(
  (ref) {
    final month = ref.watch(selectedMonthProvider);
    final scope = ref.watch(dashboardScopeProvider);
    return ref
        .watch(monthTransactionsProvider(month))
        .whenData((list) => MonthlySummary.compute(list.where(scope.includes)));
  },
);

final dashboardTrendProvider = Provider.autoDispose<AsyncValue<List<MonthPoint>>>(
  (ref) {
    final month = ref.watch(selectedMonthProvider);
    final scope = ref.watch(dashboardScopeProvider);
    final range = DateRange.lastMonths(month, trendMonths);
    return ref
        .watch(transactionsInRangeProvider(range))
        .whenData((list) => monthPoints(range, list.where(scope.includes)));
  },
);

/// Latest transactions linked to an entity (account, card, loan…).
final linkedTransactionsProvider = StreamProvider.autoDispose
    .family<List<Transaction>, (String, String)>(
      (ref, key) =>
          ref.watch(transactionRepositoryProvider).watchLinked(key.$1, key.$2),
    );
