import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// ‹ October 2026 › — drives [selectedMonthProvider], which the dashboard,
/// transactions and budgets all follow.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final isCurrent = Dates.sameMonth(month, DateTime.now());
    final label = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(month);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            notifier.previous();
            onChanged?.call();
          },
        ),
        Flexible(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isCurrent
                ? null
                : () {
                    notifier.select(DateTime.now());
                    onChanged?.call();
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!isCurrent)
                    Text(
                      l10n.thisMonth,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () {
            notifier.next();
            onChanged?.call();
          },
        ),
      ],
    );
  }
}
