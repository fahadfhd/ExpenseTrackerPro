import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/features/auth/data/auth_repository.dart';
import 'package:expensetrackerpro/features/backup/data/backup_service.dart';
import 'package:expensetrackerpro/features/loans/application/loan_reminder_sync.dart';
import 'package:expensetrackerpro/features/recurring/application/recurring_providers.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(auth: ref.watch(firebaseAuthProvider)),
);

final backupServiceProvider = Provider<BackupService>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return BackupService(
    userDoc: userDoc,
    storage: ref.watch(firebaseStorageProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final backupStatusProvider = StreamProvider<BackupStatus>(
  (ref) => ref.watch(backupServiceProvider).watchStatus(),
);

/// Housekeeping that runs once per signed-in user per app launch. Each step
/// is independent and failures are logged, never shown as crashes: the app
/// stays fully usable offline even when these cannot complete.
class StartupTasks {
  StartupTasks(this._ref);

  final Ref _ref;
  String? _ranFor;

  Future<void> run() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null || _ranFor == user.uid) return;
    _ranFor = user.uid;

    // Starts listening to reminders; schedules device notifications for
    // them (also after a reinstall or restore).
    _ref.read(notificationSyncProvider);
    // Keeps loan EMI reminders matching each loan's live schedule.
    _ref.read(loanReminderSyncProvider);

    await _step('profile', _syncProfile);
    await _step('migration', () => _migrate(user.uid));
    await _step('recurring', catchUpRecurring);
    if (!user.isAnonymous) await _step('backup', _autoBackup);
  }

  bool _generating = false;

  /// Records recurring entries that have come due. Runs at launch and on
  /// every resume, so an app left in memory overnight still records rent or
  /// salary on its date. Concurrent calls are ignored; ids are deterministic
  /// so a repeat run never duplicates.
  Future<void> catchUpRecurring() async {
    if (_generating || _ref.read(uidProvider) == null) return;
    _generating = true;
    try {
      await _ref.read(recurringRepositoryProvider).generateDue(DateTime.now());
    } finally {
      _generating = false;
    }
  }

  Future<void> _step(String name, Future<void> Function() task) async {
    try {
      await task();
    } catch (e) {
      debugPrint('Startup task "$name" failed: $e');
    }
  }

  Future<void> _syncProfile() async {
    final user = _ref.read(authStateProvider).value;
    final userDoc = _ref.read(userDocProvider);
    if (user == null || userDoc == null) return;
    _ref.read(writeDispatcherProvider).dispatch(
      userDoc.set({
        'displayName': user.displayName,
        'email': user.email,
        'isGuest': user.isAnonymous,
        'preferredTheme': _ref.read(settingsProvider).themeMode.name,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  /// One-time upgrade of transactions written before schema 2.
  Future<void> _migrate(String uid) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final key = 'migration.transactionsV2.$uid';
    if (prefs.getBool(key) ?? false) return;
    await _ref.read(transactionRepositoryProvider).migrateLegacyDocuments();
    await prefs.setBool(key, true);
  }

  Future<void> _autoBackup() async {
    final settings = _ref.read(settingsProvider);
    if (!settings.autoBackup) return;
    final service = _ref.read(backupServiceProvider);
    final status = await service.watchStatus().first;
    final last = status.lastBackupAt;
    if (last != null &&
        DateTime.now().difference(last) < BackupService.autoBackupInterval) {
      return;
    }
    await service.backupNow(settings: settings.toMap());
  }
}

final startupTasksProvider = Provider<StartupTasks>(StartupTasks.new);
