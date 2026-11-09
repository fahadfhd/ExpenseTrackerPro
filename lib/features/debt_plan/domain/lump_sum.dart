import 'dart:math';

import 'package:kept/features/debt_plan/domain/debt_plan.dart';

/// One suggested payment out of a lump sum.
class LumpSumAllocation {
  const LumpSumAllocation({
    required this.debt,
    required this.amountMinor,
    required this.closes,
  });

  final PayoffDebt debt;
  final int amountMinor;

  /// True when this payment brings the debt to zero.
  final bool closes;
}

/// Where a one-off sum of extra money should go, and what that achieves.
class LumpSumAdvice {
  const LumpSumAdvice._({
    required this.amountMinor,
    required this.keepMinor,
    required this.allocations,
    required this.leftoverMinor,
    required this.after,
    required this.interestSavedMinor,
    required this.monthsSooner,
    required this.freedMonthlyMinor,
    required this.closableInstead,
  });

  /// At most this share goes to the emergency reserve: debt interest usually
  /// costs more than savings earn, so most of the money still clears debt.
  static const maxKeepPercent = 25;

  /// Spends [amountMinor] down the plan's own order, after setting aside part
  /// of it when savings fall short of [reserveShortfallMinor]. The monthly
  /// budget stays the same afterwards, so a closed EMI speeds up the rest.
  factory LumpSumAdvice.build(
    DebtPlan plan,
    int amountMinor, {
    int reserveShortfallMinor = 0,
  }) {
    final keep = min(
      max(0, reserveShortfallMinor),
      amountMinor * maxKeepPercent ~/ 100,
    );
    var remaining = amountMinor - keep;

    final allocations = <LumpSumAllocation>[];
    final afterOrder = <PayoffDebt>[];
    for (final debt in plan.order) {
      final payment = min(remaining, debt.balanceMinor);
      remaining -= payment;
      if (payment > 0) {
        allocations.add(
          LumpSumAllocation(
            debt: debt,
            amountMinor: payment,
            closes: payment == debt.balanceMinor,
          ),
        );
      }
      if (payment < debt.balanceMinor) {
        afterOrder.add(debt.withBalance(debt.balanceMinor - payment));
      }
    }

    final after = PayoffSchedule.simulate(
      afterOrder,
      extraMinor: 0,
      start: plan.start,
      budgetMinor: plan.schedule.monthlyBudgetMinor,
    );
    final comparable = plan.schedule.finished && after.finished;
    final closedIds = {
      for (final a in allocations)
        if (a.closes) a.debt.id,
    };
    final spendable = amountMinor - keep;

    // A debt this money could close outright, for people who would rather
    // lose an EMI than save the most interest.
    PayoffDebt? instead;
    for (final debt in plan.order) {
      if (closedIds.contains(debt.id) ||
          !debt.hasRequiredPayment ||
          debt.balanceMinor > spendable) {
        continue;
      }
      if (instead == null ||
          debt.minimumFor(debt.balanceMinor) >
              instead.minimumFor(instead.balanceMinor)) {
        instead = debt;
      }
    }

    return LumpSumAdvice._(
      amountMinor: amountMinor,
      keepMinor: keep,
      allocations: allocations,
      leftoverMinor: remaining,
      after: after,
      interestSavedMinor: comparable
          ? max(0, plan.schedule.totalInterestMinor - after.totalInterestMinor)
          : 0,
      monthsSooner: comparable
          ? max(0, plan.schedule.monthCount - after.monthCount)
          : 0,
      freedMonthlyMinor: allocations
          .where((a) => a.closes)
          .fold(0, (sum, a) => sum + a.debt.minimumFor(a.debt.balanceMinor)),
      closableInstead: instead,
    );
  }

  final int amountMinor;

  /// Set aside as emergency money.
  final int keepMinor;
  final List<LumpSumAllocation> allocations;

  /// Money left once every debt is cleared.
  final int leftoverMinor;

  /// The plan after these payments, at the same monthly budget.
  final PayoffSchedule after;
  final int interestSavedMinor;
  final int monthsSooner;

  /// Required payments that stop because their debts closed.
  final int freedMonthlyMinor;
  final PayoffDebt? closableInstead;

  bool get clearsEverything => after.finished && after.months.isEmpty;
}
