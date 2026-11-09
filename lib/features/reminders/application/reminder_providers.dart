import 'dart:async';

import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/notifications/notification_planner.dart';
import 'package:kept/core/notifications/notification_service.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/reminders/data/reminder_repository.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return ReminderRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
  );
});

final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(reminderRepositoryProvider).watchAll(),
);

/// Overridden in tests with a fake.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(),
);

final notificationsEnabledProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(notificationServiceProvider).areEnabled(),
);

String notificationBody(AppLocalizations l10n, Reminder r, int offset) {
  final what = r.description.isNotEmpty
      ? r.description
      : l10n.reminderType(r.type);
  if (offset == 0) return l10n.notifDue(what);
  if (offset % 1440 == 0) return l10n.notifInDays(what, '${offset ~/ 1440}');
  if (offset % 60 == 0) return l10n.notifInHours(what, '${offset ~/ 60}');
  return l10n.notifInMinutes(what, '$offset');
}

/// Keeps device notifications in sync with reminder data.
///
/// Re-plans whenever reminders change (including after a restore or on a
/// fresh install, when they stream in from Firestore) and when the app
/// resumes. Because notification ids are deterministic, re-planning never
/// creates duplicates.
class NotificationSync {
  NotificationSync(this._ref) {
    _ref.listen<AsyncValue<List<Reminder>>>(remindersProvider, (_, next) {
      if (next.hasValue) _schedule();
    }, fireImmediately: true);
    // Notification wording follows the app language, so re-plan when it
    // changes. (This only starts a timer: the change can arrive while
    // widgets are building, when providers must not be written to.)
    _ref.listen(appLocaleProvider, (_, _) => _schedule());
  }

  final Ref _ref;
  Timer? _debounce;
  bool _running = false;
  bool _again = false;

  void resync() => _schedule();

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  Future<void> _run() async {
    if (_running) {
      _again = true;
      return;
    }
    final reminders = _ref.read(remindersProvider).value;
    if (reminders == null) return;
    _running = true;
    try {
      await _ensurePermission(reminders);
      final l10n = _ref.read(l10nProvider);
      final service = _ref.read(notificationServiceProvider);
      // Language polish: neither step may stop the notifications themselves
      // from being scheduled, so a failure is only logged.
      try {
        // Titles stored on card and borrow/lend reminders keep the language
        // they were written in; bring them in line with the current one.
        _ref.read(entityRemindersProvider).relabel();
        await service.setChannelText(
          name: l10n.notificationChannelName,
          description: l10n.notificationChannelDescription,
        );
      } catch (e) {
        debugPrint('Updating reminder text for the language failed: $e');
      }
      final plan = NotificationPlanner.plan(
        reminders,
        now: DateTime.now(),
        bodyFor: (r, offset) => notificationBody(l10n, r, offset),
      );
      await service.reconcile(plan);
    } catch (e) {
      debugPrint('Notification sync failed: $e');
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        _schedule();
      }
    }
  }

  static const permissionAskedKey = 'notifications.permissionRequested';

  /// Asks for notification permission once per install, as soon as any
  /// reminder exists — including reminders created by loans, cards and
  /// borrow/lend records, or restored after a reinstall. Without this,
  /// Android 13+ and iOS silently drop every scheduled notification.
  Future<void> _ensurePermission(List<Reminder> reminders) async {
    if (!reminders.any((r) => r.enabled)) return;
    final prefs = _ref.read(sharedPreferencesProvider);
    if (prefs.getBool(permissionAskedKey) ?? false) return;
    // Set first so a dismissed dialog is not shown again on every change.
    await prefs.setBool(permissionAskedKey, true);
    await _ref.read(notificationServiceProvider).requestPermission();
    _ref.invalidate(notificationsEnabledProvider);
  }

  void dispose() => _debounce?.cancel();
}

final notificationSyncProvider = Provider<NotificationSync>((ref) {
  final sync = NotificationSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});

/// Builds the reminders owned by cards and borrow/lend records.
///
/// When a reminder for the entity already exists, the user's choices on it
/// (time, alert offsets, on/off) are kept; only the schedule derived from
/// the entity is refreshed.
class EntityReminders {
  EntityReminders(this._ref);

  final Ref _ref;

  ReminderRepository get _repo => _ref.read(reminderRepositoryProvider);

  AppLocalizations get _l10n => _ref.read(l10nProvider);

  Reminder? _existing(ReminderEntityType type, String id) {
    final reminders = _ref.read(remindersProvider).value ?? const [];
    final key = Reminder.entityReminderId(type, id);
    return reminders.where((r) => r.id == key).firstOrNull;
  }

  /// Loan reminders are kept in sync by `LoanReminderSync`, which follows
  /// the live repayment schedule.

  Reminder _merge(Reminder fresh, Reminder? existing) => existing == null
      ? fresh
      : fresh.copyWith(
          hour: existing.hour,
          minute: existing.minute,
          offsetsMinutes: existing.offsetsMinutes,
          enabled: existing.enabled,
        );

  void syncCard(CreditCard card) {
    const type = ReminderEntityType.creditCard;
    if (card.archived) {
      _repo.syncEntityReminder(type, card.id, null);
      return;
    }
    final existing = _existing(type, card.id);
    final now = DateTime.now();
    _repo.syncEntityReminder(
      type,
      card.id,
      _merge(
        Reminder(
          id: Reminder.entityReminderId(type, card.id),
          title: _l10n.reminderCardTitle(card.displayName),
          type: ReminderType.creditCardPayment,
          // Anchored in January (31 days) so the due day is never clamped
          // permanently; shorter months clamp per occurrence.
          date: DateTime(card.createdAt.year, DateTime.january, card.dueDay),
          hour: 10,
          minute: 0,
          recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly),
          entityType: type,
          entityId: card.id,
          offsetsMinutes: const [3 * 1440, 1440, 0],
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
        existing,
      ),
    );
  }

  void syncDebt(DebtRecord record) {
    const type = ReminderEntityType.borrowLend;
    final due = record.dueDate;
    if (!record.reminderEnabled || due == null || record.isSettled) {
      _repo.syncEntityReminder(type, record.id, null);
      return;
    }
    final existing = _existing(type, record.id);
    final now = DateTime.now();
    final borrowed = record.direction == DebtDirection.borrowed;
    _repo.syncEntityReminder(
      type,
      record.id,
      Reminder(
        id: Reminder.entityReminderId(type, record.id),
        title: borrowed
            ? _l10n.reminderBorrowedTitle(record.personName)
            : _l10n.reminderLentTitle(record.personName),
        description: record.description,
        type: borrowed ? ReminderType.borrowed : ReminderType.lent,
        date: due,
        hour: existing?.hour ?? 9,
        minute: existing?.minute ?? 0,
        entityType: type,
        entityId: record.id,
        // Offsets are chosen on the record itself.
        offsetsMinutes: record.reminderOffsetsMinutes.isEmpty
            ? const [0]
            : record.reminderOffsetsMinutes,
        enabled: existing?.enabled ?? true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  void remove(ReminderEntityType type, String id) =>
      _repo.syncEntityReminder(type, id, null);

  /// Re-titles the card and borrow/lend reminders in the current language.
  /// Their titles are stored text, so after a language change they would
  /// otherwise stay in the old language until the card or record is next
  /// edited. Only reminders whose title actually differs are rewritten.
  /// (Loan reminders are re-titled by `LoanReminderSync`.)
  void relabel() {
    for (final card in _ref.read(cardsProvider).value ?? const <CreditCard>[]) {
      final existing = _existing(ReminderEntityType.creditCard, card.id);
      if (existing != null &&
          existing.title != _l10n.reminderCardTitle(card.displayName)) {
        syncCard(card);
      }
    }
    final debts = _ref.read(debtsProvider).value ?? const <DebtRecord>[];
    for (final record in debts) {
      final existing = _existing(ReminderEntityType.borrowLend, record.id);
      if (existing == null) continue;
      final title = record.direction == DebtDirection.borrowed
          ? _l10n.reminderBorrowedTitle(record.personName)
          : _l10n.reminderLentTitle(record.personName);
      if (existing.title != title) syncDebt(record);
    }
  }
}

final entityRemindersProvider = Provider<EntityReminders>(EntityReminders.new);
