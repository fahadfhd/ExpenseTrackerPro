import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';

/// Compares keeping a balance at its current rate with moving it to a
/// cheaper loan, card-to-EMI plan or balance transfer over the same months.
class DebtSwitchQuote {
  const DebtSwitchQuote({
    required this.currentEmiMinor,
    required this.currentInterestMinor,
    required this.newEmiMinor,
    required this.newInterestMinor,
    required this.feeMinor,
  });

  factory DebtSwitchQuote.build({
    required int balanceMinor,
    required double currentRatePercent,
    required double newRatePercent,
    required int months,
    required double feePercent,
  }) {
    EmiQuote quote(double rate) => LoanSchedule.quote(
      principalMinor: balanceMinor,
      annualRatePercent: rate,
      installments: months,
      frequency: EmiFrequency.monthly,
    );
    final current = quote(currentRatePercent);
    final next = quote(newRatePercent);
    return DebtSwitchQuote(
      currentEmiMinor: current.emiMinor,
      currentInterestMinor: current.totalInterestMinor,
      newEmiMinor: next.emiMinor,
      newInterestMinor: next.totalInterestMinor,
      feeMinor: (balanceMinor * feePercent / 100).round(),
    );
  }

  final int currentEmiMinor;
  final int currentInterestMinor;
  final int newEmiMinor;
  final int newInterestMinor;

  /// One-off charge for switching.
  final int feeMinor;

  int get newTotalCostMinor => newInterestMinor + feeMinor;

  /// Positive when switching is cheaper after the fee.
  int get netSavingMinor => currentInterestMinor - newTotalCostMinor;

  bool get isWorthIt => netSavingMinor > 0;
}
