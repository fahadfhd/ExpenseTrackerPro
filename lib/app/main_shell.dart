import 'package:kept/app/app_providers.dart';
import 'package:kept/core/ads/ad_free.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/features/accounts/presentation/accounts_screen.dart';
import 'package:kept/features/dashboard/presentation/dashboard_screen.dart';
import 'package:kept/features/loans/presentation/loans_screen.dart';
import 'package:kept/features/more/presentation/more_screen.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:kept/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation: Home, Transactions, Accounts, Loans, More.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(startupTasksProvider).run();
    });
    _lifecycle = AppLifecycleListener(
      onResume: () {
        // A timer does not run while the app is suspended: check whether the
        // 24 ad-free hours ended in the meantime.
        ref.read(adFreeUntilProvider.notifier).refresh();
        // Refill the rolling notification window.
        ref.read(notificationSyncProvider).resync();
        // Record recurring entries that came due while in the background.
        ref
            .read(startupTasksProvider)
            .catchUpRecurring()
            .catchError(
              (Object e) => debugPrint('Recurring catch-up failed: $e'),
            );
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tab = ref.watch(shellTabProvider);
    ref.listen(syncStatusProvider.select((s) => s.lastFailure), (_, failure) {
      if (failure == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.syncRejected(l10n.failure(failure)))),
      );
      ref.read(syncStatusProvider.notifier).clearFailure();
    });

    final showFab = tab == ShellTab.home || tab == ShellTab.transactions;
    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [
          DashboardScreen(),
          TransactionsScreen(),
          AccountsScreen(),
          LoansScreen(),
          MoreScreen(),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              heroTag: 'add-transaction',
              tooltip: l10n.addTransaction,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.add),
              onPressed: () => TransactionFormSheet.show(context),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            ref.read(shellTabProvider.notifier).select(ShellTab.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.space_dashboard_outlined),
            selectedIcon: const Icon(Icons.space_dashboard_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: l10n.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(Icons.account_balance_rounded),
            label: l10n.navAccounts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: l10n.navLoans,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps_rounded),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
