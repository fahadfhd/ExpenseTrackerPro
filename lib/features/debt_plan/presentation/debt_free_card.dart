import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/features/debt_plan/application/debt_plan_providers.dart';
import 'package:kept/features/debt_plan/presentation/debt_plan_format.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard summary of the debt-free plan; hidden when nothing is owed.
class DebtFreeCard extends ConsumerWidget {
  const DebtFreeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(debtPlanProvider).value;
    if (plan == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final progress = ref.watch(debtProgressProvider).value;
    final ratio = progress?.paidRatio(plan.totalOwedMinor) ?? 0;
    final unusual =
        ref.watch(financialProfileProvider)?.unusualIncomeMinor ?? 0;
    final schedule = plan.schedule;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppRoutes.debtPlan(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.finished
                          ? '${l10n.debtPlanDebtFreeBy} '
                                '${debtMonthYear(context, schedule.lastMonth!)}'
                          : l10n.debtPlanTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              if (ratio > 0) ...[
                const SizedBox(height: 10),
                ProgressMeter(
                  ratio: ratio,
                  semanticsLabel: l10n.debtProgressPaid(
                    money.format(progress!.paidDownMinor(plan.totalOwedMinor)),
                    money.format(progress.peakMinor),
                  ),
                  warnAt: 2,
                  alertAt: 3,
                ),
              ],
              if (unusual > 0) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => AppRoutes.extraMoney(context, initial: unusual),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 18,
                        color: context.finance.positive,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.extraMoneyDetected(money.format(unusual)),
                          style: TextStyle(
                            color: context.finance.positive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
