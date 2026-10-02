import 'package:expensetrackerpro/core/firebase/firestore_codec.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:expensetrackerpro/core/utils/dates.dart';

enum RecurrenceFrequency { once, daily, weekly, monthly, yearly }

/// "Every [interval] [frequency] until [until]". Shared by reminders and
/// recurring transactions so both expand dates identically.
///
/// Occurrences keep the anchor's time of day; monthly and yearly occurrences
/// keep its day of month, clamped to shorter months (31st → 30th/28th).
class Recurrence {
  const Recurrence({
    this.frequency = RecurrenceFrequency.once,
    this.interval = 1,
    this.until,
  });

  static const none = Recurrence();

  final RecurrenceFrequency frequency;

  /// Every N units; 1 = every day/week/month/year.
  final int interval;

  /// Last allowed occurrence (inclusive, by day). Null = forever.
  final DateTime? until;

  bool get repeats => frequency != RecurrenceFrequency.once;

  /// The occurrence number [k] (0-based) for [anchor].
  DateTime nth(DateTime anchor, int k) {
    final step = k * interval;
    return switch (frequency) {
      RecurrenceFrequency.once => anchor,
      RecurrenceFrequency.daily => DateTime(
        anchor.year,
        anchor.month,
        anchor.day + step,
        anchor.hour,
        anchor.minute,
      ),
      RecurrenceFrequency.weekly => DateTime(
        anchor.year,
        anchor.month,
        anchor.day + 7 * step,
        anchor.hour,
        anchor.minute,
      ),
      RecurrenceFrequency.monthly => Dates.addMonths(
        anchor,
        step,
        preferredDay: anchor.day,
      ),
      RecurrenceFrequency.yearly => Dates.addMonths(
        anchor,
        12 * step,
        preferredDay: anchor.day,
      ),
    };
  }

  /// Occurrences in `[from, to)`, in order.
  Iterable<DateTime> between(DateTime anchor, DateTime from, DateTime to) sync* {
    if (!to.isAfter(from)) return;
    final last = until == null
        ? null
        : DateTime(until!.year, until!.month, until!.day, 23, 59, 59);
    if (!repeats) {
      if (!anchor.isBefore(from) && anchor.isBefore(to)) yield anchor;
      return;
    }
    // Jump close to `from` instead of walking from the anchor.
    var k = 0;
    if (from.isAfter(anchor)) {
      final estimate = switch (frequency) {
        RecurrenceFrequency.daily => from.difference(anchor).inDays ~/ interval,
        RecurrenceFrequency.weekly =>
          from.difference(anchor).inDays ~/ (7 * interval),
        RecurrenceFrequency.monthly =>
          ((from.year - anchor.year) * 12 + from.month - anchor.month) ~/
              interval,
        RecurrenceFrequency.yearly => (from.year - anchor.year) ~/ interval,
        RecurrenceFrequency.once => 0,
      };
      k = estimate > 1 ? estimate - 1 : 0;
    }
    for (;; k++) {
      final date = nth(anchor, k);
      if (!date.isBefore(to) || (last != null && date.isAfter(last))) return;
      if (!date.isBefore(from)) yield date;
    }
  }

  /// First occurrence at or after [from], or null if the series has ended.
  DateTime? nextFrom(DateTime anchor, DateTime from) {
    final horizon = DateTime(from.year + 2 + interval, from.month, from.day);
    for (final d in between(anchor, from, horizon)) {
      return d;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
    'frequency': frequency.name,
    'interval': interval,
    'until': until == null ? null : Timestamp.fromDate(until!),
  };

  factory Recurrence.fromMap(Object? raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    return Recurrence(
      frequency: Codec.enumByName(
        RecurrenceFrequency.values,
        map['frequency'],
        RecurrenceFrequency.once,
      ),
      interval: Codec.integer(map['interval'], 1).clamp(1, 365),
      until: Codec.date(map['until']),
    );
  }

  Recurrence copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    DateTime? Function()? until,
  }) => Recurrence(
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    until: until != null ? until() : this.until,
  );
}
