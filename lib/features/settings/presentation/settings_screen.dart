import 'package:expensetrackerpro/app/app_providers.dart';
import 'package:expensetrackerpro/core/config/feature_flags.dart';
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/currency_formatter.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/features/auth/data/auth_repository.dart';
import 'package:expensetrackerpro/features/backup/data/backup_service.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/settings/application/gmail_import.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  /// Runs a long operation with a busy indicator and user-safe errors.
  Future<void> _run(Future<String?> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final message = await task();
      if (mounted && message != null) showMessage(context, message);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkGoogle() => _run(() async {
    final l10n = context.l10n;
    final auth = ref.read(authRepositoryProvider);
    final result = await auth.linkGoogle();
    if (result == GoogleLinkResult.accountExists && mounted) {
      final ok = await confirmAction(
        context,
        title: l10n.googleAccountExistsTitle,
        message: l10n.googleAccountExistsBody,
        confirmLabel: l10n.switchAccount,
      );
      if (ok) await auth.switchToExistingGoogleAccount();
    }
    return null;
  });

  Future<void> _signOut(bool isGuest) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.signOutConfirm,
      message: isGuest ? l10n.signOutGuestWarning : l10n.signOutBody,
      confirmLabel: l10n.signOut,
    );
    if (!ok) return;
    await _run(() async {
      // The next user must not receive this user's reminders.
      await ref.read(notificationServiceProvider).reconcile(const []);
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      return null;
    });
  }

  Future<void> _restore(BackupEntry entry) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.restoreConfirmTitle,
      message: l10n.restoreConfirmBody,
      confirmLabel: l10n.confirm,
    );
    if (!ok) return;
    await _run(() async {
      final result = await ref.read(backupServiceProvider).restore(entry);
      ref.read(notificationSyncProvider).resync();
      return [
        l10n.restoreDone('${result.restored}'),
        if (result.skipped > 0) l10n.restoreSkipped('${result.skipped}'),
      ].join('. ');
    });
  }

  Future<void> _showBackups() async {
    final l10n = context.l10n;
    List<BackupEntry> entries = const [];
    await _run(() async {
      entries = await ref.read(backupServiceProvider).listBackups();
      return null;
    });
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toString();
    final chosen = await showModalBottomSheet<BackupEntry>(
      context: context,
      builder: (context) => SafeArea(
        child: entries.isEmpty
            ? Padding(padding: const EdgeInsets.all(24), child: Text(l10n.backupEmpty))
            : ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text(l10n.backupList, style: const TextStyle(fontWeight: FontWeight.w800))),
                  for (final e in entries)
                    ListTile(
                      leading: const Icon(Icons.restore_rounded),
                      title: Text(DateFormat.yMMMd(locale).add_jm().format(e.createdAt)),
                      onTap: () => Navigator.pop(context, e),
                    ),
                ],
              ),
      ),
    );
    if (chosen != null) await _restore(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final user = ref.watch(authStateProvider).value;
    final isGuest = user?.isAnonymous ?? true;
    final backup = ref.watch(backupStatusProvider).value;
    final sync = ref.watch(syncStatusProvider);
    final notificationsOn = ref.watch(notificationsEnabledProvider).value;
    final locale = Localizations.localeOf(context).toString();
    final timeFmt = DateFormat.yMMMd(locale).add_jm();

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header(l10n.settingsAccount),
          ListTile(
            leading: Icon(isGuest ? Icons.person_outline_rounded : Icons.verified_user_rounded),
            title: Text(isGuest ? l10n.guestAccount : l10n.signedInAs(user?.email ?? '')),
            subtitle: isGuest ? Text(l10n.guestWarning) : null,
          ),
          if (isGuest && GoogleSignInBootstrap.isSupported)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.login_rounded),
                label: Text(l10n.linkGoogle),
                onPressed: _busy ? null : _linkGoogle,
              ),
            ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(l10n.signOut),
            onTap: _busy ? null : () => _signOut(isGuest),
          ),

          header(l10n.settingsAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem), icon: const Icon(Icons.brightness_auto_rounded)),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight), icon: const Icon(Icons.light_mode_rounded)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark), icon: const Icon(Icons.dark_mode_rounded)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => controller.setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PickerField<String>(
              label: l10n.settingsCurrency,
              value: settings.currencyCode,
              options: [
                for (final code in supportedCurrencies.keys)
                  PickerOption(code, '$code · ${CurrencyFormatter(currencyCode: code).symbol}'),
              ],
              onChanged: (v) => controller.setCurrency(v ?? settings.currencyCode),
            ),
          ),
          if (AppLocalizations.supportedLocales.length > 1) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PickerField<String>(
                label: l10n.settingsLanguage,
                value: settings.localeCode,
                allowNone: true,
                noneLabel: l10n.languageSystem,
                options: [
                  for (final l in AppLocalizations.supportedLocales)
                    PickerOption(l.languageCode, l.languageCode.toUpperCase()),
                ],
                onChanged: controller.setLocale,
              ),
            ),
          ],
          SwitchListTile(
            secondary: const Icon(Icons.pie_chart_outline_rounded),
            title: Text(l10n.budgetAlertsSetting),
            value: settings.budgetAlerts,
            onChanged: controller.setBudgetAlerts,
          ),

          header(l10n.settingsNotifications),
          ListTile(
            leading: Icon(notificationsOn == true ? Icons.notifications_active_rounded : Icons.notifications_off_rounded),
            title: Text(notificationsOn == true ? l10n.notificationsStatusOn : l10n.notificationsStatusOff),
            trailing: notificationsOn == true
                ? null
                : TextButton(
                    onPressed: () async {
                      await ref.read(notificationServiceProvider).requestPermission();
                      ref.invalidate(notificationsEnabledProvider);
                      ref.read(notificationSyncProvider).resync();
                    },
                    child: Text(l10n.notificationsEnable),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.sync_rounded),
            title: Text(l10n.notificationsResync),
            onTap: () {
              ref.read(notificationSyncProvider).resync();
              showMessage(context, l10n.notificationsResynced);
            },
          ),

          header(l10n.settingsData),
          ListTile(
            leading: Icon(sync.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded),
            title: Text(sync.isSynced ? l10n.syncAllSynced : l10n.syncPending('${sync.pending}')),
            subtitle: sync.lastSyncedAt == null ? null : Text(l10n.syncLastSynced(timeFmt.format(sync.lastSyncedAt!))),
          ),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: Text(l10n.backupTitle),
            subtitle: Text(
              isGuest
                  ? l10n.backupNeedsAccount
                  : backup?.lastBackupAt == null
                  ? l10n.backupNever
                  : l10n.backupLast(timeFmt.format(backup!.lastBackupAt!)),
            ),
          ),
          if (!isGuest) ...[
            SwitchListTile(
              secondary: const Icon(Icons.event_repeat_rounded),
              title: Text(l10n.backupAuto),
              value: settings.autoBackup,
              onChanged: controller.setAutoBackup,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(l10n.backupNow),
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final count = await ref.read(backupServiceProvider).backupNow(settings: settings.toMap());
                              return l10n.backupDone('$count');
                            }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore_rounded),
                      label: Text(l10n.backupList),
                      onPressed: _busy ? null : _showBackups,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text(l10n.recalcBalances),
            subtitle: Text(l10n.recalcBalancesHelp),
            onTap: _busy
                ? null
                : () => _run(() async {
                    await ref.read(transactionRepositoryProvider).recalculateBalances();
                    return l10n.recalcDone;
                  }),
          ),
          if (kAutoImportEnabled && !isGuest)
            ListTile(
              leading: const Icon(Icons.mark_email_read_rounded),
              title: Text(l10n.importTitle),
              subtitle: Text(l10n.importBody),
              onTap: _busy
                  ? null
                  : () => _run(() async {
                      final count = await ref.read(gmailImportProvider).run();
                      return l10n.importDone('$count');
                    }),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.privacyNote, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
