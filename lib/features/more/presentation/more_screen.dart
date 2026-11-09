import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/vehicles/application/vehicle_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Secondary sections, kept out of the bottom bar to avoid crowding it.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final openDebts = ref.watch(debtSummaryProvider).openCount;
    final reminderCount = (ref.watch(remindersProvider).value ?? const [])
        .where((r) => r.enabled)
        .length;
    final vehicleCount = (ref.watch(vehiclesProvider).value ?? const []).length;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    Widget tile(
      IconData icon,
      String title,
      VoidCallback onTap, {
      int? count,
    }) => ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null && count > 0) Badge(label: Text('$count')),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header(l10n.moreMoney),
          tile(
            Icons.flag_rounded,
            l10n.debtPlanTitle,
            () => AppRoutes.debtPlan(context),
          ),
          tile(
            Icons.payments_rounded,
            l10n.extraMoneyTitle,
            () => AppRoutes.extraMoney(context),
          ),
          tile(
            Icons.handshake_rounded,
            l10n.borrowLendTitle,
            () => AppRoutes.borrowLend(context),
            count: openDebts,
          ),
          tile(
            Icons.category_rounded,
            l10n.categoriesManage,
            () => AppRoutes.categories(context),
          ),
          tile(
            Icons.pie_chart_rounded,
            l10n.budgetsTitle,
            () => AppRoutes.budgets(context),
          ),
          tile(
            Icons.repeat_rounded,
            l10n.recurringTitle,
            () => AppRoutes.recurring(context),
          ),
          tile(
            Icons.insights_rounded,
            l10n.reportsTitle,
            () => AppRoutes.reports(context),
          ),
          tile(
            Icons.directions_car_rounded,
            l10n.vehiclesTitle,
            () => AppRoutes.vehicles(context),
            count: vehicleCount,
          ),
          tile(
            Icons.notifications_rounded,
            l10n.remindersTitle,
            () => AppRoutes.reminders(context),
            count: reminderCount,
          ),
          header(l10n.moreTools),
          tile(
            Icons.calculate_rounded,
            l10n.emiCalculator,
            () => AppRoutes.emiCalculator(context),
          ),
          tile(
            Icons.swap_horiz_rounded,
            l10n.debtSwitchTitle,
            () => AppRoutes.debtSwitch(context),
          ),
          tile(
            Icons.speed_rounded,
            l10n.mileageCalculator,
            () => AppRoutes.mileageCalculator(context),
          ),
          tile(
            Icons.search_rounded,
            l10n.searchEverything,
            () => AppRoutes.search(context),
          ),
          header(l10n.moreApp),
          tile(
            Icons.settings_rounded,
            l10n.settingsTitle,
            () => AppRoutes.settings(context),
          ),
        ],
      ),
    );
  }
}
