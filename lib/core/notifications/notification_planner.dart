import 'package:kept/core/utils/stable_hash.dart';
import 'package:kept/features/reminders/domain/reminder.dart';

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.reminderId,
    required this.fireAt,
    required this.occurrence,
    required this.offsetMinutes,
    required this.title,
    required this.body,
  });

  /// Deterministic: the same reminder, offset and occurrence always map to
  /// the same id, so rescheduling replaces instead of duplicating.
  final int id;
  final String reminderId;

  /// Local wall-clock time to show the notification.
  final DateTime fireAt;

  /// The occurrence this notification announces.
  final DateTime occurrence;
  final int offsetMinutes;
  final String title;
  final String body;

  /// Stored with the OS notification; lets the reconciler detect content
  /// changes without cancelling everything.
  String get payload =>
      '$reminderId|${fireAt.toIso8601String()}|${stableHash31(title)}|${stableHash31(body)}';

  static int idFor(String reminderId, int offsetMinutes, DateTime occurrence) =>
      stableHash31(
        '$reminderId|$offsetMinutes|${occurrence.toIso8601String()}',
      );
}

/// Turns reminders into the concrete notifications that should be pending on
/// the device right now.
///
/// Recurring reminders are expanded over a rolling [horizon] rather than
/// registered as OS-level repeats, because OS repeats cannot express
/// "7 days before the 31st of every month". The app re-plans on every launch,
/// resume and reminder change, which keeps the window filled.
///
/// The result is capped at [maxPending] (iOS allows 64 pending per app). So
/// that a frequent reminder (a daily gym alert) can never crowd out a rare,
/// important one (an EMI next month), every reminder's *next* occurrence is
/// reserved first — looking up to [nextOccurrenceHorizon] ahead — and only
/// the remaining slots are filled with later occurrences, soonest first.
abstract final class NotificationPlanner {
  static const horizon = Duration(days: 60);
  static const nextOccurrenceHorizon = Duration(days: 366);
  static const maxPending = 60;

  static List<PlannedNotification> plan(
    Iterable<Reminder> reminders, {
    required DateTime now,
    required String Function(Reminder reminder, int offsetMinutes) bodyFor,
    Duration window = horizon,
    int limit = maxPending,
  }) {
    final windowEnd = now.add(window);
    final reserved = <PlannedNotification>[];
    final rest = <PlannedNotification>[];

    for (final reminder in reminders) {
      if (!reminder.enabled) continue;
      final offsets = reminder.offsetsMinutes.isEmpty
          ? const [0]
          : reminder.offsetsMinutes;
      final maxOffset = offsets.reduce((a, b) => a > b ? a : b);
      final searchEnd = now
          .add(window > nextOccurrenceHorizon ? window : nextOccurrenceHorizon)
          .add(Duration(minutes: maxOffset));
      var haveNext = false;
      for (final occurrence in reminder.recurrence.between(
        reminder.anchor,
        now,
        searchEnd,
      )) {
        final upcoming = [
          for (final offset in offsets)
            if (occurrence.subtract(Duration(minutes: offset)).isAfter(now))
              PlannedNotification(
                id: PlannedNotification.idFor(reminder.id, offset, occurrence),
                reminderId: reminder.id,
                fireAt: occurrence.subtract(Duration(minutes: offset)),
                occurrence: occurrence,
                offsetMinutes: offset,
                title: reminder.title,
                body: bodyFor(reminder, offset),
              ),
        ];
        if (upcoming.isEmpty) continue;
        if (!haveNext) {
          reserved.addAll(upcoming);
          haveNext = true;
          continue;
        }
        final inWindow = upcoming.where((p) => !p.fireAt.isAfter(windowEnd));
        if (inWindow.isEmpty) break;
        rest.addAll(inWindow);
      }
    }

    int byTime(PlannedNotification a, PlannedNotification b) =>
        a.fireAt.compareTo(b.fireAt);
    reserved.sort(byTime);
    rest.sort(byTime);
    final seen = <int>{};
    final chosen = <PlannedNotification>[
      for (final p in [...reserved, ...rest])
        if (seen.add(p.id)) p,
    ].take(limit).toList()..sort(byTime);
    return chosen;
  }
}
