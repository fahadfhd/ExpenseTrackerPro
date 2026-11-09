import 'dart:async';

import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/debt_plan/application/debt_plan_providers.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const debtPlanReminderId = 'debt_plan_monthly';

/// Keeps the monthly debt history and the optional plan reminder current,
/// whichever screen is showing. Writes only when something changed.
class DebtPlanSync {
  DebtPlanSync(this._ref) {
    _ref.listen(payoffDebtsProvider, (_, _) => _run(), fireImmediately: true);
    _ref.listen(debtProgressProvider, (_, _) => _run(), fireImmediately: true);
    _ref.listen(debtPlanProvider, (_, _) => _run(), fireImmediately: true);
    _ref.listen(remindersProvider, (_, _) => _run(), fireImmediately: true);
    _ref.listen(debtPlanSettingsProvider, (_, _) => _run());
    // The reminder title is stored text, so it follows the language. Deferred
    // because the change can arrive while widgets are building.
    _ref.listen(appLocaleProvider, (_, _) {
      _languageChange?.cancel();
      _languageChange = Timer(Duration.zero, _run);
    });
    _ref.onDispose(() => _languageChange?.cancel());
  }

  final Ref _ref;
  Timer? _languageChange;

  void _run() {
    _recordProgress();
    _syncReminder();
  }

  void _recordProgress() {
    final debts = _ref.read(payoffDebtsProvider).value;
    final progress = _ref.read(debtProgressProvider).value;
    // Both must be loaded, or a partial picture would overwrite the history.
    if (debts == null || progress == null) return;
    final now = _ref.read(clockProvider)();
    final total = debts.fold(0, (sum, d) => sum + d.balanceMinor);
    final open = {for (final d in debts) d.id: d.name};
    if (!progress.needsUpdate(now, total, open)) return;
    _ref
        .read(debtProgressStoreProvider)
        ?.save(progress.recorded(now, total, open));
  }

  void _syncReminder() {
    final plan = _ref.read(debtPlanProvider);
    final reminders = _ref.read(remindersProvider).value;
    if (!plan.hasValue || reminders == null) return;
    final repo = _ref.read(reminderRepositoryProvider);
    Reminder? existing;
    for (final r in reminders) {
      if (r.id == debtPlanReminderId) existing = r;
    }
    final enabled = _ref.read(debtPlanSettingsProvider).reminderEnabled;
    final desired = enabled && plan.value != null
        ? _desired(plan.value!, existing)
        : null;
    if (desired == null) {
      if (existing != null) repo.delete(debtPlanReminderId);
    } else if (existing == null ||
        existing.title != desired.title ||
        !Dates.sameDay(existing.date, desired.date)) {
      repo.save(desired);
    }
  }

  Reminder _desired(DebtPlan plan, Reminder? existing) {
    final l10n = _ref.read(l10nProvider);
    final money = _ref.read(currencyFormatterProvider);
    final now = _ref.read(clockProvider)();
    final target = plan.focus ?? plan.order.first;
    final payment = plan.schedule.months.first.paymentsMinor[target.id] ?? 0;
    return Reminder(
      id: debtPlanReminderId,
      title: l10n.debtPlanReminderTitle(money.format(payment), target.name),
      type: ReminderType.custom,
      date: DateTime(plan.start.year, plan.start.month + 1),
      hour: existing?.hour ?? 9,
      minute: existing?.minute ?? 0,
      recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly),
      enabled: existing?.enabled ?? true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }
}

final debtPlanSyncProvider = Provider<DebtPlanSync>(DebtPlanSync.new);
