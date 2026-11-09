import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/features/transactions/domain/monthly_summary.dart';

const defaultBudgetThresholds = [75, 90, 100];

/// A monthly spending limit, either overall ([categoryId] null) or for one
/// category. Ids are deterministic ([idFor]) so there is at most one budget
/// per category.
class Budget {
  const Budget({
    required this.id,
    required this.amountMinor,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.thresholds = defaultBudgetThresholds,
    this.enabled = true,
  });

  static String idFor(String? categoryId) =>
      categoryId == null ? 'overall' : 'cat_$categoryId';

  final String id;
  final String? categoryId;
  final int amountMinor;

  /// Percentages at which to warn, ascending.
  final List<int> thresholds;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverall => categoryId == null;

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'amountMinor': amountMinor,
    'thresholds': thresholds,
    'enabled': enabled,
    'period': 'monthly',
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Budget.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    final thresholds = Codec.ints(
      map['thresholds'],
    ).where((t) => t > 0 && t <= 200).toList()..sort();
    return Budget(
      id: id,
      categoryId: Codec.stringOrNull(map['categoryId']),
      amountMinor: Codec.integer(map['amountMinor']),
      thresholds: thresholds.isEmpty ? defaultBudgetThresholds : thresholds,
      enabled: Codec.boolean(map['enabled'], true),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
    );
  }
}

class BudgetUsage {
  const BudgetUsage({required this.budget, required this.spentMinor});

  final Budget budget;
  final int spentMinor;

  int get remainingMinor => budget.amountMinor - spentMinor;

  double get ratio =>
      budget.amountMinor <= 0 ? 0 : spentMinor / budget.amountMinor;

  int get percent => (ratio * 100).floor();

  /// Highest configured threshold reached, or null when below all of them.
  int? get reachedThreshold {
    int? reached;
    for (final t in budget.thresholds) {
      if (percent >= t) reached = t;
    }
    return reached;
  }

  bool get isOver => spentMinor > budget.amountMinor;
}

abstract final class BudgetCalculator {
  static List<BudgetUsage> usage(
    Iterable<Budget> budgets,
    MonthlySummary summary,
  ) =>
      [
        for (final b in budgets.where((b) => b.enabled))
          BudgetUsage(
            budget: b,
            spentMinor: b.isOverall
                ? summary.spending
                : summary.byCategory[b.categoryId] ?? 0,
          ),
      ]..sort((a, b) {
        if (a.budget.isOverall != b.budget.isOverall) {
          return a.budget.isOverall ? -1 : 1;
        }
        return b.ratio.compareTo(a.ratio);
      });

  /// Threshold newly crossed when spending goes from [before] to [after]
  /// minor units, or null. Used to warn right after saving an expense.
  static int? crossedThreshold(Budget budget, int before, int after) {
    if (budget.amountMinor <= 0) return null;
    int? crossed;
    for (final t in budget.thresholds) {
      final limit = budget.amountMinor * t / 100;
      if (before < limit && after >= limit) crossed = t;
    }
    return crossed;
  }
}
