import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/features/debt_plan/application/debt_plan_providers.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/debt_plan/domain/lump_sum.dart';
import 'package:kept/features/debt_plan/presentation/debt_plan_format.dart';
import 'package:kept/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "I got extra money": says which loan, EMI or card to put it towards.
class ExtraMoneyScreen extends ConsumerStatefulWidget {
  const ExtraMoneyScreen({super.key, this.initialMinor});

  /// Income the app noticed above the usual amount, if any.
  final int? initialMinor;

  @override
  ConsumerState<ExtraMoneyScreen> createState() => _ExtraMoneyScreenState();
}

class _ExtraMoneyScreenState extends ConsumerState<ExtraMoneyScreen> {
  late final _amount = TextEditingController(
    text: widget.initialMinor == null
        ? ''
        : Money.toEditable(widget.initialMinor!),
  );
  bool _keepReserve = true;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.extraMoneyTitle)),
      body: AsyncView<DebtPlan?>(
        value: ref.watch(debtPlanProvider),
        data: (plan) {
          if (plan == null) {
            return EmptyState(
              icon: Icons.celebration_rounded,
              message: l10n.debtPlanEmpty,
            );
          }
          final amount = Money.parse(_amount.text) ?? 0;
          final shortfall =
              ref
                  .watch(financialProfileProvider)
                  ?.reserveShortfallMinor(plan.monthlyMinimumMinor) ??
              0;
          final advice = amount <= 0
              ? null
              : LumpSumAdvice.build(
                  plan,
                  amount,
                  reserveShortfallMinor: _keepReserve ? shortfall : 0,
                );
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(l10n.extraMoneyIntro),
              const SizedBox(height: 12),
              AmountField(
                controller: _amount,
                label: l10n.extraMoneyAmount,
                required: false,
                allowZero: true,
                onChanged: (_) => setState(() {}),
              ),
              if (widget.initialMinor == null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.extraMoneyRecordIncome),
                    onPressed: () => TransactionFormSheet.show(
                      context,
                      kind: EntryKind.income,
                    ),
                  ),
                ),
              ],
              if (shortfall > 0)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.extraMoneyKeepReserve),
                  subtitle: Text(l10n.extraMoneyKeepReserveHelp),
                  value: _keepReserve,
                  onChanged: (v) => setState(() => _keepReserve = v),
                ),
              if (advice != null) ...[
                const SizedBox(height: 12),
                _AdviceCard(advice: advice),
                const SizedBox(height: 12),
                _ResultCard(plan: plan, advice: advice),
                const SizedBox(height: 12),
                Text(
                  l10n.extraMoneyCaution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice});

  final LumpSumAdvice advice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final amountStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
    );
    return SectionCard(
      title: l10n.extraMoneyDoThis,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          for (final item in advice.allocations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(payoffDebtIcon(item.debt.kind)),
              title: Text(
                item.debt.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                item.closes
                    ? l10n.extraMoneyCloses
                    : l10n.extraMoneyPartPayment,
                style: item.closes
                    ? TextStyle(
                        color: context.finance.positive,
                        fontWeight: FontWeight.w700,
                      )
                    : null,
              ),
              trailing: MoneyText(item.amountMinor, style: amountStyle),
              onTap: () => openPayoffDebt(context, item.debt),
            ),
          if (advice.keepMinor > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.shield_rounded),
              title: Text(
                l10n.extraMoneyKeep,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: MoneyText(advice.keepMinor, style: amountStyle),
            ),
          if (advice.leftoverMinor > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.savings_rounded),
              title: Text(
                l10n.extraMoneyLeftover,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: MoneyText(advice.leftoverMinor, style: amountStyle),
            ),
        ],
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.plan, required this.advice});

  final DebtPlan plan;
  final LumpSumAdvice advice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final instead = advice.closableInstead;
    return SectionCard(
      title: l10n.extraMoneyResult,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (advice.clearsEverything)
            Text(
              l10n.extraMoneyClearsAll,
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.finance.positive,
                fontWeight: FontWeight.w800,
              ),
            )
          else if (advice.after.finished)
            Text(
              l10n.extraMoneyNewDate(
                debtMonthYear(context, advice.after.lastMonth!),
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(l10n.debtPlanNeverClears),
          const SizedBox(height: 8),
          if (advice.interestSavedMinor > 0)
            DebtAmountRow(
              l10n.extraMoneyInterestSaved,
              debtApprox(advice.interestSavedMinor),
            ),
          if (advice.monthsSooner > 0)
            Text(
              l10n.extraMoneySooner(debtDuration(l10n, advice.monthsSooner)),
            ),
          if (advice.freedMonthlyMinor > 0)
            DebtAmountRow(
              l10n.extraMoneyFreed,
              debtApprox(advice.freedMonthlyMinor),
            ),
          if (instead != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.extraMoneyInstead(
                instead.name,
                money.format(instead.balanceMinor),
                money.format(
                  debtApprox(instead.minimumFor(instead.balanceMinor)),
                ),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
