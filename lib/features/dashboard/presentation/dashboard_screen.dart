import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/routing/app_routes.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/budgets/application/budget_providers.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/dashboard/application/upcoming_provider.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/monthly_summary.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction_query.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_tile.dart';
import 'package:expensetrackerpro/shared/widgets/charts.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:expensetrackerpro/shared/widgets/month_switcher.dart';
import 'package:expensetrackerpro/shared/widgets/section_card.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Answers "how am I doing this month?" first, then lets the user drill in.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.searchEverything,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => AppRoutes.search(context),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => AppRoutes.settings(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(transactionsInRangeProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            const Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MonthSwitcher(),
                  ),
                ),
                _SyncIndicator(),
              ],
            ),
            const _ScopeSelector(),
            const SizedBox(height: 8),
            AsyncView<MonthlySummary>(
              value: summary,
              onRetry: () => ref.invalidate(transactionsInRangeProvider),
              loading: const Column(
                children: [
                  Skeleton(height: 170, radius: 28),
                  SizedBox(height: 12),
                  SkeletonList(count: 3),
                ],
              ),
              data: (s) => _DashboardBody(summary: s, month: month),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncIndicator extends ConsumerWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(syncStatusProvider);
    final theme = Theme.of(context);
    final text = status.isSynced
        ? l10n.syncAllSynced
        : l10n.syncPending('${status.pending}');
    return Tooltip(
      message: text,
      child: Semantics(
        label: text,
        excludeSemantics: true,
        child: Icon(
          status.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
          size: 20,
          color: status.isSynced
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}

/// Narrows every dashboard figure and chart to one account or card.
class _ScopeSelector extends ConsumerWidget {
  const _ScopeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scope = ref.watch(dashboardScopeProvider);
    final accounts = ref.watch(activeAccountsProvider);
    final cards = ref.watch(activeCardsProvider);
    if (accounts.isEmpty && cards.isEmpty) return const SizedBox.shrink();
    final notifier = ref.read(dashboardScopeProvider.notifier);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: Text(l10n.dashboardScopeAll),
            selected: scope.isAll,
            onSelected: (_) => notifier.set(const DashboardScope()),
          ),
          for (final a in accounts)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ChoiceChip(
                avatar: const Icon(Icons.account_balance_rounded, size: 16),
                label: Text(a.name),
                selected: scope.accountId == a.id,
                onSelected: (_) => notifier.set(DashboardScope(accountId: a.id)),
              ),
            ),
          for (final c in cards)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ChoiceChip(
                avatar: const Icon(Icons.credit_card_rounded, size: 16),
                label: Text(c.displayName),
                selected: scope.cardId == c.id,
                onSelected: (_) => notifier.set(DashboardScope(cardId: c.id)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary, required this.month});

  final MonthlySummary summary;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cards = ref.watch(cardsProvider).value ?? const [];
    final isFresh = summary.transactionCount == 0 && accounts.isEmpty && cards.isEmpty;
    final pending = ref.watch(pendingPaymentsProvider(month)) + summary.pending;
    final finance = context.finance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFresh) ...[const _Onboarding(), const SizedBox(height: 12)],
        _HeroCard(summary: summary, month: month),
        const SizedBox(height: 12),
        KpiGrid(
          children: [
            StatTile(
              label: l10n.dashboardEmi,
              icon: Icons.account_balance_wallet_rounded,
              value: MoneyText(summary.emi),
              onTap: () => ref.read(shellTabProvider.notifier).select(ShellTab.loans),
            ),
            StatTile(
              label: l10n.dashboardCardSpending,
              icon: Icons.credit_card_rounded,
              value: MoneyText(summary.cardSpending),
            ),
            StatTile(
              label: l10n.dashboardBorrowed,
              icon: Icons.call_received_rounded,
              value: MoneyText(summary.borrowed),
              onTap: () => AppRoutes.borrowLend(context),
            ),
            StatTile(
              label: l10n.dashboardLent,
              icon: Icons.call_made_rounded,
              value: MoneyText(summary.lent),
              onTap: () => AppRoutes.borrowLend(context),
            ),
            StatTile(
              label: l10n.dashboardPendingPayments,
              icon: Icons.pending_actions_rounded,
              color: pending > 0 ? finance.warning : null,
              value: MoneyText(pending),
            ),
            StatTile(
              label: l10n.netWorth,
              icon: Icons.savings_rounded,
              value: MoneyText(ref.watch(netWorthProvider).netMinor),
              onTap: () => ref.read(shellTabProvider.notifier).select(ShellTab.accounts),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _NotificationsOffBanner(),
        _BudgetCard(month: month),
        const _UpcomingCard(),
        const SizedBox(height: 12),
        _Charts(summary: summary, month: month),
        const SizedBox(height: 12),
        const _RecentTransactions(),
      ],
    );
  }
}

class _Onboarding extends StatelessWidget {
  const _Onboarding();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.emptyDashboardTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.emptyDashboardBody),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.account_balance_rounded),
                label: Text(l10n.addAccount),
                onPressed: () => AppRoutes.newAccount(context),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.credit_card_rounded),
                label: Text(l10n.addCard),
                onPressed: () => AppRoutes.newCard(context),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addExpense),
                onPressed: () => TransactionFormSheet.show(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.summary, required this.month});

  final MonthlySummary summary;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final monthName = DateFormat.MMMM(Localizations.localeOf(context).toString()).format(month);
    final savings = summary.savings;
    final rate = summary.savingsRate;
    const onHero = Colors.white;
    final verdict = summary.income == 0
        ? l10n.dashboardNoIncome
        : savings >= 0
        ? l10n.dashboardSavingsRate('${((rate ?? 0) * 100).round()}')
        : l10n.dashboardOverspent(money.format(-savings));

    Widget figure(String label, int value, IconData icon) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: onHero.withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: onHero.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          MoneyText(
            value,
            style: theme.textTheme.titleMedium?.copyWith(color: onHero, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7C66), Color(0xFF12906F), Color(0xFF0B5F5C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardSpentThisMonth(monthName),
            style: theme.textTheme.titleSmall?.copyWith(color: onHero.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 4),
          MoneyText(
            summary.spending,
            style: theme.textTheme.displaySmall?.copyWith(
              color: onHero,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                savings >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 18,
                color: onHero,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(verdict, style: theme.textTheme.bodyMedium?.copyWith(color: onHero)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              figure(l10n.dashboardIncome, summary.income, Icons.south_west_rounded),
              figure(l10n.dashboardSavings, savings, Icons.savings_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown when reminders exist but the OS blocks notifications, so dues are
/// never missed silently.
class _NotificationsOffBanner extends ConsumerWidget {
  const _NotificationsOffBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasReminders = (ref.watch(remindersProvider).value ?? const [])
        .any((r) => r.enabled);
    final enabled = ref.watch(notificationsEnabledProvider).value;
    if (!hasReminders || enabled != false) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: ListTile(
          leading: Icon(Icons.notifications_off_rounded, color: theme.colorScheme.onErrorContainer),
          title: Text(l10n.notificationsOff, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          trailing: TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).requestPermission();
              ref.invalidate(notificationsEnabledProvider);
              ref.read(notificationSyncProvider).resync();
            },
            child: Text(l10n.notificationsEnable),
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final usage = ref.watch(budgetUsageProvider(month)).value ?? const [];
    final overall = usage.where((u) => u.budget.isOverall).firstOrNull;
    if (overall == null) return const SizedBox.shrink();
    final money = ref.watch(currencyFormatterProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => AppRoutes.budgets(context),
        child: SectionCard(
          title: l10n.dashboardBudget,
          trailing: Text('${overall.percent}%'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProgressMeter(
                ratio: overall.ratio,
                semanticsLabel: l10n.dashboardBudget,
                warnAt: (overall.budget.thresholds.first) / 100,
              ),
              const SizedBox(height: 8),
              Text(
                overall.isOver
                    ? l10n.dashboardBudgetOver(money.format(-overall.remainingMinor))
                    : l10n.dashboardBudgetLeft(money.format(overall.remainingMinor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(upcomingProvider);
    final theme = Theme.of(context);
    final finance = context.finance;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    return SectionCard(
      title: l10n.dashboardUpcoming,
      trailing: TextButton(
        onPressed: () => AppRoutes.reminders(context),
        child: Text(l10n.remindersTitle),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(l10n.dashboardUpcomingEmpty),
            )
          : Column(
              children: [
                for (final item in items.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => AppRoutes.upcoming(context, item),
                    leading: Icon(switch (item.kind) {
                      UpcomingKind.card => Icons.credit_card_rounded,
                      UpcomingKind.loan => Icons.account_balance_wallet_rounded,
                      UpcomingKind.borrowed => Icons.call_received_rounded,
                      UpcomingKind.lent => Icons.call_made_rounded,
                      UpcomingKind.reminder => Icons.notifications_rounded,
                    }),
                    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: item.isOverdue(now)
                        ? Row(
                            children: [
                              Icon(Icons.error_rounded, size: 14, color: finance.negative),
                              const SizedBox(width: 4),
                              Text(l10n.dashboardOverdue, style: TextStyle(color: finance.negative, fontWeight: FontWeight.w700)),
                            ],
                          )
                        : Text(l10n.dashboardDueOn(DateFormat.MMMEd(locale).format(item.date))),
                    trailing: item.amountMinor == null
                        ? null
                        : MoneyText(
                            item.amountMinor!,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                  ),
              ],
            ),
    );
  }
}

class _Charts extends ConsumerWidget {
  const _Charts({required this.summary, required this.month});

  final MonthlySummary summary;
  final DateTime month;

  void _showCategory(WidgetRef ref, String categoryId) {
    ref.read(customRangeProvider.notifier).set(null);
    ref.read(transactionFilterProvider.notifier).update(
      TransactionFilter(categoryIds: {categoryId}),
    );
    ref.read(shellTabProvider.notifier).select(ShellTab.transactions);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final accounts = ref.watch(accountsByIdProvider);
    final cards = ref.watch(cardsByIdProvider);
    final trend = ref.watch(dashboardTrendProvider).value;
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.MMM(locale);

    String totalLabel(String title, int total) =>
        l10n.chartSemanticsTotal(title, money.format(total));

    Widget empty() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(l10n.chartNoData),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: l10n.chartByCategory,
          child: summary.byCategory.isEmpty
              ? empty()
              : RankedBars(
                  otherLabel: l10n.chartOther,
                  items: [
                    for (final e in summary.byCategory.entries)
                      BarItem(
                        label: l10n.categoryLabel(e.key),
                        valueMinor: e.value,
                        icon: Categories.byId(e.key).icon,
                        iconColor: Categories.byId(e.key).color,
                        onTap: () => _showCategory(ref, e.key),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.chartDaily,
          child: summary.byDay.isEmpty
              ? empty()
              : DailyBarChart(
                  byDay: summary.byDay,
                  daysInMonth: Dates.daysInMonth(month.year, month.month),
                  semanticsLabel: totalLabel(l10n.chartDaily, summary.spending),
                ),
        ),
        if (trend != null) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.chartIncomeVsSpending,
            child: MonthlyBarChart(
              aLabel: l10n.dashboardSpending,
              bLabel: l10n.dashboardIncome,
              semanticsLabel: [
                l10n.chartIncomeVsSpending,
                for (final p in trend)
                  '${monthLabel.format(p.month)}: ${l10n.dashboardSpending} ${money.format(p.summary.spending)}, ${l10n.dashboardIncome} ${money.format(p.summary.income)}',
              ].join('. '),
              months: [
                for (final p in trend)
                  MonthBar(
                    label: monthLabel.format(p.month),
                    a: p.summary.spending,
                    b: p.summary.income,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.chartTrend,
            child: TrendLineChart(
              labels: [for (final p in trend) monthLabel.format(p.month)],
              values: [for (final p in trend) p.summary.spending],
              semanticsLabel: [
                l10n.chartTrend,
                for (final p in trend)
                  '${monthLabel.format(p.month)} ${money.format(p.summary.spending)}',
              ].join(', '),
            ),
          ),
        ],
        if (summary.byAccount.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.chartByAccount,
            child: RankedBars(
              otherLabel: l10n.chartOther,
              items: [
                for (final e in summary.byAccount.entries)
                  BarItem(
                    label: accounts[e.key]?.name ?? '—',
                    valueMinor: e.value,
                    icon: Icons.account_balance_rounded,
                    onTap: () => AppRoutes.account(context, e.key),
                  ),
              ],
            ),
          ),
        ],
        if (summary.byCard.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.chartByCard,
            child: RankedBars(
              otherLabel: l10n.chartOther,
              items: [
                for (final e in summary.byCard.entries)
                  BarItem(
                    label: cards[e.key]?.displayName ?? '—',
                    valueMinor: e.value,
                    icon: Icons.credit_card_rounded,
                    onTap: () => AppRoutes.card(context, e.key),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthProvider);
    final list = ref.watch(monthTransactionsProvider(month)).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.dashboardRecent,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(shellTabProvider.notifier).select(ShellTab.transactions),
              child: Text(l10n.seeAll),
            ),
          ],
        ),
        if (list.isEmpty)
          EmptyState(icon: Icons.receipt_long_rounded, message: l10n.noTransactions, compact: true)
        else
          for (final tx in list.take(5))
            TransactionTile(tx, showDate: true, onTap: () => TransactionDetailSheet.show(context, tx)),
      ],
    );
  }
}
