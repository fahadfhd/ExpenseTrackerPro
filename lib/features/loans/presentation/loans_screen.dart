import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/routing/app_routes.dart';
import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:expensetrackerpro/features/loans/application/loan_providers.dart';
import 'package:expensetrackerpro/features/loans/domain/amortization.dart';
import 'package:expensetrackerpro/features/loans/domain/loan.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:expensetrackerpro/shared/widgets/section_card.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedules = ref.watch(loanSchedulesProvider);
    final overview = ref.watch(loansOverviewProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loansTitle),
        actions: [
          IconButton(
            tooltip: l10n.emiCalculator,
            icon: const Icon(Icons.calculate_rounded),
            onPressed: () => AppRoutes.emiCalculator(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'loans-fab',
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addLoan),
        onPressed: () => AppRoutes.newLoan(context),
      ),
      body: AsyncView<Map<String, LoanSchedule>>(
        value: schedules,
        onRetry: () => ref.invalidate(loansProvider),
        data: (map) {
          if (map.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              message: l10n.loansEmpty,
            );
          }
          final list = map.values.toList()
            ..sort((a, b) {
              final aActive = a.effectiveStatus == LoanStatus.active;
              final bActive = b.effectiveStatus == LoanStatus.active;
              if (aActive != bActive) return aActive ? -1 : 1;
              final an = a.nextDue?.dueDate, bn = b.nextDue?.dueDate;
              if (an == null || bn == null) return 0;
              return an.compareTo(bn);
            });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.loansOutstanding,
                            style: theme.textTheme.labelMedium,
                          ),
                          MoneyText(
                            overview.outstandingMinor,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            l10n.loansActive('${overview.activeCount}'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.loansMonthlyEmi,
                            style: theme.textTheme.labelMedium,
                          ),
                          MoneyText(
                            overview.monthlyEmiMinor,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (overview.overdueCount > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.error_rounded,
                                  size: 14,
                                  color: context.finance.negative,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.loanOverdueCount(
                                    '${overview.overdueCount}',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: context.finance.negative,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final s in list) LoanTile(schedule: s),
            ],
          );
        },
      ),
    );
  }
}

class LoanTile extends StatelessWidget {
  const LoanTile({super.key, required this.schedule});

  final LoanSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final loan = schedule.loan;
    final next = schedule.nextDue;
    final status = schedule.effectiveStatus;
    final locale = Localizations.localeOf(context).toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppRoutes.loan(context, loan.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  LoanStatusChip(status),
                ],
              ),
              if (loan.lender.isNotEmpty)
                Text(loan.lender, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              ProgressMeter(
                ratio: schedule.paidRatio,
                semanticsLabel: l10n.loanProgress(
                  '${schedule.paidCount}',
                  '${schedule.rows.length}',
                ),
                warnAt: 2,
                alertAt: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.outstandingPrincipal,
                          style: theme.textTheme.labelSmall,
                        ),
                        MoneyText(
                          schedule.outstandingPrincipalMinor,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          next == null
                              ? l10n.noNextEmi
                              : l10n.nextEmiOn(
                                  '${next.number}',
                                  DateFormat.MMMd(locale).format(next.dueDate),
                                ),
                          style: theme.textTheme.labelSmall,
                        ),
                        if (next != null)
                          MoneyText(
                            next.emiMinor,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoanStatusChip extends StatelessWidget {
  const LoanStatusChip(this.status, {super.key});

  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, color) = switch (status) {
      LoanStatus.active => (Icons.autorenew_rounded, theme.colorScheme.primary),
      LoanStatus.completed => (
        Icons.check_circle_rounded,
        context.finance.positive,
      ),
      LoanStatus.prepaid => (Icons.bolt_rounded, context.finance.positive),
      LoanStatus.closed => (
        Icons.lock_rounded,
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    return StatusChip(label: l10n.loanStatus(status), icon: icon, color: color);
  }
}
