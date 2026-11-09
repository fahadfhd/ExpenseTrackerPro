import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String debtMonthYear(BuildContext context, DateTime date) =>
    DateFormat.yMMM(Localizations.localeOf(context).toString()).format(date);

String debtDuration(AppLocalizations l10n, int months) => months < 12
    ? l10n.debtPlanDurationMonths('$months')
    : l10n.debtPlanDurationYears('${months ~/ 12}', '${months % 12}');

String debtPercent(double value) =>
    value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// Projected figures are estimates, so paise would be false precision.
int debtApprox(int minor) =>
    (minor / Money.minorPerMajor).round() * Money.minorPerMajor;

void openPayoffDebt(BuildContext context, PayoffDebt debt) =>
    switch (debt.kind) {
      PayoffDebtKind.loan => AppRoutes.loan(context, debt.id),
      PayoffDebtKind.card => AppRoutes.card(context, debt.id),
      PayoffDebtKind.person => AppRoutes.debt(context, debt.id),
    };

IconData payoffDebtIcon(PayoffDebtKind kind) => switch (kind) {
  PayoffDebtKind.loan => Icons.account_balance_rounded,
  PayoffDebtKind.card => Icons.credit_card_rounded,
  PayoffDebtKind.person => Icons.handshake_rounded,
};

/// Label on the left, amount on the right.
class DebtAmountRow extends StatelessWidget {
  const DebtAmountRow(this.label, this.minor, {super.key, this.bold = false});

  final String label;
  final int minor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.w800) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: style)),
          FitAmount(child: MoneyText(minor, style: style)),
        ],
      ),
    );
  }
}
