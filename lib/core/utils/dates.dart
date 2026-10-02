/// Calendar helpers. All functions work on local wall-clock dates.
abstract final class Dates {
  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

  static DateTime nextMonth(DateTime month) =>
      DateTime(month.year, month.month + 1);

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Adds [months] keeping the day of month, clamped to the target month's
  /// length (Jan 31 + 1 month = Feb 28/29).
  static DateTime addMonths(DateTime d, int months, {int? preferredDay}) {
    final target = DateTime(d.year, d.month + months);
    final day = (preferredDay ?? d.day).clamp(
      1,
      daysInMonth(target.year, target.month),
    );
    return DateTime(
      target.year,
      target.month,
      day,
      d.hour,
      d.minute,
      d.second,
    );
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// `yyyyMMdd`, used in deterministic document ids.
  static String compactKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Half-open date range `[start, end)`.
class DateRange {
  const DateRange(this.start, this.end);

  factory DateRange.month(DateTime month) {
    final start = Dates.monthOf(month);
    return DateRange(start, Dates.nextMonth(start));
  }

  /// The [count] months ending with (and including) [lastMonth].
  factory DateRange.lastMonths(DateTime lastMonth, int count) {
    final end = Dates.nextMonth(Dates.monthOf(lastMonth));
    return DateRange(DateTime(end.year, end.month - count), end);
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
