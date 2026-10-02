import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/core/utils/recurrence.dart';
import 'package:expensetrackerpro/features/loans/application/loan_providers.dart';
import 'package:expensetrackerpro/features/loans/domain/amortization.dart';
import 'package:expensetrackerpro/features/loans/domain/loan.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/reminders/domain/reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _type = ReminderEntityType.loan;

/// The EMI reminder a loan should have right now, or null for none.
///
/// Derived from the live schedule rather than the loan's contract, so the
/// reminder stops once the loan is completed, prepaid or closed, and starts
/// at the next *unpaid* installment (EMIs paid ahead don't trigger it). The
/// user's own choices on an existing reminder (time, alerts, on/off) are
/// kept.
Reminder? desiredLoanReminder(
  LoanSchedule schedule,
  Reminder? existing,
  AppLocalizations l10n,
  DateTime now,
) {
  final loan = schedule.loan;
  final next = schedule.nextDue;
  if (!loan.reminderEnabled ||
      schedule.effectiveStatus != LoanStatus.active ||
      next == null) {
    return null;
  }
  // A due date clamped to a short month (31 → 28) would shift every later
  // occurrence; fall back to the first due date, whose day is exact. Past
  // occurrences are ignored by the planner anyway.
  final anchor = next.dueDate.day == loan.firstDueDate.day
      ? next.dueDate
      : Dates.dayOf(loan.firstDueDate);
  final fresh = Reminder(
    id: Reminder.entityReminderId(_type, loan.id),
    title: l10n.reminderLoanTitle(loan.name),
    type: ReminderType.loanEmi,
    date: anchor,
    hour: existing?.hour ?? 9,
    minute: existing?.minute ?? 0,
    recurrence: Recurrence(
      frequency: RecurrenceFrequency.monthly,
      interval: loan.frequency.monthsPerPeriod,
      until: schedule.rows.last.dueDate,
    ),
    entityType: _type,
    entityId: loan.id,
    offsetsMinutes: existing?.offsetsMinutes ?? const [3 * 1440, 0],
    enabled: existing?.enabled ?? true,
    createdAt: existing?.createdAt ?? now,
    updatedAt: now,
  );
  return fresh;
}

bool _sameSchedule(Reminder a, Reminder b) =>
    a.title == b.title &&
    Dates.sameDay(a.date, b.date) &&
    a.recurrence.frequency == b.recurrence.frequency &&
    a.recurrence.interval == b.recurrence.interval &&
    (a.recurrence.until == null) == (b.recurrence.until == null) &&
    (a.recurrence.until == null ||
        Dates.sameDay(a.recurrence.until!, b.recurrence.until!));

/// Keeps every loan's EMI reminder matching its schedule: created, moved to
/// the next unpaid EMI, or removed (completed, prepaid, closed, deleted,
/// reminders turned off). Writes only when something changed.
class LoanReminderSync {
  LoanReminderSync(this._ref) {
    _ref.listen(loanSchedulesProvider, (_, _) => _run(), fireImmediately: true);
    _ref.listen(remindersProvider, (_, _) => _run(), fireImmediately: true);
  }

  final Ref _ref;

  void _run() {
    final schedules = _ref.read(loanSchedulesProvider).value;
    final reminders = _ref.read(remindersProvider).value;
    // Both must be loaded, or existing user choices could be overwritten
    // and live reminders mistaken for orphans.
    if (schedules == null || reminders == null) return;
    final repo = _ref.read(reminderRepositoryProvider);
    final l10n = _ref.read(l10nProvider);
    final now = DateTime.now();
    final existing = {
      for (final r in reminders)
        if (r.entityType == _type && r.entityId != null) r.entityId!: r,
    };
    for (final schedule in schedules.values) {
      final current = existing.remove(schedule.loan.id);
      final desired = desiredLoanReminder(schedule, current, l10n, now);
      if (desired == null) {
        if (current != null) {
          repo.syncEntityReminder(_type, schedule.loan.id, null);
        }
      } else if (current == null || !_sameSchedule(current, desired)) {
        repo.syncEntityReminder(_type, schedule.loan.id, desired);
      }
    }
    // Reminders whose loan no longer exists.
    for (final orphan in existing.keys) {
      repo.syncEntityReminder(_type, orphan, null);
    }
  }
}

final loanReminderSyncProvider = Provider<LoanReminderSync>(
  LoanReminderSync.new,
);
