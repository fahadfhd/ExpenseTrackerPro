import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:kept/features/debt_plan/application/debt_plan_providers.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/debt_plan/domain/financial_profile.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _gap = SizedBox(height: 12);

/// Entry point for "I got extra money", with what the app noticed.
class ExtraMoneyCard extends ConsumerWidget {
  const ExtraMoneyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final unusual =
        ref.watch(financialProfileProvider)?.unusualIncomeMinor ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        title: l10n.extraMoneyTitle,
        subtitle: l10n.extraMoneySubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (unusual > 0) ...[
              Text(
                l10n.extraMoneyDetected(money.format(unusual)),
                style: TextStyle(
                  color: context.finance.positive,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _gap,
            ],
            FilledButton.icon(
              icon: const Icon(Icons.payments_rounded),
              label: Text(l10n.extraMoneyAction),
              onPressed: () => AppRoutes.extraMoney(
                context,
                initial: unusual > 0 ? unusual : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far the debt has come, from the monthly history.
class DebtProgressCard extends ConsumerWidget {
  const DebtProgressCard({super.key, required this.plan});

  final DebtPlan plan;

  /// More points than this crowd the month labels on a phone.
  static const _chartPoints = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(debtProgressProvider).value;
    if (progress == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final total = plan.totalOwedMinor;
    final openIds = {for (final d in plan.debts) d.id};
    final paid = progress.paidDownMinor(total);
    final cleared = progress.clearedNames(openIds);
    final justCleared = progress.clearedThisMonth(
      ref.watch(clockProvider)(),
      openIds,
    );
    final history = progress.snapshots.length > _chartPoints
        ? progress.snapshots.sublist(progress.snapshots.length - _chartPoints)
        : progress.snapshots;
    if (paid <= 0 && cleared.isEmpty) return const SizedBox.shrink();
    final format = DateFormat(
      'MMM yy',
      Localizations.localeOf(context).toString(),
    );
    final paidText = l10n.debtProgressPaid(
      money.format(paid),
      money.format(progress.peakMinor),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        title: l10n.debtProgressTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (justCleared.isNotEmpty) ...[
              Text(
                l10n.debtProgressJustCleared(justCleared.join(', ')),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.finance.positive,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _gap,
            ],
            Text(paidText),
            const SizedBox(height: 8),
            ProgressMeter(
              ratio: progress.paidRatio(total),
              semanticsLabel: paidText,
              warnAt: 2,
              alertAt: 3,
            ),
            if (cleared.isNotEmpty) ...[
              _gap,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final name in cleared)
                    StatusChip(
                      label: name,
                      icon: Icons.emoji_events_rounded,
                      color: context.finance.positive,
                    ),
                ],
              ),
            ],
            if (history.length >= 2) ...[
              _gap,
              TrendLineChart(
                labels: [for (final s in history) format.format(s.month)],
                values: [for (final s in history) s.totalMinor],
                semanticsLabel: paidText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// How much of usual income goes to required debt payments.
class DebtLoadCard extends ConsumerWidget {
  const DebtLoadCard({super.key, required this.plan});

  final DebtPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(financialProfileProvider);
    final minimums = plan.monthlyMinimumMinor;
    final load = profile?.debtLoad(minimums);
    if (profile == null || load == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final finance = context.finance;
    final (label, advice, color, icon) = switch (profile.debtLoadBand(
      minimums,
    )!) {
      DebtLoad.healthy => (
        l10n.debtLoadHealthy,
        l10n.debtLoadHealthyHelp,
        finance.positive,
        Icons.check_circle_rounded,
      ),
      DebtLoad.watch => (
        l10n.debtLoadWatch,
        l10n.debtLoadWatchHelp,
        finance.warning,
        Icons.info_rounded,
      ),
      DebtLoad.high => (
        l10n.debtLoadHigh,
        l10n.debtLoadHighHelp,
        finance.negative,
        Icons.error_rounded,
      ),
    };
    final percent = (load * 100).round();
    final headroom = profile.headroomMinor(minimums);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SectionCard(
        title: l10n.debtLoadTitle,
        trailing: StatusChip(label: label, icon: icon, color: color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.debtLoadShare('$percent')),
            const SizedBox(height: 8),
            ProgressMeter(
              ratio: load,
              semanticsLabel: l10n.debtLoadShare('$percent'),
              warnAt: FinancialProfile.watchLoadAt,
              alertAt: FinancialProfile.highLoadAt,
            ),
            const SizedBox(height: 8),
            Text(advice),
            if (headroom < 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.debtLoadOverBudget(money.format(-headroom)),
                style: TextStyle(
                  color: finance.negative,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opt-in monthly notification saying what to pay.
class DebtPlanReminderSwitch extends ConsumerWidget {
  const DebtPlanReminderSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(context.l10n.debtPlanReminder),
    subtitle: Text(context.l10n.debtPlanReminderHelp),
    value: ref.watch(debtPlanSettingsProvider.select((s) => s.reminderEnabled)),
    onChanged: ref.read(debtPlanSettingsProvider.notifier).setReminder,
  );
}
