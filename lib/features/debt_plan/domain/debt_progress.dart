import 'dart:math';

import 'package:kept/core/firebase/firestore_codec.dart';

/// Debt at one month: the total and the debts still open (id to name).
class DebtSnapshot {
  const DebtSnapshot({
    required this.monthKey,
    required this.totalMinor,
    required this.debts,
  });

  factory DebtSnapshot.fromMap(String key, Map<String, dynamic> map) =>
      DebtSnapshot(
        monthKey: key,
        totalMinor: Codec.integer(map['totalMinor']),
        debts: {
          for (final e in (map['debts'] as Map? ?? const {}).entries)
            '${e.key}': '${e.value}',
        },
      );

  /// `yyyy-MM`, which also sorts chronologically.
  final String monthKey;
  final int totalMinor;
  final Map<String, String> debts;

  DateTime get month {
    final parts = monthKey.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  Map<String, dynamic> toMap() => {'totalMinor': totalMinor, 'debts': debts};

  bool matches(int total, Map<String, String> open) =>
      total == totalMinor &&
      open.length == debts.length &&
      open.entries.every((e) => debts[e.key] == e.value);
}

/// Month-by-month debt history, one snapshot per month.
class DebtProgress {
  DebtProgress(Iterable<DebtSnapshot> snapshots)
    : snapshots = snapshots.toList()
        ..sort((a, b) => a.monthKey.compareTo(b.monthKey));

  factory DebtProgress.fromMap(Map<String, dynamic>? map) => DebtProgress([
    for (final e in (map?['months'] as Map? ?? const {}).entries)
      if (e.value is Map && _keyPattern.hasMatch('${e.key}'))
        DebtSnapshot.fromMap(
          '${e.key}',
          Map<String, dynamic>.from(e.value as Map),
        ),
  ]);

  static final _keyPattern = RegExp(r'^\d{4}-\d{2}$');
  static const maxMonths = 120;

  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  final List<DebtSnapshot> snapshots;

  bool get isEmpty => snapshots.isEmpty;

  Map<String, dynamic> toMap() => {
    'months': {for (final s in snapshots) s.monthKey: s.toMap()},
  };

  /// True when this month's snapshot needs writing. Someone who has never
  /// had debt gets no history.
  bool needsUpdate(DateTime now, int total, Map<String, String> open) {
    if (isEmpty && total == 0) return false;
    final key = keyFor(now);
    for (final s in snapshots) {
      if (s.monthKey == key) return !s.matches(total, open);
    }
    return true;
  }

  /// A copy with this month's figures replaced, oldest months dropped.
  DebtProgress recorded(DateTime now, int total, Map<String, String> open) {
    final key = keyFor(now);
    final next = [
      ...snapshots.where((s) => s.monthKey != key),
      DebtSnapshot(monthKey: key, totalMinor: total, debts: open),
    ]..sort((a, b) => a.monthKey.compareTo(b.monthKey));
    return DebtProgress(next.skip(max(0, next.length - maxMonths)));
  }

  /// The most ever owed, which progress is measured against.
  int get peakMinor => snapshots.fold(0, (p, s) => max(p, s.totalMinor));

  int paidDownMinor(int currentTotal) => max(0, peakMinor - currentTotal);

  double paidRatio(int currentTotal) =>
      peakMinor <= 0 ? 0 : paidDownMinor(currentTotal) / peakMinor;

  /// Names of debts seen earlier that are no longer open.
  List<String> clearedNames(Set<String> openIds) {
    final names = <String, String>{};
    for (final s in snapshots) {
      names.addAll(s.debts);
    }
    names.removeWhere((id, _) => openIds.contains(id));
    return names.values.toList();
  }

  /// Debts open at the end of last recorded month but closed in [now]'s.
  List<String> clearedThisMonth(DateTime now, Set<String> openIds) {
    final key = keyFor(now);
    final earlier = snapshots.where((s) => s.monthKey.compareTo(key) < 0);
    if (earlier.isEmpty) return const [];
    return [
      for (final e in earlier.last.debts.entries)
        if (!openIds.contains(e.key)) e.value,
    ];
  }
}
