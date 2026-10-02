import 'dart:math';

enum EmiFrequency {
  monthly(12),
  quarterly(4),
  halfYearly(2),
  yearly(1);

  const EmiFrequency(this.periodsPerYear);

  final int periodsPerYear;

  int get monthsPerPeriod => 12 ~/ periodsPerYear;
}

/// Reducing-balance EMI maths. Amounts are minor units; rates are annual
/// percentages (e.g. `10.5` for 10.5% p.a.) converted to a periodic rate of
/// `annual / 100 / periodsPerYear`.
abstract final class EmiEngine {
  static double periodicRate(double annualRatePercent, EmiFrequency f) =>
      annualRatePercent / 100 / f.periodsPerYear;

  /// EMI = P·r·(1+r)^n / ((1+r)^n − 1), or P/n when r = 0.
  ///
  /// Rounded to the nearest minor unit. Throws [ArgumentError] for
  /// non-positive principal or installment count, or a negative rate.
  static int emi({
    required int principalMinor,
    required double periodicRate,
    required int installments,
  }) {
    if (principalMinor <= 0) {
      throw ArgumentError.value(principalMinor, 'principalMinor');
    }
    if (installments <= 0) {
      throw ArgumentError.value(installments, 'installments');
    }
    if (periodicRate < 0 || periodicRate.isNaN) {
      throw ArgumentError.value(periodicRate, 'periodicRate');
    }
    return _rawEmi(
      principalMinor.toDouble(),
      periodicRate,
      installments,
    ).round();
  }

  static double _rawEmi(double p, double r, int n) {
    if (r == 0) return p / n;
    final growth = pow(1 + r, n).toDouble();
    return p * r * growth / (growth - 1);
  }

  /// Solves for the periodic interest rate that makes [installments] payments
  /// of [emiMinor] repay [principalMinor], using bisection on the EMI
  /// formula (which is strictly increasing in the rate).
  ///
  /// Returns 0 when the payments total exactly the principal, and null when
  /// no non-negative rate fits (payments total less than the principal) or
  /// the implied rate exceeds 100% per period.
  static double? solvePeriodicRate({
    required int principalMinor,
    required int emiMinor,
    required int installments,
  }) {
    if (principalMinor <= 0 || emiMinor <= 0 || installments <= 0) {
      return null;
    }
    final p = principalMinor.toDouble();
    final target = emiMinor.toDouble();
    // Half a minor unit tolerance absorbs EMI rounding.
    if ((target * installments - p).abs() < installments * 0.5) return 0;
    if (target * installments < p) return null;

    var low = 0.0;
    var high = 1.0;
    if (_rawEmi(p, high, installments) < target) return null;
    for (var i = 0; i < 200; i++) {
      final mid = (low + high) / 2;
      if (_rawEmi(p, mid, installments) < target) {
        low = mid;
      } else {
        high = mid;
      }
      if (high - low < 1e-12) break;
    }
    return (low + high) / 2;
  }

  /// Annual percentage for a periodic rate.
  static double annualPercent(double periodicRate, EmiFrequency f) =>
      periodicRate * f.periodsPerYear * 100;
}

/// One-off calculator result for the EMI calculator screen.
class EmiQuote {
  const EmiQuote({
    required this.emiMinor,
    required this.totalPaymentMinor,
    required this.totalInterestMinor,
    required this.principalMinor,
    required this.firstInterestMinor,
    required this.firstPrincipalMinor,
  });

  final int emiMinor;
  final int totalPaymentMinor;
  final int totalInterestMinor;
  final int principalMinor;

  /// Interest and principal portions of the first installment.
  final int firstInterestMinor;
  final int firstPrincipalMinor;

  /// Total interest as a share of principal.
  double get interestRatio =>
      principalMinor == 0 ? 0 : totalInterestMinor / principalMinor;
}
