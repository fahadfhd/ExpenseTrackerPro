import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';

PayoffDebt loan(String id, int balance, double rate, int emi) => PayoffDebt(
  id: id,
  kind: PayoffDebtKind.loan,
  name: id,
  balanceMinor: balance,
  annualRatePercent: rate,
  fixedPaymentMinor: emi,
);

PayoffDebt card(String id, int balance, double rate, {double min = 5}) =>
    PayoffDebt(
      id: id,
      kind: PayoffDebtKind.card,
      name: id,
      balanceMinor: balance,
      annualRatePercent: rate,
      minimumPercent: min,
      minimumFloorMinor: (balance * 0.01).ceil(),
    );

PayoffDebt person(String id, int balance) => PayoffDebt(
  id: id,
  kind: PayoffDebtKind.person,
  name: id,
  balanceMinor: balance,
  annualRatePercent: 0,
);

DebtPlan plan(
  List<PayoffDebt> debts, {
  PayoffStrategy strategy = PayoffStrategy.avalanche,
  int extra = 0,
}) => DebtPlan.build(
  debts,
  strategy: strategy,
  extraMinor: extra,
  start: DateTime(2026, 11, 15),
);

void main() {
  test('a zero-rate loan clears in balance / EMI months with no interest', () {
    final result = plan([loan('a', 120000, 0, 10000)]);
    expect(result.schedule.finished, isTrue);
    expect(result.schedule.monthCount, 12);
    expect(result.schedule.totalInterestMinor, 0);
    expect(result.schedule.lastMonth, DateTime(2027, 10));
  });

  test('every paisa paid equals balance plus interest', () {
    final debts = [
      loan('home', 5000000, 9, 120000),
      card('visa', 800000, 42),
      person('ravi', 300000),
    ];
    final schedule = plan(debts, extra: 150000).schedule;
    final paid = schedule.months
        .expand((m) => m.paymentsMinor.values)
        .fold(0, (sum, v) => sum + v);
    expect(schedule.finished, isTrue);
    expect(paid, 6100000 + schedule.totalInterestMinor);
    expect(schedule.months.last.closingMinor, 0);
  });

  test('avalanche targets the highest rate and snowball the smallest', () {
    final debts = [loan('small', 100000, 10, 5000), card('big', 900000, 40)];
    expect(plan(debts).order.first.id, 'big');
    expect(
      plan(debts, strategy: PayoffStrategy.snowball).order.first.id,
      'small',
    );
  });

  test('avalanche never costs more interest than snowball', () {
    final result = plan([
      loan('small', 100000, 10, 5000),
      loan('car', 600000, 11, 20000),
      card('big', 900000, 40),
    ], extra: 50000);
    expect(
      result.avalanche.totalInterestMinor,
      lessThan(result.snowball.totalInterestMinor),
    );
  });

  test('extra money goes only to the focus debt while it is open', () {
    final result = plan([
      loan('cheap', 1000000, 8, 20000),
      loan('dear', 1000000, 18, 25000),
    ], extra: 30000);
    final first = result.schedule.months.first.paymentsMinor;
    expect(first['cheap'], 20000);
    expect(first['dear'], 55000);
    expect(result.focus?.id, 'dear');
  });

  test('the budget stays constant, so a closed EMI rolls onto the next', () {
    final schedule = plan([
      loan('short', 20000, 0, 10000),
      loan('long', 1000000, 0, 10000),
    ]).schedule;
    expect(schedule.monthlyBudgetMinor, 20000);
    expect(schedule.clearedMonthIndex['short'], 1);
    expect(schedule.months[2].paymentsMinor['long'], 20000);
  });

  test('paying extra beats minimums on interest and time', () {
    final result = plan([card('visa', 1000000, 36)], extra: 100000);
    expect(result.interestSavedMinor, greaterThan(0));
    expect(result.monthsSooner, greaterThan(0));
  });

  test('with no extra, rollover alone still saves against minimums', () {
    final result = plan([
      loan('short', 100000, 12, 20000),
      loan('long', 1000000, 18, 25000),
    ]);
    expect(result.extraMinor, 0);
    expect(result.interestSavedMinor, greaterThan(0));
  });

  test('a card minimum below the interest is flagged and never clears', () {
    final result = plan([card('bad', 1000000, 48, min: 2)]);
    expect(result.underwater.single.id, 'bad');
    expect(result.schedule.finished, isFalse);
    expect(result.schedule.clearedMonthIndex, isEmpty);
    expect(result.interestSavedMinor, 0);
    expect(result.monthsSooner, 0);
  });

  test('a runaway balance stops early instead of overflowing', () {
    final result = plan([card('worst', 100000000, 100, min: 0)]);
    expect(result.schedule.finished, isFalse);
    expect(result.schedule.monthCount, lessThan(PayoffSchedule.maxMonths));
    expect(result.schedule.clearedMonthIndex, isEmpty);
    expect(result.schedule.months.last.closingMinor, greaterThan(0));
  });

  test('extra money can rescue a card whose minimum is too low', () {
    final result = plan([card('bad', 1000000, 48, min: 2)], extra: 50000);
    expect(result.schedule.finished, isTrue);
  });

  test('money borrowed from people needs extra or a freed-up EMI', () {
    expect(plan([person('ravi', 100000)]).schedule.finished, isFalse);
    expect(
      plan([person('ravi', 100000)], extra: 10000).schedule.monthCount,
      10,
    );
    final withLoan = plan([
      person('ravi', 100000),
      loan('l', 100000, 0, 50000),
    ]);
    expect(withLoan.schedule.finished, isTrue);
    expect(withLoan.schedule.clearedMonthIndex['ravi'], 3);
  });

  test('months sooner ignores debts that have no required payment', () {
    final result = plan([person('ravi', 900000), loan('l', 100000, 0, 50000)]);
    // The loan finishes in month 2 either way; Ravi only starts afterwards.
    expect(result.monthsSooner, 0);
  });

  test('roadmap lists debts in the order they clear', () {
    final result = plan([
      loan('late', 1000000, 18, 25000),
      loan('early', 20000, 8, 20000),
    ]);
    expect(result.roadmap.map((d) => d.id), ['early', 'late']);
  });

  test('what-ifs are positive, round and improve the plan', () {
    final result = plan([loan('a', 2000000, 14, 47300)]);
    final options = result.whatIfs;
    // 10%, 25% and 50% of a 473 minimum, to one significant digit.
    expect(options.map((o) => o.stepMinor), [5000, 10000, 20000]);
    for (final option in options) {
      expect(option.schedule.monthCount, lessThan(result.schedule.monthCount));
      expect(option.interestSavedMinor, greaterThan(0));
    }
  });

  test('an empty list is a finished plan with nothing to do', () {
    final result = plan(const []);
    expect(result.schedule.months, isEmpty);
    expect(result.schedule.finished, isTrue);
    expect(result.focus, isNull);
  });
}
