import 'dart:math';

import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/loans/domain/amortization.dart';

/// Which debt receives the money left over after every minimum is paid.
enum PayoffStrategy {
  /// Highest interest rate first: the lowest total cost.
  avalanche,

  /// Smallest balance first: the earliest closed debts.
  snowball,
}

enum PayoffDebtKind { loan, card, person }

/// One debt as the planner sees it. Amounts are minor units.
class PayoffDebt {
  const PayoffDebt({
    required this.id,
    required this.kind,
    required this.name,
    required this.balanceMinor,
    required this.annualRatePercent,
    this.fixedPaymentMinor = 0,
    this.minimumPercent = 0,
    this.minimumFloorMinor = 0,
    this.rateIsEstimated = false,
  });

  /// EMIs are normalised to a month, so quarterly and yearly loans are an
  /// approximation of their real schedule.
  factory PayoffDebt.fromLoan(LoanSchedule schedule) => PayoffDebt(
    id: schedule.loan.id,
    kind: PayoffDebtKind.loan,
    name: schedule.loan.name,
    balanceMinor: schedule.outstandingPrincipalMinor,
    annualRatePercent: schedule.loan.annualRatePercent,
    fixedPaymentMinor:
        (schedule.currentEmiMinor / schedule.loan.frequency.monthsPerPeriod)
            .round(),
  );

  /// The minimum due shrinks with the balance, so it is floored at 1% of the
  /// starting balance; without a floor it would never reach zero. The floor
  /// is relative because the app supports several currencies.
  factory PayoffDebt.fromCard(CreditCard card) => PayoffDebt(
    id: card.id,
    kind: PayoffDebtKind.card,
    name: card.displayName,
    balanceMinor: card.outstandingMinor,
    annualRatePercent:
        card.annualRatePercent ?? CreditCard.typicalAnnualRatePercent,
    minimumPercent: card.minimumDuePercent,
    minimumFloorMinor: max(1, (card.outstandingMinor * 0.01).ceil()),
    rateIsEstimated: card.annualRatePercent == null,
  );

  /// Money borrowed from a person: no interest and no required instalment.
  factory PayoffDebt.fromBorrowed(DebtRecord record) => PayoffDebt(
    id: record.id,
    kind: PayoffDebtKind.person,
    name: record.personName,
    balanceMinor: record.outstandingMinor,
    annualRatePercent: 0,
  );

  final String id;
  final PayoffDebtKind kind;
  final String name;
  final int balanceMinor;
  final double annualRatePercent;

  /// EMI per month, or 0 when the payment depends on the balance.
  final int fixedPaymentMinor;
  final double minimumPercent;
  final int minimumFloorMinor;
  final bool rateIsEstimated;

  double get monthlyRate => annualRatePercent / 100 / 12;

  /// The same debt after part of it has been paid; its terms do not change.
  PayoffDebt withBalance(int balance) => PayoffDebt(
    id: id,
    kind: kind,
    name: name,
    balanceMinor: balance,
    annualRatePercent: annualRatePercent,
    fixedPaymentMinor: fixedPaymentMinor,
    minimumPercent: minimumPercent,
    minimumFloorMinor: minimumFloorMinor,
    rateIsEstimated: rateIsEstimated,
  );

  int interestOn(int balance) => (balance * monthlyRate).round();

  /// Payment required this month on [balance], never more than is owed.
  int minimumFor(int balance) {
    final percent = (balance * minimumPercent / 100).ceil();
    return min(
      balance,
      max(fixedPaymentMinor, max(percent, minimumFloorMinor)),
    );
  }

  /// False for money borrowed from people, which has no due instalment.
  bool get hasRequiredPayment =>
      fixedPaymentMinor > 0 || minimumPercent > 0 || minimumFloorMinor > 0;

  /// False when the required payment does not even cover a month's interest,
  /// so that paying only the minimum makes the balance grow.
  bool get paymentCoversInterest {
    final interest = interestOn(balanceMinor);
    return interest == 0 || minimumFor(balanceMinor + interest) > interest;
  }
}

class PayoffMonth {
  const PayoffMonth({
    required this.date,
    required this.paymentsMinor,
    required this.interestMinor,
    required this.closingMinor,
  });

  /// First day of the month.
  final DateTime date;

  /// Debt id to amount paid this month.
  final Map<String, int> paymentsMinor;
  final int interestMinor;

  /// Total still owed after this month's payments.
  final int closingMinor;
}

/// The result of running one set of payment rules to the end.
class PayoffSchedule {
  const PayoffSchedule({
    required this.months,
    required this.clearedMonthIndex,
    required this.interestByDebtMinor,
    required this.finished,
    required this.monthlyBudgetMinor,
  });

  /// Longest horizon simulated; a plan still open by then is reported as
  /// unfinished rather than as a far-off date.
  static const maxMonths = 600;

  /// A balance this many times its starting size is never going to clear;
  /// stopping here also keeps compounding from overflowing an int.
  static const maxGrowth = 100;

  final List<PayoffMonth> months;

  /// Debt id to the zero-based month it reaches zero; absent if it never does.
  final Map<String, int> clearedMonthIndex;
  final Map<String, int> interestByDebtMinor;
  final bool finished;
  final int monthlyBudgetMinor;

  int get monthCount => months.length;

  int get totalInterestMinor =>
      interestByDebtMinor.values.fold(0, (sum, v) => sum + v);

  DateTime? get lastMonth => months.isEmpty ? null : months.last.date;

  /// Runs month by month: interest accrues, every minimum is paid, then
  /// whatever remains of the budget goes down [order] until it is used up.
  ///
  /// The budget stays constant, so the minimum of a closed debt automatically
  /// rolls onto the next one. Without [rollover] each debt only ever receives
  /// its own minimum, which is the "minimum payments only" comparison.
  /// [budgetMinor] fixes the budget instead of deriving it from the minimums.
  static PayoffSchedule simulate(
    List<PayoffDebt> order, {
    required int extraMinor,
    required DateTime start,
    bool rollover = true,
    int? budgetMinor,
  }) {
    final balances = {for (final d in order) d.id: d.balanceMinor};
    final interestByDebt = {for (final d in order) d.id: 0};
    final cleared = <String, int>{};
    final months = <PayoffMonth>[];
    int? budget;
    final runawayMinor =
        order.fold(0, (sum, d) => sum + d.balanceMinor) * maxGrowth;

    bool open() => balances.values.any((b) => b > 0);

    for (var index = 0; index < maxMonths && open(); index++) {
      var monthInterest = 0;
      for (final debt in order) {
        final balance = balances[debt.id]!;
        if (balance <= 0) continue;
        final interest = debt.interestOn(balance);
        balances[debt.id] = balance + interest;
        interestByDebt[debt.id] = interestByDebt[debt.id]! + interest;
        monthInterest += interest;
      }

      final payments = <String, int>{};
      var minimums = 0;
      for (final debt in order) {
        final balance = balances[debt.id]!;
        if (balance <= 0) continue;
        final payment = debt.minimumFor(balance);
        if (payment <= 0) continue;
        balances[debt.id] = balance - payment;
        payments[debt.id] = payment;
        minimums += payment;
      }

      budget ??= budgetMinor ?? minimums + extraMinor;
      if (rollover) {
        var pool = max(0, budget - minimums);
        for (final debt in order) {
          if (pool <= 0) break;
          final balance = balances[debt.id]!;
          if (balance <= 0) continue;
          final payment = min(pool, balance);
          balances[debt.id] = balance - payment;
          payments[debt.id] = (payments[debt.id] ?? 0) + payment;
          pool -= payment;
        }
      }

      for (final debt in order) {
        if (balances[debt.id]! <= 0) cleared.putIfAbsent(debt.id, () => index);
      }
      final closing = balances.values.fold(0, (sum, v) => sum + v);
      months.add(
        PayoffMonth(
          date: DateTime(start.year, start.month + index),
          paymentsMinor: payments,
          interestMinor: monthInterest,
          closingMinor: closing,
        ),
      );
      if (closing > runawayMinor) break;
    }

    return PayoffSchedule(
      months: List.unmodifiable(months),
      clearedMonthIndex: Map.unmodifiable(cleared),
      interestByDebtMinor: Map.unmodifiable(interestByDebt),
      finished: !open(),
      monthlyBudgetMinor: budget ?? 0,
    );
  }
}

/// What paying [stepMinor] more each month than the current plan would do.
class PayoffWhatIf {
  const PayoffWhatIf({
    required this.stepMinor,
    required this.schedule,
    required this.interestSavedMinor,
  });

  final int stepMinor;
  final PayoffSchedule schedule;
  final int interestSavedMinor;
}

/// A complete debt-free plan. Rules are in docs/IMPLEMENTATION_NOTES.md.
class DebtPlan {
  const DebtPlan._({
    required this.debts,
    required this.strategy,
    required this.extraMinor,
    required this.start,
    required this.order,
    required this.schedule,
    required this.avalanche,
    required this.snowball,
    required this.minimumsOnly,
  });

  factory DebtPlan.build(
    Iterable<PayoffDebt> debts, {
    required PayoffStrategy strategy,
    required int extraMinor,
    required DateTime start,
  }) {
    final open = debts.where((d) => d.balanceMinor > 0).toList();
    final firstMonth = DateTime(start.year, start.month);

    PayoffSchedule run(PayoffStrategy s) => PayoffSchedule.simulate(
      ordered(open, s),
      extraMinor: extraMinor,
      start: firstMonth,
    );

    final avalanche = run(PayoffStrategy.avalanche);
    final snowball = run(PayoffStrategy.snowball);
    return DebtPlan._(
      debts: open,
      strategy: strategy,
      extraMinor: extraMinor,
      start: firstMonth,
      order: ordered(open, strategy),
      schedule: strategy == PayoffStrategy.avalanche ? avalanche : snowball,
      avalanche: avalanche,
      snowball: snowball,
      // Debts with no required payment would never close in this comparison.
      minimumsOnly: PayoffSchedule.simulate(
        open.where((d) => d.hasRequiredPayment).toList(),
        extraMinor: 0,
        start: firstMonth,
        rollover: false,
      ),
    );
  }

  /// [debts] in the order that strategy targets them.
  static List<PayoffDebt> ordered(
    Iterable<PayoffDebt> debts,
    PayoffStrategy strategy,
  ) {
    int byRate(PayoffDebt a, PayoffDebt b) =>
        b.annualRatePercent.compareTo(a.annualRatePercent);
    int byBalance(PayoffDebt a, PayoffDebt b) =>
        a.balanceMinor.compareTo(b.balanceMinor);
    return debts.toList()..sort((a, b) {
      final (first, second) = strategy == PayoffStrategy.avalanche
          ? (byRate(a, b), byBalance(a, b))
          : (byBalance(a, b), byRate(a, b));
      if (first != 0) return first;
      return second != 0 ? second : a.id.compareTo(b.id);
    });
  }

  final List<PayoffDebt> debts;
  final PayoffStrategy strategy;
  final int extraMinor;
  final DateTime start;

  /// [debts] in target order for [strategy].
  final List<PayoffDebt> order;

  /// The schedule for the chosen [strategy].
  final PayoffSchedule schedule;
  final PayoffSchedule avalanche;
  final PayoffSchedule snowball;
  final PayoffSchedule minimumsOnly;

  int get totalOwedMinor => debts.fold(0, (sum, d) => sum + d.balanceMinor);

  int get monthlyMinimumMinor => schedule.monthlyBudgetMinor - extraMinor;

  bool get isComparable => schedule.finished && minimumsOnly.finished;

  /// Interest avoided compared with paying only the minimums.
  int get interestSavedMinor => isComparable
      ? max(0, minimumsOnly.totalInterestMinor - schedule.totalInterestMinor)
      : 0;

  /// Months sooner than minimum payments would finish, measured on the same
  /// debts: those with a required payment.
  int get monthsSooner {
    if (!isComparable) return 0;
    final required = debts.where((d) => d.hasRequiredPayment);
    final finish = required.fold(
      0,
      (latest, d) => max(latest, schedule.clearedMonthIndex[d.id]! + 1),
    );
    return max(0, minimumsOnly.monthCount - finish);
  }

  /// The debt receiving the extra money first; null when there is no extra
  /// money this month.
  PayoffDebt? get focus {
    if (schedule.months.isEmpty) return null;
    if (schedule.monthlyBudgetMinor <= monthlyMinimumMinor) return null;
    return order.first;
  }

  /// Debts in the order they get cleared; any that never clear come last.
  List<PayoffDebt> get roadmap {
    const never = PayoffSchedule.maxMonths + 1;
    final position = {for (var i = 0; i < order.length; i++) order[i].id: i};
    int cleared(PayoffDebt d) => schedule.clearedMonthIndex[d.id] ?? never;
    return order.toList()..sort((a, b) {
      final byMonth = cleared(a).compareTo(cleared(b));
      return byMonth != 0
          ? byMonth
          : position[a.id]!.compareTo(position[b.id]!);
    });
  }

  /// Debts whose required payment does not cover their interest.
  List<PayoffDebt> get underwater =>
      debts.where((d) => !d.paymentCoversInterest).toList();

  bool get hasEstimatedRates => debts.any((d) => d.rateIsEstimated);

  /// Interest the credit cards add in the first month.
  int get cardInterestPerMonthMinor => debts
      .where((d) => d.kind == PayoffDebtKind.card)
      .fold(0, (sum, d) => sum + d.interestOn(d.balanceMinor));

  /// Roughly 10%, 25% and 50% more than the minimums, in round numbers.
  List<PayoffWhatIf> get whatIfs {
    final base = monthlyMinimumMinor > 0
        ? monthlyMinimumMinor
        : totalOwedMinor ~/ 20;
    final steps = {
      for (final f in const [10, 25, 50]) _round(base * f ~/ 100),
    };
    return [
      for (final step in steps.toList()..sort())
        () {
          final result = PayoffSchedule.simulate(
            order,
            extraMinor: extraMinor + step,
            start: start,
          );
          return PayoffWhatIf(
            stepMinor: step,
            schedule: result,
            interestSavedMinor: schedule.finished && result.finished
                ? max(
                    0,
                    schedule.totalInterestMinor - result.totalInterestMinor,
                  )
                : 0,
          );
        }(),
    ];
  }

  /// Rounds to one significant digit of the major unit, at least 1.
  static int _round(int minor) {
    final major = max(1, minor ~/ 100);
    final unit = pow(10, major.toString().length - 1).toInt();
    return max(1, (major / unit).round()) * unit * 100;
  }
}
