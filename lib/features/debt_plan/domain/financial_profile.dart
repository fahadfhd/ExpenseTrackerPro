import 'dart:math';

import 'package:kept/features/transactions/domain/monthly_summary.dart';

enum DebtLoad { healthy, watch, high }

/// What recent months say about the money available for debt.
class FinancialProfile {
  const FinancialProfile({
    required this.avgIncomeMinor,
    required this.avgSpendingMinor,
    required this.monthsUsed,
    required this.thisMonthIncomeMinor,
    required this.liquidMinor,
  });

  /// [completeMonths] excludes the current month; months with no activity are
  /// ignored so a new user's empty history does not drag the averages down.
  factory FinancialProfile.compute({
    required Iterable<MonthlySummary> completeMonths,
    required MonthlySummary thisMonth,
    required int liquidMinor,
  }) {
    final used = completeMonths
        .where((m) => m.income > 0 || m.spending > 0)
        .toList();
    int average(int Function(MonthlySummary) f) =>
        used.isEmpty ? 0 : used.fold(0, (sum, m) => sum + f(m)) ~/ used.length;
    return FinancialProfile(
      avgIncomeMinor: average((m) => m.income),
      avgSpendingMinor: average((m) => m.spending),
      monthsUsed: used.length,
      thisMonthIncomeMinor: thisMonth.income,
      liquidMinor: max(0, liquidMinor),
    );
  }

  static const emergencyMonths = 3;
  static const watchLoadAt = 0.3;
  static const highLoadAt = 0.4;

  /// Income this far above average counts as extra money, not normal noise.
  static const unusualIncomeShare = 0.2;

  final int avgIncomeMinor;
  final int avgSpendingMinor;
  final int monthsUsed;
  final int thisMonthIncomeMinor;

  /// Money in accounts, ignoring overdrawn ones.
  final int liquidMinor;

  bool get hasHistory => monthsUsed > 0;

  /// Income received this month above the usual amount, or 0.
  int get unusualIncomeMinor {
    if (avgIncomeMinor <= 0) return 0;
    final excess = thisMonthIncomeMinor - avgIncomeMinor;
    return excess >= avgIncomeMinor * unusualIncomeShare ? excess : 0;
  }

  /// Usual income left after usual spending and [minimumsMinor]. Negative
  /// means the required payments are not affordable from income.
  int headroomMinor(int minimumsMinor) =>
      avgIncomeMinor - avgSpendingMinor - minimumsMinor;

  /// Half of the headroom, leaving the rest for surprises, rounded down.
  int suggestedExtraMinor(int minimumsMinor) {
    final half = headroomMinor(minimumsMinor) ~/ 2;
    return half <= 0 ? 0 : _roundDown(half);
  }

  /// Share of usual income the required payments take; null without income.
  double? debtLoad(int minimumsMinor) =>
      avgIncomeMinor <= 0 ? null : minimumsMinor / avgIncomeMinor;

  DebtLoad? debtLoadBand(int minimumsMinor) {
    final load = debtLoad(minimumsMinor);
    if (load == null) return null;
    if (load > highLoadAt) return DebtLoad.high;
    return load >= watchLoadAt ? DebtLoad.watch : DebtLoad.healthy;
  }

  int reserveTargetMinor(int minimumsMinor) =>
      (avgSpendingMinor + minimumsMinor) * emergencyMonths;

  /// How much more is needed for a full emergency reserve. Zero without
  /// history, because the target would be a guess.
  int reserveShortfallMinor(int minimumsMinor) =>
      hasHistory ? max(0, reserveTargetMinor(minimumsMinor) - liquidMinor) : 0;

  /// Rounds down to two significant digits of the major unit.
  static int _roundDown(int minor) {
    final major = minor ~/ 100;
    if (major < 100) return major * 100;
    final unit = pow(10, major.toString().length - 2).toInt();
    return major ~/ unit * unit * 100;
  }
}
