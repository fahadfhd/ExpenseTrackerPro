import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/features/auth/data/auth_repository.dart';
import 'package:kept/features/backup/data/backup_service.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:kept/features/debt_plan/application/debt_plan_sync.dart';
import 'package:kept/features/loans/application/loan_reminder_sync.dart';
import 'package:kept/features/recurring/application/recurring_providers.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
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
  List<ProviderSubscription<Object?>>? _syncs;

  /// Starts the background syncs and holds them open for the app's lifetime:
  ///
  /// - device notifications follow the reminders (also after a reinstall or
  ///   restore);
  /// - loan EMI reminders follow each loan's live schedule;
  /// - the debt history and plan reminder follow what is owed;
  /// - the user's own categories are loaded into the shared registry.
  ///
  /// They are listened to from the container, not from a widget or another
  /// provider. Riverpod pauses a stream once the widgets watching it are
  /// hidden (any screen pushed on top of the tabs does that), and a provider
  /// that is merely read, or only listened to by another provider, does not
  /// keep its sources running. A background sync must not depend on which
  /// screen happens to be showing.
  void _startSyncs() {
    final container = _ref.container;
    _syncs ??= [
      container.listen(notificationSyncProvider, (_, _) {}),
      container.listen(loanReminderSyncProvider, (_, _) {}),
      container.listen(debtPlanSyncProvider, (_, _) {}),
      container.listen(customCategoriesProvider, (_, _) {}),
    ];
  }

  Future<void> run() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null || _ranFor == user.uid) return;
    _ranFor = user.uid;

    _startSyncs();

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
    _ref
        .read(writeDispatcherProvider)
        .dispatch(
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
