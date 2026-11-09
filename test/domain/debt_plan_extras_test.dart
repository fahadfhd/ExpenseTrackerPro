import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/debt_plan/domain/debt_progress.dart';
import 'package:kept/features/debt_plan/domain/debt_switch.dart';
import 'package:kept/features/debt_plan/domain/financial_profile.dart';
import 'package:kept/features/debt_plan/domain/lump_sum.dart';
import 'package:kept/features/transactions/domain/monthly_summary.dart';

PayoffDebt loan(String id, int balance, double rate, int emi) => PayoffDebt(
  id: id,
  kind: PayoffDebtKind.loan,
  name: id,
  balanceMinor: balance,
  annualRatePercent: rate,
  fixedPaymentMinor: emi,
);

DebtPlan plan(List<PayoffDebt> debts) => DebtPlan.build(
  debts,
  strategy: PayoffStrategy.avalanche,
  extraMinor: 0,
  start: DateTime(2026, 11, 15),
);

MonthlySummary month(int income, int spending) => MonthlySummary(
  income: income,
  spending: spending,
  emi: 0,
  cardSpending: 0,
  borrowed: 0,
  lent: 0,
  pending: 0,
  byCategory: const {},
  byDay: const {},
  byAccount: const {},
  byCard: const {},
  transactionCount: 1,
);

FinancialProfile profile({
  List<int> incomes = const [5000000, 5000000, 5000000],
  int spending = 2000000,
  int thisMonth = 5000000,
  int liquid = 0,
}) => FinancialProfile.compute(
  completeMonths: [for (final i in incomes) month(i, spending)],
  thisMonth: month(thisMonth, 0),
  liquidMinor: liquid,
);

void main() {
  group('extra money', () {
    final debts = [
      loan('cheap', 1000000, 8, 30000),
      loan('dear', 300000, 18, 20000),
    ];

    test('goes to the dearest debt first and closes it', () {
      final advice = LumpSumAdvice.build(plan(debts), 400000);
      expect(advice.allocations.map((a) => a.debt.id), ['dear', 'cheap']);
      expect(advice.allocations.first.amountMinor, 300000);
      expect(advice.allocations.first.closes, isTrue);
      expect(advice.allocations.last.amountMinor, 100000);
      expect(advice.allocations.last.closes, isFalse);
      expect(advice.freedMonthlyMinor, 20000);
    });

    test('saves interest and time at the same monthly budget', () {
      final base = plan(debts);
      final advice = LumpSumAdvice.build(base, 400000);
      expect(advice.after.monthlyBudgetMinor, base.schedule.monthlyBudgetMinor);
      expect(advice.interestSavedMinor, greaterThan(0));
      expect(advice.monthsSooner, greaterThan(0));
    });

    test('every rupee is accounted for', () {
      final advice = LumpSumAdvice.build(
        plan(debts),
        2000000,
        reserveShortfallMinor: 100000,
      );
      final paid = advice.allocations.fold(0, (s, a) => s + a.amountMinor);
      expect(paid + advice.keepMinor + advice.leftoverMinor, 2000000);
    });

    test('keeps up to a quarter when savings are short', () {
      final base = plan(debts);
      expect(
        LumpSumAdvice.build(
          base,
          400000,
          reserveShortfallMinor: 9000000,
        ).keepMinor,
        100000,
      );
      expect(
        LumpSumAdvice.build(
          base,
          400000,
          reserveShortfallMinor: 50000,
        ).keepMinor,
        50000,
      );
      expect(LumpSumAdvice.build(base, 400000).keepMinor, 0);
    });

    test('enough money clears everything and leaves the rest', () {
      final advice = LumpSumAdvice.build(plan(debts), 1500000);
      expect(advice.clearsEverything, isTrue);
      expect(advice.leftoverMinor, 200000);
      expect(advice.closableInstead, isNull);
    });

    test('offers closing a whole EMI when the top pick stays open', () {
      final advice = LumpSumAdvice.build(
        plan([
          loan('big', 5000000, 18, 100000),
          loan('small', 200000, 9, 40000),
        ]),
        300000,
      );
      expect(advice.allocations.single.debt.id, 'big');
      expect(advice.closableInstead?.id, 'small');
    });
  });

  group('income signals', () {
    test('a bonus month is noticed, normal variation is not', () {
      expect(profile(thisMonth: 8000000).unusualIncomeMinor, 3000000);
      expect(profile(thisMonth: 5500000).unusualIncomeMinor, 0);
      expect(profile(thisMonth: 3000000).unusualIncomeMinor, 0);
    });

    test('no history means no bonus detection', () {
      expect(
        profile(incomes: const [], thisMonth: 9000000).unusualIncomeMinor,
        0,
      );
    });

    test('empty months do not drag the average down', () {
      final result = FinancialProfile.compute(
        completeMonths: [MonthlySummary.empty, month(6000000, 1000000)],
        thisMonth: MonthlySummary.empty,
        liquidMinor: 0,
      );
      expect(result.avgIncomeMinor, 6000000);
      expect(result.monthsUsed, 1);
    });

    test('suggests half the headroom, rounded down', () {
      // 50,000 - 20,000 - 12,345 = 17,655; half is 8,827.
      expect(profile().suggestedExtraMinor(1234500), 880000);
      expect(profile().suggestedExtraMinor(3500000), 0);
      expect(profile().headroomMinor(3500000), -500000);
    });

    test('debt load bands', () {
      expect(profile().debtLoadBand(1000000), DebtLoad.healthy);
      expect(profile().debtLoadBand(1500000), DebtLoad.watch);
      expect(profile().debtLoadBand(2000000), DebtLoad.watch);
      expect(profile().debtLoadBand(2000100), DebtLoad.high);
      expect(profile(incomes: const []).debtLoad(1000000), isNull);
    });

    test('emergency shortfall is three months of outgoings', () {
      expect(profile(liquid: 1000000).reserveShortfallMinor(1000000), 8000000);
      expect(profile(liquid: 9999999).reserveShortfallMinor(1000000), 0);
      expect(profile(incomes: const []).reserveShortfallMinor(1000000), 0);
    });
  });

  group('progress history', () {
    final oct = DateTime(2026, 10, 5);
    final nov = DateTime(2026, 11, 5);

    test('someone with no debt and no history records nothing', () {
      expect(DebtProgress(const []).needsUpdate(nov, 0, const {}), isFalse);
    });

    test('tracks the peak, what is paid and what closed', () {
      final progress = DebtProgress(const [])
          .recorded(oct, 1000000, const {'a': 'Car', 'b': 'Card'})
          .recorded(nov, 600000, const {'a': 'Car'});
      expect(progress.peakMinor, 1000000);
      expect(progress.paidDownMinor(600000), 400000);
      expect(progress.paidRatio(600000), closeTo(0.4, 0.001));
      expect(progress.clearedNames({'a'}), ['Card']);
      expect(progress.clearedThisMonth(nov, {'a'}), ['Card']);
    });

    test('rewrites only when the month changed', () {
      final progress = DebtProgress(
        const [],
      ).recorded(nov, 100, const {'a': 'Car'});
      expect(progress.needsUpdate(nov, 100, const {'a': 'Car'}), isFalse);
      expect(progress.needsUpdate(nov, 90, const {'a': 'Car'}), isTrue);
      expect(
        progress.needsUpdate(DateTime(2026, 12), 100, const {'a': 'Car'}),
        isTrue,
      );
      expect(progress.recorded(nov, 90, const {}).snapshots, hasLength(1));
    });

    test('survives a round trip through storage', () {
      final progress = DebtProgress(
        const [],
      ).recorded(nov, 100, const {'a': 'Car'});
      final copy = DebtProgress.fromMap(progress.toMap());
      expect(copy.snapshots.single.month, DateTime(2026, 11));
      expect(copy.snapshots.single.debts, {'a': 'Car'});
      expect(DebtProgress.fromMap(null).isEmpty, isTrue);
    });
  });

  group('switching to a cheaper loan', () {
    DebtSwitchQuote quote(double fee) => DebtSwitchQuote.build(
      balanceMinor: 10000000,
      currentRatePercent: 42,
      newRatePercent: 16,
      months: 12,
      feePercent: fee,
    );

    test('a normal fee is worth paying to escape card interest', () {
      expect(quote(2).feeMinor, 200000);
      expect(quote(2).isWorthIt, isTrue);
      expect(
        quote(2).netSavingMinor,
        quote(2).currentInterestMinor - quote(2).newInterestMinor - 200000,
      );
    });

    test('a large fee can cancel the saving', () {
      expect(quote(30).isWorthIt, isFalse);
    });
  });
}
