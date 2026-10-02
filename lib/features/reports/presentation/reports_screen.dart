import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/borrow_lend/application/debt_providers.dart';
import 'package:expensetrackerpro/features/borrow_lend/domain/debt_record.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/loans/application/loan_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/monthly_summary.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/vehicles/application/vehicle_providers.dart';
import 'package:expensetrackerpro/shared/widgets/charts.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:expensetrackerpro/shared/widgets/section_card.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

@immutable
class ReportFilter {
  const ReportFilter({
    required this.range,
    this.accountId,
    this.cardId,
    this.categoryId,
  });

  final DateRange range;
  final String? accountId;
  final String? cardId;
  final String? categoryId;

  bool includes(Transaction tx) {
    if (accountId != null &&
        tx.accountId != accountId &&
        tx.toAccountId != accountId) {
      return false;
    }
    if (cardId != null && tx.creditCardId != cardId) return false;
    if (categoryId != null && tx.categoryId != categoryId) return false;
    return true;
  }

  ReportFilter copyWith({
    DateRange? range,
    String? Function()? accountId,
    String? Function()? cardId,
    String? Function()? categoryId,
  }) => ReportFilter(
    range: range ?? this.range,
    accountId: accountId != null ? accountId() : this.accountId,
    cardId: cardId != null ? cardId() : this.cardId,
    categoryId: categoryId != null ? categoryId() : this.categoryId,
  );
}

class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() => ReportFilter(range: DateRange.month(DateTime.now()));

  void set(ReportFilter filter) => state = filter;
}

final reportFilterProvider =
    NotifierProvider.autoDispose<ReportFilterNotifier, ReportFilter>(
      ReportFilterNotifier.new,
    );

class ReportData {
  const ReportData({
    required this.transactions,
    required this.summary,
    required this.months,
  });
  final List<Transaction> transactions;
  final MonthlySummary summary;
  final List<MonthPoint> months;
}

final reportDataProvider = Provider.autoDispose<AsyncValue<ReportData>>((ref) {
  final filter = ref.watch(reportFilterProvider);
  return ref.watch(transactionsInRangeProvider(filter.range)).whenData((all) {
    final list = all.where(filter.includes).toList();
    return ReportData(
      transactions: list,
      summary: MonthlySummary.compute(list),
      months: monthPoints(
        DateRange(Dates.monthOf(filter.range.start), filter.range.end),
        list,
      ),
    );
  });
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(reportDataProvider);
    final tabs = [
      (l10n.reportSummary, (ReportData d) => _SummaryTab(d)),
      (l10n.reportCategories, (ReportData d) => _CategoriesTab(d)),
      (l10n.reportAccounts, (ReportData d) => _AccountsTab(d)),
      (l10n.reportCards, (ReportData d) => _CardsTab(d)),
      (l10n.reportLoans, (ReportData d) => const _LoansTab()),
      (l10n.reportDebts, (ReportData d) => const _DebtsTab()),
      (l10n.reportFuel, (ReportData d) => const _FuelTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reportsTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in tabs) Tab(text: t.$1)],
          ),
        ),
        body: Column(
          children: [
            const _FilterBar(),
            Expanded(
              child: AsyncView<ReportData>(
                value: data,
                data: (d) =>
                    TabBarView(children: [for (final t in tabs) t.$2(d)]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cards = ref.watch(cardsProvider).value ?? const [];
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.yMMMd(locale);
    final rangeLabel =
        '${fmt.format(filter.range.start)} – ${fmt.format(filter.range.end.subtract(const Duration(days: 1)))}';

    Future<void> pickRange() async {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 30),
        lastDate: DateTime(now.year + 5),
        initialDateRange: DateTimeRange(
          start: filter.range.start,
          end: filter.range.end.subtract(const Duration(days: 1)),
        ),
      );
      if (picked == null) return;
      notifier.set(
        filter.copyWith(
          range: DateRange(
            Dates.dayOf(picked.start),
            Dates.dayOf(picked.end).add(const Duration(days: 1)),
          ),
        ),
      );
    }

    void setMonth(int delta) {
      final m = DateTime(
        filter.range.start.year,
        filter.range.start.month + delta,
      );
      notifier.set(filter.copyWith(range: DateRange.month(m)));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setMonth(-1),
          ),
          ActionChip(
            avatar: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(rangeLabel),
            onPressed: pickRange,
          ),
          IconButton(
            tooltip: l10n.nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => setMonth(1),
          ),
          const SizedBox(width: 4),
          _ChoiceMenu<String>(
            label: filter.accountId == null
                ? l10n.reportAllAccounts
                : (accounts
                          .where((a) => a.id == filter.accountId)
                          .firstOrNull
                          ?.name ??
                      ''),
            selected: filter.accountId != null,
            options: [for (final a in accounts) PickerOption(a.id, a.name)],
            noneLabel: l10n.reportAllAccounts,
            onChanged: (v) => notifier.set(
              filter.copyWith(accountId: () => v, cardId: () => null),
            ),
          ),
          const SizedBox(width: 8),
          _ChoiceMenu<String>(
            label: filter.cardId == null
                ? l10n.reportAllCards
                : (cards
                          .where((c) => c.id == filter.cardId)
                          .firstOrNull
                          ?.displayName ??
                      ''),
            selected: filter.cardId != null,
            options: [for (final c in cards) PickerOption(c.id, c.displayName)],
            noneLabel: l10n.reportAllCards,
            onChanged: (v) => notifier.set(
              filter.copyWith(cardId: () => v, accountId: () => null),
            ),
          ),
          const SizedBox(width: 8),
          _ChoiceMenu<String>(
            label: filter.categoryId == null
                ? l10n.reportAllCategories
                : l10n.categoryLabel(filter.categoryId),
            selected: filter.categoryId != null,
            options: [
              for (final c in [...Categories.expense, ...Categories.income])
                PickerOption(c.id, l10n.categoryLabel(c.id)),
            ],
            noneLabel: l10n.reportAllCategories,
            onChanged: (v) =>
                notifier.set(filter.copyWith(categoryId: () => v)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceMenu<T> extends StatelessWidget {
  const _ChoiceMenu({
    required this.label,
    required this.selected,
    required this.options,
    required this.noneLabel,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final List<PickerOption<T>> options;
  final String noneLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      onSelected: (v) => onChanged(v == _none ? null : v as T),
      itemBuilder: (_) => [
        PopupMenuItem(value: _none, child: Text(noneLabel)),
        for (final o in options)
          PopupMenuItem(value: o.value, child: Text(o.label)),
      ],
      child: Chip(
        label: Text(label),
        avatar: Icon(
          selected ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          size: 18,
        ),
      ),
    );
  }
}

const _none = Object();

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab(this.data);
  final ReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = data.summary;
    final locale = Localizations.localeOf(context).toString();
    Widget row(String label, int value, {MoneyTone tone = MoneyTone.neutral}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              FitAmount(
                child: MoneyText(
                  value,
                  tone: tone,
                  signed: tone != MoneyTone.neutral,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.reportSummary,
          child: Column(
            children: [
              row(l10n.dashboardIncome, s.income, tone: MoneyTone.positive),
              row(l10n.dashboardSpending, s.spending, tone: MoneyTone.negative),
              row(l10n.dashboardEmi, s.emi),
              row(
                l10n.dashboardSavings,
                s.savings,
                tone: s.savings >= 0 ? MoneyTone.positive : MoneyTone.negative,
              ),
              row(l10n.dashboardCardSpending, s.cardSpending),
              row(l10n.dashboardBorrowed, s.borrowed),
              row(l10n.dashboardLent, s.lent),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.reportTransactions)),
                    FitAmount(child: Text('${s.transactionCount}')),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (data.months.length > 1) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.reportMonthly,
            child: MonthlyBarChart(
              aLabel: l10n.dashboardSpending,
              bLabel: l10n.dashboardIncome,
              semanticsLabel: l10n.chartIncomeVsSpending,
              months: [
                for (final p in data.months)
                  MonthBar(
                    label: DateFormat.MMM(locale).format(p.month),
                    a: p.summary.spending,
                    b: p.summary.income,
                  ),
              ],
            ),
          ),
        ] else if (s.byDay.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.chartDaily,
            child: DailyBarChart(
              byDay: s.byDay,
              daysInMonth: Dates.daysInMonth(
                data.months.first.month.year,
                data.months.first.month.month,
              ),
              semanticsLabel: l10n.chartDaily,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab(this.data);
  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.chartByCategory,
          child: data.summary.byCategory.isEmpty
              ? Text(l10n.chartNoData)
              : RankedBars(
                  maxItems: 20,
                  items: [
                    for (final e in data.summary.byCategory.entries)
                      BarItem(
                        label: l10n.categoryLabel(e.key),
                        valueMinor: e.value,
                        icon: Categories.byId(e.key).icon,
                        iconColor: Categories.byId(e.key).color,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AccountsTab extends ConsumerWidget {
  const _AccountsTab(this.data);
  final ReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    if (accounts.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_rounded,
        message: l10n.reportNoAccounts,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.chartByAccount,
          child: data.summary.byAccount.isEmpty
              ? Text(l10n.chartNoData)
              : RankedBars(
                  maxItems: 20,
                  items: [
                    for (final e in data.summary.byAccount.entries)
                      BarItem(
                        label:
                            accounts
                                .where((a) => a.id == e.key)
                                .firstOrNull
                                ?.name ??
                            '—',
                        valueMinor: e.value,
                        icon: Icons.account_balance_rounded,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.currentBalance,
          child: Column(
            children: [
              for (final a in accounts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.name),
                  subtitle: Text(l10n.accountType(a.type)),
                  trailing: MoneyText(
                    a.balanceMinor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardsTab extends ConsumerWidget {
  const _CardsTab(this.data);
  final ReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cards = ref.watch(cardsProvider).value ?? const [];
    if (cards.isEmpty) {
      return EmptyState(
        icon: Icons.credit_card_rounded,
        message: l10n.reportNoCards,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final c in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              title: c.displayName,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressMeter(
                    ratio: c.utilization,
                    semanticsLabel: l10n.utilization,
                    warnAt: 0.3,
                    alertAt: 0.75,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.utilizationValue('${(c.utilization * 100).round()}'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.outstanding)),
                      FitAmount(child: MoneyText(c.outstandingMinor)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.creditLimit)),
                      FitAmount(child: MoneyText(c.creditLimitMinor)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.reportPeriodSpending)),
                      FitAmount(
                        child: MoneyText(data.summary.byCard[c.id] ?? 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LoansTab extends ConsumerWidget {
  const _LoansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedules =
        ref.watch(loanSchedulesProvider).value?.values.toList() ?? const [];
    if (schedules.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_rounded,
        message: l10n.reportNoLoans,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in schedules)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              title: s.loan.name,
              subtitle: l10n.loanStatus(s.effectiveStatus),
              child: Column(
                children: [
                  SplitBar(
                    aLabel: l10n.principalPaid,
                    aMinor: s.paidPrincipalMinor + s.prepaidPrincipalMinor,
                    bLabel: l10n.outstandingPrincipal,
                    bMinor: s.outstandingPrincipalMinor,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.paidInterest)),
                      FitAmount(child: MoneyText(s.paidInterestMinor)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(l10n.remainingInterest)),
                      FitAmount(child: MoneyText(s.remainingInterestMinor)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.loanProgress(
                            '${s.paidCount}',
                            '${s.rows.length}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DebtsTab extends ConsumerWidget {
  const _DebtsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final records = ref.watch(debtsProvider).value ?? const <DebtRecord>[];
    final summary = ref.watch(debtSummaryProvider);
    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_rounded,
        message: l10n.reportNoDebts,
      );
    }
    final byPerson = <String, (int owe, int owed)>{};
    for (final r in records) {
      final current = byPerson[r.personName] ?? (0, 0);
      byPerson[r.personName] = r.direction == DebtDirection.borrowed
          ? (current.$1 + r.outstandingMinor, current.$2)
          : (current.$1, current.$2 + r.outstandingMinor);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.reportDebts,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.iOwe)),
                  FitAmount(child: MoneyText(summary.iOweMinor)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(l10n.owedToMe)),
                  FitAmount(child: MoneyText(summary.owedToMeMinor)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(l10n.overdueAmount)),
                  FitAmount(child: MoneyText(summary.overdueMinor)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(l10n.totalBorrowed)),
                  FitAmount(child: MoneyText(summary.borrowedTotalMinor)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text(l10n.totalLent)),
                  FitAmount(child: MoneyText(summary.lentTotalMinor)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.reportByPerson,
          child: Column(
            children: [
              for (final e in byPerson.entries.where(
                (e) => e.value.$1 > 0 || e.value.$2 > 0,
              ))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key),
                  subtitle: Text(
                    [
                      if (e.value.$1 > 0) l10n.iOwe,
                      if (e.value.$2 > 0) l10n.owedToMe,
                    ].join(' · '),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (e.value.$1 > 0)
                        MoneyText(
                          e.value.$1,
                          tone: MoneyTone.negative,
                          signed: true,
                        ),
                      if (e.value.$2 > 0)
                        MoneyText(
                          e.value.$2,
                          tone: MoneyTone.positive,
                          signed: true,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FuelTab extends ConsumerWidget {
  const _FuelTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(reportFilterProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final logs = ref.watch(fuelLogsProvider).value ?? const [];
    if (vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_car_rounded,
        message: l10n.reportNoVehicles,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.reportFuelInPeriod,
          child: RankedBars(
            maxItems: 20,
            items: [
              for (final v in vehicles)
                BarItem(
                  label: v.name,
                  icon: Icons.local_gas_station_rounded,
                  valueMinor: logs
                      .where(
                        (l) =>
                            l.vehicleId == v.id &&
                            filter.range.contains(l.date),
                      )
                      .fold(0, (s, l) => s + l.totalCostMinor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final v in vehicles)
          if (ref.watch(vehicleStatsProvider(v.id)) case final stats?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                title: v.name,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.fuelMonthlyAverage)),
                        FitAmount(
                          child: MoneyText(stats.monthlyAverageCostMinor),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text(l10n.fuelYearlyEstimate)),
                        FitAmount(child: MoneyText(stats.yearlyEstimateMinor)),
                      ],
                    ),
                    if (stats.costPerKmMinor != null)
                      Row(
                        children: [
                          Expanded(child: Text(l10n.costPerKm)),
                          FitAmount(
                            child: Text(
                              ref
                                  .watch(currencyFormatterProvider)
                                  .format(stats.costPerKmMinor!.round()),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
