import 'dart:async';

import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/haptics.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/transactions/domain/monthly_summary.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/transactions/presentation/filter_sheet.dart';
import 'package:kept/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:kept/features/transactions/presentation/transaction_tile.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/month_switcher.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:kept/shared/widgets/banner_ad_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _ViewMode { list, calendar }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late final TextEditingController _search;
  Timer? _debounce;
  _ViewMode _mode = _ViewMode.list;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(transactionFilterProvider).text,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(transactionFilterProvider.notifier).setText(text);
    });
  }

  Future<void> _pickRange() async {
    final current = ref.read(activeTransactionRangeProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(
        start: current.start,
        end: current.end.subtract(const Duration(days: 1)),
      ),
    );
    if (picked == null) return;
    ref
        .read(customRangeProvider.notifier)
        .set(
          DateRange(
            Dates.dayOf(picked.start),
            Dates.dayOf(picked.end).add(const Duration(days: 1)),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(transactionFilterProvider);
    final customRange = ref.watch(customRangeProvider);
    final range = ref.watch(activeTransactionRangeProvider);
    final visible = ref.watch(visibleTransactionsProvider);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTransactions),
        actions: [
          IconButton(
            tooltip: _mode == _ViewMode.list
                ? l10n.calendarView
                : l10n.listView,
            icon: Icon(
              _mode == _ViewMode.list
                  ? Icons.calendar_month_rounded
                  : Icons.view_list_rounded,
            ),
            onPressed: () => setState(() {
              _mode = _mode == _ViewMode.list
                  ? _ViewMode.calendar
                  : _ViewMode.list;
              _selectedDay = null;
            }),
          ),
          IconButton(
            tooltip: l10n.customRange,
            icon: const Icon(Icons.date_range_rounded),
            onPressed: _pickRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: customRange == null
                ? MonthSwitcher(
                    onChanged: () => setState(() => _selectedDay = null),
                  )
                : InputChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                      '${DateFormat.yMMMd(locale).format(range.start)} – '
                      '${DateFormat.yMMMd(locale).format(range.end.subtract(const Duration(days: 1)))}',
                    ),
                    tooltip: l10n.backToMonth,
                    onDeleted: () =>
                        ref.read(customRangeProvider.notifier).set(null),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: l10n.searchTransactions,
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.clear,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                _onSearch('');
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: filter.activeCount > 0,
                  label: Text('${filter.activeCount}'),
                  child: IconButton.filledTonal(
                    tooltip: filter.activeCount > 0
                        ? l10n.filtersActive('${filter.activeCount}')
                        : l10n.filters,
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => const TransactionFilterSheet(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView<List<Transaction>>(
              value: visible,
              onRetry: () => ref.invalidate(transactionsInRangeProvider(range)),
              loading: const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(),
              ),
              data: (list) => _mode == _ViewMode.list
                  ? _DailyList(transactions: list, filtered: !filter.isEmpty)
                  : _CalendarView(
                      month: Dates.monthOf(range.start),
                      transactions: list,
                      selectedDay: _selectedDay,
                      onSelect: (d) => setState(() => _selectedDay = d),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTotals extends StatelessWidget {
  const _PeriodTotals(this.summary);

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget cell(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            cell(
              l10n.moneyIn,
              MoneyText(
                summary.income,
                tone: MoneyTone.positive,
                signed: true,
                style: style,
              ),
            ),
            cell(
              l10n.moneyOut,
              MoneyText(
                summary.spending + summary.emi,
                tone: MoneyTone.negative,
                signed: true,
                style: style,
              ),
            ),
            cell(
              l10n.entriesLabel,
              Text('${summary.transactionCount}', style: style),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transactions grouped by day with a per-day spending total. Swipe a row
/// left to delete it; an Undo snackbar restores it.
class _DailyList extends ConsumerStatefulWidget {
  const _DailyList({required this.transactions, required this.filtered});

  final List<Transaction> transactions;
  final bool filtered;

  @override
  ConsumerState<_DailyList> createState() => _DailyListState();
}

class _DailyListState extends ConsumerState<_DailyList> {
  /// Ids swiped away. A `Dismissible` must leave the tree the moment it is
  /// dismissed, but the Firestore stream only catches up a moment later, so
  /// the row is hidden locally first.
  final _hidden = <String>{};

  /// Records owned by another module (loan EMIs, borrow/lend, fuel) must be
  /// changed there, so they can't be swiped away.
  static bool _swipeable(Transaction tx) =>
      tx.loanId == null && tx.borrowLendId == null && tx.vehicleId == null;

  void _delete(Transaction tx) {
    final repo = ref.read(transactionRepositoryProvider);
    setState(() => _hidden.add(tx.id));
    repo.delete(tx);
    Haptics.success();
    showUndo(
      context,
      context.l10n.transactionDeleted,
      onUndo: () {
        repo.save(tx);
        if (mounted) setState(() => _hidden.remove(tx.id));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transactions = [
      for (final tx in widget.transactions)
        if (!_hidden.contains(tx.id)) tx,
    ];
    if (transactions.isEmpty) {
      return EmptyState(
        icon: widget.filtered
            ? Icons.search_off_rounded
            : Icons.receipt_long_rounded,
        message: widget.filtered ? l10n.noMatches : l10n.noTransactions,
      );
    }
    // Group consecutive items by day (list is already sorted).
    final groups = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      groups.putIfAbsent(Dates.dayOf(tx.date), () => []).add(tx);
    }
    final days = groups.keys.toList();
    final summary = MonthlySummary.compute(transactions);
    final errorColor = Theme.of(context).colorScheme.error;

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: days.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _PeriodTotals(summary);
        // Footer: below the last transaction, never between them.
        if (index == days.length + 1) return const BannerAdSlot();
        final day = days[index - 1];
        final items = groups[day]!;
        final spent = items
            .where((t) => t.type.isSpending && t.isCleared)
            .fold<int>(0, (s, t) => s + t.amountMinor);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayHeader(day: day, spentMinor: spent),
            for (final tx in items)
              _swipeable(tx)
                  ? Dismissible(
                      key: ValueKey('tx-${tx.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(tx),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: AlignmentDirectional.centerEnd,
                        decoration: BoxDecoration(
                          color: errorColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: TransactionTile(
                        tx,
                        onTap: () => TransactionDetailSheet.show(context, tx),
                      ),
                    )
                  : TransactionTile(
                      tx,
                      onTap: () => TransactionDetailSheet.show(context, tx),
                    ),
          ],
        );
      },
    );
  }
}

class _DayHeader extends ConsumerWidget {
  const _DayHeader({required this.day, required this.spentMinor});

  final DateTime day;
  final int spentMinor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final label = Dates.sameDay(day, now)
        ? l10n.today
        : Dates.sameDay(day, now.subtract(const Duration(days: 1)))
        ? l10n.yesterday
        : DateFormat.MMMEd(
            Localizations.localeOf(context).toString(),
          ).format(day);
    final money = ref.watch(currencyFormatterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (spentMinor > 0)
              Flexible(
                child: Text(
                  l10n.dayTotal(money.format(spentMinor)),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Month grid showing what was spent each day; tapping a day lists it.
class _CalendarView extends ConsumerWidget {
  const _CalendarView({
    required this.month,
    required this.transactions,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime month;
  final List<Transaction> transactions;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final spentByDay = <int, int>{};
    final incomeDays = <int>{};
    for (final tx in transactions) {
      if (!Dates.sameMonth(tx.date, month) || !tx.isCleared) continue;
      if (tx.type.isSpending) {
        spentByDay[tx.date.day] =
            (spentByDay[tx.date.day] ?? 0) + tx.amountMinor;
      } else if (tx.type == TransactionType.income) {
        incomeDays.add(tx.date.day);
      }
    }
    final daysInMonth = Dates.daysInMonth(month.year, month.month);
    final firstWeekday = DateFormat('', locale).dateSymbols.FIRSTDAYOFWEEK;
    // DateTime.weekday: Mon=1..Sun=7; FIRSTDAYOFWEEK: Mon=0..Sun=6.
    final leading = (month.weekday - 1 - firstWeekday) % 7;
    final weekdayNames = DateFormat('', locale).dateSymbols.NARROWWEEKDAYS;
    final orderedNames = [
      for (var i = 0; i < 7; i++) weekdayNames[(firstWeekday + 1 + i) % 7],
    ];
    final selectedItems = selectedDay == null
        ? const <Transaction>[]
        : transactions
              .where((t) => Dates.sameDay(t.date, selectedDay!))
              .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final n in orderedNames)
                      Expanded(
                        child: Center(
                          child: Text(
                            n,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: leading + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leading) return const SizedBox.shrink();
                    final day = index - leading + 1;
                    final date = DateTime(month.year, month.month, day);
                    final spent = spentByDay[day] ?? 0;
                    final selected =
                        selectedDay != null &&
                        Dates.sameDay(date, selectedDay!);
                    final isToday = Dates.sameDay(date, DateTime.now());
                    final semantics = [
                      DateFormat.MMMEd(locale).format(date),
                      if (spent > 0) l10n.dayTotal(money.format(spent)),
                      if (incomeDays.contains(day)) l10n.txTypeIncome,
                    ].join(', ');
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: semantics,
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelect(date),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.colorScheme.primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday
                                ? Border.all(color: theme.colorScheme.primary)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (spent > 0)
                                FittedBox(
                                  child: Text(
                                    money.compact(spent),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              if (incomeDays.contains(day))
                                Icon(
                                  Icons.add_circle_rounded,
                                  size: 10,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedDay == null)
          EmptyState(
            icon: Icons.touch_app_rounded,
            message: l10n.selectDay,
            compact: true,
          )
        else if (selectedItems.isEmpty)
          EmptyState(
            icon: Icons.event_busy_rounded,
            message: l10n.noTransactionsOnDay,
            compact: true,
          )
        else
          for (final tx in selectedItems)
            TransactionTile(
              tx,
              onTap: () => TransactionDetailSheet.show(context, tx),
            ),
      ],
    );
  }
}
