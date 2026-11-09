import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/loans/application/loan_providers.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UpcomingKind { card, loan, borrowed, lent, reminder }

class UpcomingItem {
  const UpcomingItem({
    required this.kind,
    required this.entityId,
    required this.title,
    required this.date,
    this.amountMinor,
  });

  final UpcomingKind kind;
  final String entityId;
  final String title;
  final DateTime date;
  final int? amountMinor;

  bool isOverdue(DateTime now) => Dates.dayOf(date).isBefore(Dates.dayOf(now));
}

/// Days ahead that dues and reminders appear on the dashboard.
const upcomingWindowDays = 30;
const upcomingReminderDays = 7;

/// Everything due soon or overdue across modules, soonest first.
final upcomingProvider = Provider.autoDispose<List<UpcomingItem>>((ref) {
  final now = DateTime.now();
  final horizon = Dates.dayOf(
    now,
  ).add(const Duration(days: upcomingWindowDays));
  final items = <UpcomingItem>[];

  final cards = ref.watch(cardsByIdProvider);
  ref.watch(cardStatusesProvider).forEach((id, status) {
    if (status.totalDueMinor <= 0 || status.dueDate.isAfter(horizon)) return;
    items.add(
      UpcomingItem(
        kind: UpcomingKind.card,
        entityId: id,
        title: cards[id]?.displayName ?? '',
        date: status.dueDate,
        amountMinor: status.totalDueMinor,
      ),
    );
  });

  final schedules = ref.watch(loanSchedulesProvider).value ?? const {};
  for (final s in schedules.values) {
    final next = s.nextDue;
    if (s.effectiveStatus != LoanStatus.active || next == null) continue;
    if (next.dueDate.isAfter(horizon)) continue;
    items.add(
      UpcomingItem(
        kind: UpcomingKind.loan,
        entityId: s.loan.id,
        title: s.loan.name,
        date: next.dueDate,
        amountMinor: next.emiMinor,
      ),
    );
  }

  for (final d in ref.watch(debtsProvider).value ?? const <DebtRecord>[]) {
    if (d.isSettled || d.dueDate == null || d.dueDate!.isAfter(horizon)) {
      continue;
    }
    items.add(
      UpcomingItem(
        kind: d.direction == DebtDirection.borrowed
            ? UpcomingKind.borrowed
            : UpcomingKind.lent,
        entityId: d.id,
        title: d.personName,
        date: d.dueDate!,
        amountMinor: d.outstandingMinor,
      ),
    );
  }

  final reminderHorizon = now.add(const Duration(days: upcomingReminderDays));
  for (final r in ref.watch(remindersProvider).value ?? const []) {
    // Entity reminders are already represented by their entity above.
    if (!r.enabled || r.isEntityReminder) continue;
    final next = r.nextOccurrence(now);
    if (next == null || next.isAfter(reminderHorizon)) continue;
    items.add(
      UpcomingItem(
        kind: UpcomingKind.reminder,
        entityId: r.id,
        title: r.title,
        date: next,
      ),
    );
  }

  items.sort((a, b) => a.date.compareTo(b.date));
  return items;
});

/// Money still to be paid this month: unpaid card dues and EMIs falling in
/// [month], plus amounts owed to others that are due in it.
final pendingPaymentsProvider = Provider.autoDispose.family<int, DateTime>((
  ref,
  month,
) {
  final range = DateRange.month(month);
  var total = 0;
  for (final status in ref.watch(cardStatusesProvider).values) {
    if (range.contains(status.dueDate)) total += status.totalDueMinor;
  }
  final schedules = ref.watch(loanSchedulesProvider).value ?? const {};
  for (final s in schedules.values) {
    for (final row in s.rows) {
      if (!row.isPaid && range.contains(row.dueDate)) total += row.emiMinor;
    }
  }
  for (final d in ref.watch(debtsProvider).value ?? const <DebtRecord>[]) {
    if (d.direction == DebtDirection.borrowed &&
        d.dueDate != null &&
        range.contains(d.dueDate!)) {
      total += d.outstandingMinor;
    }
  }
  return total;
});
