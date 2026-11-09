import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/features/debt_plan/application/debt_plan_providers.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/debt_plan/domain/debt_switch.dart';
import 'package:kept/features/debt_plan/presentation/debt_plan_format.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Is moving a balance to a cheaper loan or EMI really cheaper after fees?
class DebtSwitchScreen extends ConsumerStatefulWidget {
  const DebtSwitchScreen({super.key});

  @override
  ConsumerState<DebtSwitchScreen> createState() => _DebtSwitchScreenState();
}

class _DebtSwitchScreenState extends ConsumerState<DebtSwitchScreen> {
  final _balance = TextEditingController();
  final _currentRate = TextEditingController();
  final _newRate = TextEditingController();
  final _months = TextEditingController(text: '12');
  final _fee = TextEditingController(text: '2');

  @override
  void initState() {
    super.initState();
    // Start from the most expensive card, the usual reason to come here.
    final plan = ref.read(debtPlanProvider).value;
    final cards = (plan?.debts ?? const <PayoffDebt>[])
        .where((d) => d.kind == PayoffDebtKind.card)
        .toList();
    if (cards.isEmpty) return;
    final dearest = DebtPlan.ordered(cards, PayoffStrategy.avalanche).first;
    _balance.text = Money.toEditable(dearest.balanceMinor);
    _currentRate.text = debtPercent(dearest.annualRatePercent);
  }

  @override
  void dispose() {
    for (final c in [_balance, _currentRate, _newRate, _months, _fee]) {
      c.dispose();
    }
    super.dispose();
  }

  DebtSwitchQuote? get _quote {
    final balance = Money.parse(_balance.text);
    final current = NumberField.parse(_currentRate.text);
    final next = NumberField.parse(_newRate.text);
    final months = int.tryParse(_months.text);
    final fee = NumberField.parse(_fee.text.isEmpty ? '0' : _fee.text);
    bool validRate(double? r) => r != null && r >= 0 && r <= 100;
    if (balance == null ||
        balance <= 0 ||
        !validRate(current) ||
        !validRate(next) ||
        !validRate(fee) ||
        months == null ||
        months <= 0 ||
        months > 600) {
      return null;
    }
    return DebtSwitchQuote.build(
      balanceMinor: balance,
      currentRatePercent: current!,
      newRatePercent: next!,
      months: months,
      feePercent: fee!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final quote = _quote;
    void refresh(String _) => setState(() {});
    const gap = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.debtSwitchTitle)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.debtSwitchIntro),
          gap,
          AmountField(
            controller: _balance,
            label: l10n.debtSwitchBalance,
            onChanged: refresh,
          ),
          gap,
          NumberField(
            controller: _currentRate,
            label: l10n.debtSwitchCurrentRate,
            suffix: '%',
            min: 0,
            max: 100,
            onChanged: refresh,
          ),
          gap,
          NumberField(
            controller: _newRate,
            label: l10n.debtSwitchNewRate,
            suffix: '%',
            min: 0,
            max: 100,
            onChanged: refresh,
          ),
          gap,
          NumberField(
            controller: _months,
            label: l10n.debtSwitchMonths,
            integer: true,
            min: 1,
            max: 600,
            onChanged: refresh,
          ),
          gap,
          NumberField(
            controller: _fee,
            label: l10n.debtSwitchFee,
            suffix: '%',
            min: 0,
            max: 100,
            required: false,
            helper: l10n.debtSwitchFeeHelp,
            onChanged: refresh,
          ),
          const SizedBox(height: 16),
          if (quote == null)
            Text(l10n.calcEnterValues)
          else
            SectionCard(
              title: l10n.debtSwitchResult,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    quote.isWorthIt
                        ? l10n.debtSwitchWorthIt(
                            money.format(debtApprox(quote.netSavingMinor)),
                          )
                        : l10n.debtSwitchNotWorthIt,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: quote.isWorthIt
                          ? context.finance.positive
                          : context.finance.negative,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DebtAmountRow(
                    l10n.debtSwitchKeepInterest,
                    debtApprox(quote.currentInterestMinor),
                  ),
                  DebtAmountRow(
                    l10n.debtSwitchNewInterest,
                    debtApprox(quote.newInterestMinor),
                  ),
                  DebtAmountRow(
                    l10n.debtSwitchFeeAmount,
                    debtApprox(quote.feeMinor),
                  ),
                  DebtAmountRow(
                    l10n.debtSwitchNewEmi,
                    debtApprox(quote.newEmiMinor),
                    bold: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
