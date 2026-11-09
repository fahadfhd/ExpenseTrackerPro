import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';

enum InstallmentStatus { paid, skipped, overdue, upcoming }

class AmortizationRow {
  const AmortizationRow({
    required this.number,
    required this.dueDate,
    required this.emiMinor,
    required this.principalMinor,
    required this.interestMinor,
    required this.openingMinor,
    required this.closingMinor,
    required this.status,
    this.prepaidBeforeMinor = 0,
  });

  final int number;
  final DateTime dueDate;
  final int emiMinor;
  final int principalMinor;
  final int interestMinor;

  /// Principal outstanding before this installment (after any prepayment
  /// applied just before it).
  final int openingMinor;

  /// Principal remaining after this installment.
  final int closingMinor;
  final InstallmentStatus status;

  /// Prepayment applied between the previous installment and this one.
  final int prepaidBeforeMinor;

  bool get isPaid => status == InstallmentStatus.paid;
}

/// The full repayment plan of a loan, with recorded payments, skips and
/// prepayments applied.
///
/// Rules (documented in docs/IMPLEMENTATION_NOTES.md):
/// * Interest per installment = opening principal × periodic rate, rounded to
///   the minor unit. The final installment absorbs rounding so the loan
///   closes at exactly zero.
/// * A prepayment dated before an installment's due date is applied before
///   that installment; on the due date itself it is applied after it.
/// * [PrepaymentMode.reduceTenure] keeps the EMI and ends the loan earlier;
///   [PrepaymentMode.reduceEmi] recomputes the EMI over the installments
///   left in the original contract.
/// * Marking an installment skipped does not change the plan; it stays owed.
/// * Outstanding principal = principal − principal of paid installments −
///   applied prepayments.
class LoanSchedule {
  const LoanSchedule({
    required this.loan,
    required this.rows,
    required this.prepaidPrincipalMinor,
    required this.unappliedPrepaymentMinor,
    required this.emiCoversInterest,
  });

  final Loan loan;
  final List<AmortizationRow> rows;

  /// Prepayments that reduced principal.
  final int prepaidPrincipalMinor;

  /// Prepayment amount beyond what was owed (not applied).
  final int unappliedPrepaymentMinor;

  /// False when the EMI does not even cover interest; the schedule then stops
  /// early and the UI must warn instead of showing a misleading plan.
  final bool emiCoversInterest;

  static LoanSchedule build(
    Loan loan,
    Iterable<LoanEvent> events, {
    required DateTime today,
  }) {
    final r = loan.periodicRate;
    final paid = <int>{};
    final skipped = <int>{};
    final prepayments = <LoanEvent>[];
    for (final e in events) {
      switch (e.kind) {
        case LoanEventKind.emiPaid:
          if (e.installmentNumber != null) paid.add(e.installmentNumber!);
        case LoanEventKind.skipped:
          if (e.installmentNumber != null) skipped.add(e.installmentNumber!);
        case LoanEventKind.prepayment:
          if (e.amountMinor > 0) prepayments.add(e);
      }
    }
    prepayments.sort((a, b) => a.date.compareTo(b.date));

    final rows = <AmortizationRow>[];
    final todayDay = Dates.dayOf(today);
    var balance = loan.principalMinor;
    var emi = loan.emiMinor;
    var prepaid = 0;
    var unapplied = 0;
    var nextPrepayment = 0;
    var coversInterest = true;

    for (var k = 1; k <= loan.installments && balance > 0; k++) {
      final dueDate = Dates.addMonths(
        Dates.dayOf(loan.firstDueDate),
        (k - 1) * loan.frequency.monthsPerPeriod,
        preferredDay: loan.firstDueDate.day,
      );

      var prepaidBefore = 0;
      while (nextPrepayment < prepayments.length &&
          Dates.dayOf(prepayments[nextPrepayment].date).isBefore(dueDate)) {
        final event = prepayments[nextPrepayment++];
        final applied = event.amountMinor > balance
            ? balance
            : event.amountMinor;
        unapplied += event.amountMinor - applied;
        balance -= applied;
        prepaid += applied;
        prepaidBefore += applied;
        if (balance > 0 && event.prepaymentMode == PrepaymentMode.reduceEmi) {
          emi = EmiEngine.emi(
            principalMinor: balance,
            periodicRate: r,
            installments: loan.installments - k + 1,
          );
        }
      }
      if (balance <= 0) break;

      final interest = (balance * r).round();
      var principal = emi - interest;
      if (principal <= 0 && k < loan.installments) {
        coversInterest = false;
        break;
      }
      final isLast = principal >= balance || k == loan.installments;
      if (isLast) principal = balance;
      final opening = balance;
      balance -= principal;

      rows.add(
        AmortizationRow(
          number: k,
          dueDate: dueDate,
          emiMinor: principal + interest,
          principalMinor: principal,
          interestMinor: interest,
          openingMinor: opening,
          closingMinor: balance,
          prepaidBeforeMinor: prepaidBefore,
          status: paid.contains(k)
              ? InstallmentStatus.paid
              : skipped.contains(k)
              ? InstallmentStatus.skipped
              : dueDate.isBefore(todayDay)
              ? InstallmentStatus.overdue
              : InstallmentStatus.upcoming,
        ),
      );
    }

    // Prepayments recorded after the final installment have nothing left
    // to reduce.
    for (; nextPrepayment < prepayments.length; nextPrepayment++) {
      unapplied += prepayments[nextPrepayment].amountMinor;
    }

    return LoanSchedule(
      loan: loan,
      rows: List.unmodifiable(rows),
      prepaidPrincipalMinor: prepaid,
      unappliedPrepaymentMinor: unapplied,
      emiCoversInterest: coversInterest,
    );
  }

  int _sum(Iterable<AmortizationRow> rows, int Function(AmortizationRow) f) =>
      rows.fold(0, (s, row) => s + f(row));

  Iterable<AmortizationRow> get _paidRows => rows.where((r) => r.isPaid);

  Iterable<AmortizationRow> get _unpaidRows => rows.where((r) => !r.isPaid);

  int get totalInterestMinor => _sum(rows, (r) => r.interestMinor);

  int get totalPaymentMinor =>
      _sum(rows, (r) => r.emiMinor) + prepaidPrincipalMinor;

  int get paidInterestMinor => _sum(_paidRows, (r) => r.interestMinor);

  int get paidPrincipalMinor => _sum(_paidRows, (r) => r.principalMinor);

  int get remainingInterestMinor => _sum(_unpaidRows, (r) => r.interestMinor);

  int get outstandingPrincipalMinor {
    final value =
        loan.principalMinor - paidPrincipalMinor - prepaidPrincipalMinor;
    return value < 0 ? 0 : value;
  }

  int get paidCount => _paidRows.length;

  int get remainingCount => _unpaidRows.length;

  int get overdueCount =>
      rows.where((r) => r.status == InstallmentStatus.overdue).length;

  /// First installment that is neither paid nor skipped.
  AmortizationRow? get nextDue {
    for (final row in rows) {
      if (row.status == InstallmentStatus.overdue ||
          row.status == InstallmentStatus.upcoming) {
        return row;
      }
    }
    return null;
  }

  /// EMI currently being charged (changes after a reduce-EMI prepayment).
  int get currentEmiMinor => nextDue?.emiMinor ?? loan.emiMinor;

  double get paidRatio => loan.principalMinor == 0
      ? 0
      : 1 - outstandingPrincipalMinor / loan.principalMinor;

  LoanStatus get effectiveStatus {
    if (loan.status == LoanStatus.closed) return LoanStatus.closed;
    if (emiCoversInterest && rows.every((r) => r.isPaid)) {
      return prepaidPrincipalMinor > 0 && rows.length < loan.installments
          ? LoanStatus.prepaid
          : LoanStatus.completed;
    }
    return LoanStatus.active;
  }

  /// Contract-only figures (no events) for quotes and comparisons.
  static EmiQuote quote({
    required int principalMinor,
    required double annualRatePercent,
    required int installments,
    required EmiFrequency frequency,
  }) {
    final emi = EmiEngine.emi(
      principalMinor: principalMinor,
      periodicRate: EmiEngine.periodicRate(annualRatePercent, frequency),
      installments: installments,
    );
    final now = DateTime.now();
    final schedule = build(
      Loan(
        id: '_quote',
        name: '',
        principalMinor: principalMinor,
        annualRatePercent: annualRatePercent,
        installments: installments,
        frequency: frequency,
        emiMinor: emi,
        firstDueDate: now,
        createdAt: now,
        updatedAt: now,
      ),
      const [],
      today: now,
    );
    final first = schedule.rows.isEmpty ? null : schedule.rows.first;
    return EmiQuote(
      emiMinor: emi,
      principalMinor: principalMinor,
      totalInterestMinor: schedule.totalInterestMinor,
      totalPaymentMinor: schedule.totalPaymentMinor,
      firstInterestMinor: first?.interestMinor ?? 0,
      firstPrincipalMinor: first?.principalMinor ?? 0,
    );
  }
}
