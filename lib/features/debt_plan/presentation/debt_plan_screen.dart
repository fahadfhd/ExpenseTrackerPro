import 'dart:math';

import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/debt_plan/application/debt_plan_providers.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/debt_plan/presentation/debt_plan_format.dart';
import 'package:kept/features/debt_plan/presentation/debt_plan_sections.dart';
import 'package:kept/features/loans/application/loan_providers.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// A card at or above this rate is worth trying to move to a cheaper loan.
const _expensiveCardRatePercent = 24.0;

/// Share of a card's limit above which the utilization tip appears.
const _highUtilization = 0.3;

/// One place to see everything owed and the order to clear it in.
class DebtPlanScreen extends ConsumerStatefulWidget {
  const DebtPlanScreen({super.key});

  @override
  ConsumerState<DebtPlanScreen> createState() => _DebtPlanScreenState();
}

class _DebtPlanScreenState extends ConsumerState<DebtPlanScreen> {
  late final TextEditingController _extra;

  static String _editable(int minor) =>
      minor == 0 ? '' : Money.toEditable(minor);

  @override
  void initState() {
    super.initState();
    _extra = TextEditingController(
      text: _editable(ref.read(debtPlanSettingsProvider).extraMinor),
    );
  }

  @override
  void dispose() {
    _extra.dispose();
    super.dispose();
  }

  void _applyExtra(int minor) {
    _extra.text = _editable(minor);
    ref.read(debtPlanSettingsProvider.notifier).setExtra(minor);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.debtPlanTitle)),
      body: AsyncView<DebtPlan?>(
        value: ref.watch(debtPlanProvider),
        onRetry: () => ref.invalidate(loansProvider),
        data: (plan) {
          if (plan == null) {
            return EmptyState(
              icon: Icons.celebration_rounded,
              message: l10n.debtPlanEmpty,
            );
          }
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Summary(plan: plan),
              ..._Warnings.build(context, plan),
              const ExtraMoneyCard(),
              DebtProgressCard(plan: plan),
              DebtLoadCard(plan: plan),
              const SizedBox(height: 12),
              _MonthlyCard(
                plan: plan,
                controller: _extra,
                onExtraChanged: (text) => ref
                    .read(debtPlanSettingsProvider.notifier)
                    .setExtra(Money.parse(text) ?? 0),
                onAddStep: (step) => _applyExtra(plan.extraMinor + step),
              ),
              const SizedBox(height: 12),
              _StrategyCard(plan: plan),
              const SizedBox(height: 12),
              _ThisMonthCard(plan: plan),
              const SizedBox(height: 12),
              _RoadmapCard(plan: plan),
              const SizedBox(height: 12),
              _TipsCard(plan: plan),
              const SizedBox(height: 12),
              Text(
                l10n.debtPlanAssumptions,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.plan});

  final DebtPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schedule = plan.schedule;
    final saved = plan.interestSavedMinor;
    final sooner = plan.monthsSooner;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schedule.finished) ...[
            Text(l10n.debtPlanDebtFreeBy, style: theme.textTheme.labelMedium),
            Text(
              debtMonthYear(context, schedule.lastMonth!),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              l10n.debtPlanIn(debtDuration(l10n, schedule.monthCount)),
              style: theme.textTheme.bodySmall,
            ),
          ] else
            Text(
              l10n.debtPlanNeverClears,
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.finance.negative,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 12),
          DebtAmountRow(l10n.debtPlanTotalOwed, plan.totalOwedMinor),
          if (schedule.finished)
            DebtAmountRow(
              l10n.debtPlanInterestAhead,
              debtApprox(schedule.totalInterestMinor),
            ),
          if (saved > 0 || sooner > 0) ...[
            const SizedBox(height: 8),
            _SavingsLine(saved: saved, sooner: sooner),
          ],
          if (schedule.finished && schedule.monthCount >= 2) ...[
            const SizedBox(height: 16),
            Text(l10n.debtPlanChartTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _BalanceChart(plan: plan),
          ],
        ],
      ),
    );
  }
}

class _SavingsLine extends ConsumerWidget {
  const _SavingsLine({required this.saved, required this.sooner});

  final int saved;
  final int sooner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final amount = ref
        .watch(currencyFormatterProvider)
        .format(debtApprox(saved));
    final color = context.finance.positive;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.savings_rounded, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            sooner > 0
                ? l10n.debtPlanSavings(amount, debtDuration(l10n, sooner))
                : l10n.debtPlanSavingsInterestOnly(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _BalanceChart extends ConsumerWidget {
  const _BalanceChart({required this.plan});

  final DebtPlan plan;

  /// More points than this crowd the month labels on a phone.
  static const _points = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final months = plan.schedule.months;
    final format = DateFormat(
      'MMM yy',
      Localizations.localeOf(context).toString(),
    );
    final last = months.length - 1;
    final picks = {
      for (var i = 0; i < min(_points, months.length); i++)
        (last * i / max(1, min(_points, months.length) - 1)).round(),
    }.toList()..sort();
    final money = ref.watch(currencyFormatterProvider);
    return TrendLineChart(
      labels: [for (final i in picks) format.format(months[i].date)],
      values: [for (final i in picks) months[i].closingMinor],
      semanticsLabel: l10n.debtPlanChartSemantics(
        money.format(plan.totalOwedMinor),
        debtMonthYear(context, months.last.date),
      ),
    );
  }
}

/// Problems that make the plan wrong or the debt worse; shown near the top.
abstract final class _Warnings {
  static List<Widget> build(BuildContext context, DebtPlan plan) {
    final l10n = context.l10n;
    final underwater = plan.underwater;
    return [
      if (underwater.isNotEmpty)
        _Banner(
          icon: Icons.error_rounded,
          color: context.finance.negative,
          text: l10n.debtPlanLowPayment(
            underwater.map((d) => d.name).join(', '),
          ),
        ),
      if (plan.hasEstimatedRates)
        _Banner(
          icon: Icons.info_rounded,
          color: context.finance.warning,
          text: l10n.debtPlanEstimatedWarning(
            debtPercent(CreditCard.typicalAnnualRatePercent),
          ),
        ),
    ];
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _MonthlyCard extends ConsumerWidget {
  const _MonthlyCard({
    required this.plan,
    required this.controller,
    required this.onExtraChanged,
    required this.onAddStep,
  });

  final DebtPlan plan;
  final TextEditingController controller;
  final ValueChanged<String> onExtraChanged;
  final ValueChanged<int> onAddStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final suggested =
        ref
            .watch(financialProfileProvider)
            ?.suggestedExtraMinor(plan.monthlyMinimumMinor) ??
        0;
    return SectionCard(
      title: l10n.debtPlanMonthlyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(
            controller: controller,
            label: l10n.debtPlanExtraLabel,
            required: false,
            allowZero: true,
            onChanged: onExtraChanged,
          ),
          const SizedBox(height: 8),
          DebtAmountRow(l10n.debtPlanMinimums, plan.monthlyMinimumMinor),
          DebtAmountRow(l10n.debtPlanExtra, plan.extraMinor),
          DebtAmountRow(
            l10n.debtPlanTotalMonthly,
            plan.schedule.monthlyBudgetMinor,
            bold: true,
          ),
          const SizedBox(height: 6),
          Text(l10n.debtPlanCommitNote, style: theme.textTheme.bodySmall),
          if (suggested > 0 && suggested != plan.extraMinor) ...[
            const SizedBox(height: 10),
            Text(l10n.debtPlanSuggestedExtra(money.format(suggested))),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => onAddStep(suggested - plan.extraMinor),
                child: Text(l10n.debtPlanUseSuggested),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(l10n.debtPlanWhatIfTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          for (final option in plan.whatIfs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.debtPlanWhatIfRow(money.format(option.stepMinor)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                option.schedule.finished
                    ? l10n.debtPlanWhatIfDetail(
                        debtMonthYear(context, option.schedule.lastMonth!),
                        money.format(debtApprox(option.interestSavedMinor)),
                      )
                    : l10n.debtPlanWhatIfStillOpen,
              ),
              trailing: const Icon(Icons.add_circle_outline_rounded),
              onTap: () => onAddStep(option.stepMinor),
            ),
        ],
      ),
    );
  }
}

class _StrategyCard extends ConsumerWidget {
  const _StrategyCard({required this.plan});

  final DebtPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saving =
        plan.snowball.totalInterestMinor - plan.avalanche.totalInterestMinor;
    Widget option(
      PayoffStrategy strategy,
      String title,
      String help,
      PayoffSchedule schedule, {
      bool cheapest = false,
    }) => _StrategyOption(
      title: title,
      help: help,
      schedule: schedule,
      selected: plan.strategy == strategy,
      cheapest: cheapest,
      onTap: () =>
          ref.read(debtPlanSettingsProvider.notifier).setStrategy(strategy),
    );

    return SectionCard(
      title: l10n.debtPlanStrategyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          option(
            PayoffStrategy.avalanche,
            l10n.debtPlanAvalanche,
            l10n.debtPlanAvalancheHelp,
            plan.avalanche,
            cheapest: saving > 0,
          ),
          const SizedBox(height: 8),
          option(
            PayoffStrategy.snowball,
            l10n.debtPlanSnowball,
            l10n.debtPlanSnowballHelp,
            plan.snowball,
          ),
        ],
      ),
    );
  }
}

class _StrategyOption extends ConsumerWidget {
  const _StrategyOption({
    required this.title,
    required this.help,
    required this.schedule,
    required this.selected,
    required this.cheapest,
    required this.onTap,
  });

  final String title;
  final String help;
  final PayoffSchedule schedule;
  final bool selected;
  final bool cheapest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(help, style: theme.textTheme.bodySmall),
                      if (schedule.finished)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.debtPlanStrategyResult(
                              debtMonthYear(context, schedule.lastMonth!),
                              money.format(
                                debtApprox(schedule.totalInterestMinor),
                              ),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (cheapest)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: StatusChip(
                            label: l10n.debtPlanCheapest,
                            icon: Icons.savings_rounded,
                            color: context.finance.positive,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThisMonthCard extends StatelessWidget {
  const _ThisMonthCard({required this.plan});

  final DebtPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final first = plan.schedule.months.first;
    final focus = plan.focus;
    if (first.paymentsMinor.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: l10n.debtPlanThisMonthTitle(debtMonthYear(context, first.date)),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          for (final debt in plan.order)
            if ((first.paymentsMinor[debt.id] ?? 0) > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(payoffDebtIcon(debt.kind)),
                title: Text(debt.name),
                subtitle: debt.id == focus?.id
                    ? Text(
                        l10n.debtPlanFocus,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
                trailing: MoneyText(
                  first.paymentsMinor[debt.id]!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => openPayoffDebt(context, debt),
              ),
          const DebtPlanReminderSwitch(),
        ],
      ),
    );
  }
}

class _RoadmapCard extends ConsumerWidget {
  const _RoadmapCard({required this.plan});

  final DebtPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schedule = plan.schedule;
    final roadmap = plan.roadmap;
    final cards = ref.watch(cardsByIdProvider);

    String rateText(PayoffDebt debt) {
      if (debt.annualRatePercent == 0) return l10n.debtPlanNoInterest;
      final rate = debtPercent(debt.annualRatePercent);
      return debt.rateIsEstimated
          ? l10n.debtPlanRateEstimated(rate)
          : l10n.debtPlanRate(rate);
    }

    return SectionCard(
      title: l10n.debtPlanRoadmapTitle,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          for (final (index, debt) in roadmap.indexed)
            Builder(
              builder: (context) {
                final cleared = schedule.clearedMonthIndex[debt.id];
                final card = cards[debt.id];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    debt.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleared == null
                            ? l10n.debtPlanStepOpen
                            : l10n.debtPlanStepCleared(
                                debtMonthYear(
                                  context,
                                  schedule.months[cleared].date,
                                ),
                              ),
                      ),
                      Text(rateText(debt)),
                      if (debt.kind == PayoffDebtKind.card && card != null)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _editRate(context, ref, card),
                            child: Text(l10n.debtPlanSetRate),
                          ),
                        ),
                    ],
                  ),
                  trailing: MoneyText(
                    debt.balanceMinor,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => openPayoffDebt(context, debt),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    CreditCard card,
  ) async {
    final rate = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CardRateSheet(card: card),
    );
    if (rate == null) return;
    ref
        .read(creditCardRepositoryProvider)
        .save(
          card.copyWith(
            annualRatePercent: () => rate,
            updatedAt: ref.read(clockProvider)(),
          ),
        );
  }
}

class _CardRateSheet extends StatefulWidget {
  const _CardRateSheet({required this.card});

  final CreditCard card;

  @override
  State<_CardRateSheet> createState() => _CardRateSheetState();
}

class _CardRateSheetState extends State<_CardRateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _rate = TextEditingController(
    text: widget.card.annualRatePercent == null
        ? ''
        : debtPercent(widget.card.annualRatePercent!),
  );

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.debtPlanSetRateTitle(widget.card.displayName),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _rate,
                label: l10n.cardAnnualRate,
                suffix: '%',
                min: 0,
                max: 100,
                helper: l10n.cardAnnualRateHelp,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, NumberField.parse(_rate.text));
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends ConsumerWidget {
  const _TipsCard({required this.plan});

  final DebtPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final now = ref.watch(clockProvider)();
    final borrowedOverdue = (ref.watch(debtsProvider).value ?? const [])
        .where((r) => r.direction == DebtDirection.borrowed)
        .any((r) => r.statusAt(now) == DebtStatus.overdue);
    final highUse = ref
        .watch(activeCardsProvider)
        .where((c) => c.utilization > _highUtilization)
        .map((c) => c.displayName)
        .toList();
    final cardInterest = plan.cardInterestPerMonthMinor;
    final expensiveCard = plan.debts.any(
      (d) =>
          d.kind == PayoffDebtKind.card &&
          d.annualRatePercent >= _expensiveCardRatePercent,
    );

    final tips = [
      if (ref.watch(loansOverviewProvider).overdueCount > 0 || borrowedOverdue)
        l10n.debtPlanTipOverdue,
      if (cardInterest > 0)
        l10n.debtPlanTipCardInterest(money.format(debtApprox(cardInterest))),
      if (highUse.isNotEmpty) l10n.debtPlanTipUtilization(highUse.join(', ')),
      if (expensiveCard) l10n.debtPlanTipConsolidate,
    ];
    if (tips.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      title: l10n.debtPlanTipsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          if (expensiveCard)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => AppRoutes.debtSwitch(context),
                child: Text(l10n.debtPlanCompareSwitch),
              ),
            ),
        ],
      ),
    );
  }
}
