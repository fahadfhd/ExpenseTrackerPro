import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:flutter_test/flutter_test.dart';

Loan _loan({
  int principal = 100000000, // ₹10,00,000
  double rate = 10,
  int n = 120,
  int? emi,
  DateTime? firstDue,
}) {
  final at = DateTime(2026, 1, 1);
  return Loan(
    id: 'l1',
    name: 'Home',
    principalMinor: principal,
    annualRatePercent: rate,
    installments: n,
    frequency: EmiFrequency.monthly,
    emiMinor:
        emi ??
        EmiEngine.emi(
          principalMinor: principal,
          periodicRate: EmiEngine.periodicRate(rate, EmiFrequency.monthly),
          installments: n,
        ),
    firstDueDate: firstDue ?? DateTime(2026, 1, 31),
    createdAt: at,
    updatedAt: at,
  );
}

LoanEvent _paid(int k) => LoanEvent(
  id: 'p$k',
  loanId: 'l1',
  kind: LoanEventKind.emiPaid,
  installmentNumber: k,
  date: DateTime(2026, k, 1),
  createdAt: DateTime(2026),
);

void main() {
  group('EmiEngine.emi', () {
    test('matches the standard reducing-balance formula', () {
      // ₹10L @ 10% for 10 years = ₹13,215.07
      expect(
        EmiEngine.emi(
          principalMinor: 100000000,
          periodicRate: EmiEngine.periodicRate(10, EmiFrequency.monthly),
          installments: 120,
        ),
        1321507,
      );
      // ₹1L @ 12% for 12 months = ₹8,884.88
      expect(
        EmiEngine.emi(
          principalMinor: 10000000,
          periodicRate: 0.01,
          installments: 12,
        ),
        888488,
      );
    });

    test('zero interest splits principal evenly', () {
      expect(
        EmiEngine.emi(
          principalMinor: 120000,
          periodicRate: 0,
          installments: 12,
        ),
        10000,
      );
    });

    test('rejects invalid input', () {
      expect(
        () => EmiEngine.emi(
          principalMinor: 0,
          periodicRate: .01,
          installments: 12,
        ),
        throwsArgumentError,
      );
      expect(
        () => EmiEngine.emi(
          principalMinor: 100,
          periodicRate: .01,
          installments: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => EmiEngine.emi(
          principalMinor: 100,
          periodicRate: -1,
          installments: 2,
        ),
        throwsArgumentError,
      );
    });

    test('quarterly frequency uses a quarterly periodic rate', () {
      expect(
        EmiEngine.periodicRate(12, EmiFrequency.quarterly),
        closeTo(.03, 1e-12),
      );
      expect(EmiFrequency.quarterly.monthsPerPeriod, 3);
    });
  });

  group('EmiEngine.solvePeriodicRate', () {
    test('recovers the rate used to compute an EMI', () {
      final r = EmiEngine.solvePeriodicRate(
        principalMinor: 100000000,
        emiMinor: 1321507,
        installments: 120,
      )!;
      expect(
        EmiEngine.annualPercent(r, EmiFrequency.monthly),
        closeTo(10, 0.001),
      );
    });

    test('returns 0 when payments equal principal', () {
      expect(
        EmiEngine.solvePeriodicRate(
          principalMinor: 120000,
          emiMinor: 10000,
          installments: 12,
        ),
        0,
      );
    });

    test('returns null when payments cannot repay principal', () {
      expect(
        EmiEngine.solvePeriodicRate(
          principalMinor: 120000,
          emiMinor: 9000,
          installments: 12,
        ),
        isNull,
      );
    });

    test('returns null for absurd rates above 100% per period', () {
      expect(
        EmiEngine.solvePeriodicRate(
          principalMinor: 1000,
          emiMinor: 5000,
          installments: 12,
        ),
        isNull,
      );
    });
  });

  group('LoanSchedule', () {
    test('plain schedule repays exactly the principal', () {
      final s = LoanSchedule.build(_loan(), const [], today: DateTime(2026));
      expect(s.rows, hasLength(120));
      expect(s.rows.fold<int>(0, (a, r) => a + r.principalMinor), 100000000);
      expect(s.rows.last.closingMinor, 0);
      // Total interest for ₹10L @10% / 10y is about ₹5,85,808; per-period
      // interest rounding moves it by under ₹2.
      expect(s.totalInterestMinor, closeTo(58580840, 200));
      expect(s.rows.first.interestMinor, 833333);
      expect(s.rows.first.principalMinor, 1321507 - 833333);
    });

    test('due dates keep the day of month, clamped to short months', () {
      final s = LoanSchedule.build(
        _loan(n: 3),
        const [],
        today: DateTime(2026),
      );
      expect(s.rows.map((r) => r.dueDate), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
      ]);
    });

    test('paid installments reduce outstanding and count interest paid', () {
      final s = LoanSchedule.build(_loan(), [
        _paid(1),
        _paid(2),
      ], today: DateTime(2026, 3, 1));
      expect(s.paidCount, 2);
      expect(s.remainingCount, 118);
      expect(s.outstandingPrincipalMinor, s.rows[1].closingMinor);
      expect(
        s.paidInterestMinor,
        s.rows[0].interestMinor + s.rows[1].interestMinor,
      );
      expect(
        s.paidInterestMinor + s.remainingInterestMinor,
        s.totalInterestMinor,
      );
    });

    test('unpaid past installments are overdue; skipped stays owed', () {
      final s = LoanSchedule.build(_loan(), [
        _paid(1),
        LoanEvent(
          id: 's2',
          loanId: 'l1',
          kind: LoanEventKind.skipped,
          installmentNumber: 2,
          date: DateTime(2026, 2, 28),
          createdAt: DateTime(2026),
        ),
      ], today: DateTime(2026, 4, 15));
      expect(s.rows[1].status, InstallmentStatus.skipped);
      expect(s.rows[2].status, InstallmentStatus.overdue);
      expect(s.rows[3].status, InstallmentStatus.upcoming);
      expect(s.nextDue!.number, 3);
      // Skipped principal is still outstanding.
      expect(s.outstandingPrincipalMinor, 100000000 - s.rows[0].principalMinor);
    });

    test('reduce-tenure prepayment keeps EMI and shortens the loan', () {
      final base = LoanSchedule.build(_loan(), const [], today: DateTime(2026));
      final s = LoanSchedule.build(_loan(), [
        for (var k = 1; k <= 12; k++) _paid(k),
        LoanEvent(
          id: 'pp',
          loanId: 'l1',
          kind: LoanEventKind.prepayment,
          amountMinor: 20000000,
          prepaymentMode: PrepaymentMode.reduceTenure,
          date: DateTime(2027, 1, 5),
          createdAt: DateTime(2027),
        ),
      ], today: DateTime(2027, 1, 6));
      expect(s.rows.length, lessThan(120));
      expect(s.rows[12].emiMinor, base.rows[12].emiMinor);
      expect(s.rows[12].prepaidBeforeMinor, 20000000);
      expect(s.prepaidPrincipalMinor, 20000000);
      expect(s.totalInterestMinor, lessThan(base.totalInterestMinor));
      expect(
        s.outstandingPrincipalMinor,
        base.rows[11].closingMinor - 20000000,
      );
      expect(s.rows.last.closingMinor, 0);
    });

    test('reduce-EMI prepayment keeps the installment count', () {
      final base = LoanSchedule.build(_loan(), const [], today: DateTime(2026));
      final s = LoanSchedule.build(_loan(), [
        LoanEvent(
          id: 'pp',
          loanId: 'l1',
          kind: LoanEventKind.prepayment,
          amountMinor: 20000000,
          prepaymentMode: PrepaymentMode.reduceEmi,
          date: DateTime(2026, 6, 1),
          createdAt: DateTime(2026),
        ),
      ], today: DateTime(2026));
      expect(s.rows, hasLength(120));
      expect(s.rows[5].emiMinor, lessThan(base.rows[5].emiMinor));
      expect(s.rows[4].emiMinor, base.rows[4].emiMinor);
      expect(s.rows.last.closingMinor, 0);
    });

    test('prepayment that clears the balance marks the loan prepaid', () {
      final s = LoanSchedule.build(_loan(n: 12, principal: 1200000, rate: 12), [
        _paid(1),
        LoanEvent(
          id: 'pp',
          loanId: 'l1',
          kind: LoanEventKind.prepayment,
          amountMinor: 5000000,
          prepaymentMode: PrepaymentMode.reduceTenure,
          date: DateTime(2026, 2, 1),
          createdAt: DateTime(2026),
        ),
      ], today: DateTime(2026, 2, 2));
      expect(s.rows, hasLength(1));
      expect(s.outstandingPrincipalMinor, 0);
      expect(s.unappliedPrepaymentMinor, greaterThan(0));
      expect(s.effectiveStatus, LoanStatus.prepaid);
    });

    test('all installments paid marks the loan completed', () {
      final s = LoanSchedule.build(_loan(n: 3, principal: 300000, rate: 12), [
        _paid(1),
        _paid(2),
        _paid(3),
      ], today: DateTime(2026, 6));
      expect(s.effectiveStatus, LoanStatus.completed);
      expect(s.outstandingPrincipalMinor, 0);
    });

    test('EMI below interest is flagged instead of looping', () {
      final s = LoanSchedule.build(
        _loan(emi: 100),
        const [],
        today: DateTime(2026),
      );
      expect(s.emiCoversInterest, isFalse);
      expect(s.effectiveStatus, LoanStatus.active);
    });

    test('quote totals agree with the schedule', () {
      final q = LoanSchedule.quote(
        principalMinor: 10000000,
        annualRatePercent: 12,
        installments: 12,
        frequency: EmiFrequency.monthly,
      );
      expect(q.emiMinor, 888488);
      expect(q.totalPaymentMinor, 10000000 + q.totalInterestMinor);
      expect(q.firstInterestMinor, 100000);
      expect(q.firstPrincipalMinor, 888488 - 100000);
    });
  });
}
