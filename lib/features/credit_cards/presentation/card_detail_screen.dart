import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:kept/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:kept/features/transactions/presentation/transaction_tile.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CreditCard card,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(creditCardRepositoryProvider);
    if (await repo.isInUse(card.id)) {
      if (context.mounted) showMessage(context, l10n.cardInUse);
      return;
    }
    if (!context.mounted || !await confirmDelete(context, card.displayName)) {
      return;
    }
    repo.delete(card.id);
    ref
        .read(entityRemindersProvider)
        .remove(ReminderEntityType.creditCard, card.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final card = ref.watch(cardsByIdProvider)[cardId];
    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off_rounded,
          message: l10n.failureNotFound,
        ),
      );
    }
    final status = ref.watch(cardStatusesProvider)[cardId];
    final locale = Localizations.localeOf(context).toString();
    final range = DateRange.lastMonths(DateTime.now(), trendMonths);
    final history = ref.watch(transactionsInRangeProvider(range)).value;
    final points = history == null
        ? null
        : monthPoints(range, history.where((t) => t.creditCardId == cardId));
    final linked = ref.watch(
      linkedTransactionsProvider(('creditCardId', cardId)),
    );

    Widget figure(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w800),
            child: value,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(card.displayName),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => AppRoutes.editCard(context, card),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archive') {
                final updated = card.copyWith(
                  archived: !card.archived,
                  updatedAt: DateTime.now(),
                );
                ref.read(creditCardRepositoryProvider).save(updated);
                ref.read(entityRemindersProvider).syncCard(updated);
              } else if (v == 'delete') {
                _delete(context, ref, card);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(card.archived ? l10n.unarchive : l10n.archive),
              ),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: l10n.outstanding,
            subtitle: card.bankName.isEmpty ? null : card.bankName,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  card.outstandingMinor,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ProgressMeter(
                  ratio: card.utilization,
                  semanticsLabel: l10n.utilization,
                  warnAt: 0.3,
                  alertAt: 0.75,
                  height: 12,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.utilizationValue('${(card.utilization * 100).round()}'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    figure(l10n.creditLimit, MoneyText(card.creditLimitMinor)),
                    figure(l10n.available, MoneyText(card.availableMinor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (status != null)
            SectionCard(
              title: l10n.statement,
              subtitle: DateFormat.yMMMd(
                locale,
              ).format(status.lastStatementDate),
              child: Column(
                children: [
                  Row(
                    children: [
                      figure(
                        l10n.statementBalance,
                        MoneyText(status.statementBalanceMinor),
                      ),
                      figure(
                        l10n.totalDue,
                        status.isPaid
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(l10n.paidInFull),
                                ],
                              )
                            : MoneyText(status.totalDueMinor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      figure(
                        l10n.minimumDueEstimate,
                        MoneyText(status.minimumDueMinor),
                      ),
                      figure(
                        l10n.dueDate,
                        Text(DateFormat.yMMMd(locale).format(status.dueDate)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.credit_score_rounded),
                  label: Text(l10n.payBill),
                  onPressed: () => TransactionFormSheet.show(
                    context,
                    kind: EntryKind.cardPayment,
                    presetCardId: cardId,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addCardExpense),
                  onPressed: () => TransactionFormSheet.show(
                    context,
                    kind: EntryKind.expense,
                    presetCardId: cardId,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (points != null)
            SectionCard(
              title: l10n.cardSpending6m,
              child: MonthlyBarChart(
                aLabel: l10n.dashboardCardSpending,
                semanticsLabel: l10n.cardSpending6m,
                months: [
                  for (final p in points)
                    MonthBar(
                      label: DateFormat.MMM(locale).format(p.month),
                      a: p.summary.cardSpending,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.recentActivity,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          AsyncView(
            value: linked,
            data: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    message: l10n.noActivity,
                    compact: true,
                  )
                : Column(
                    children: [
                      for (final tx in list)
                        TransactionTile(
                          tx,
                          showDate: true,
                          onTap: () => TransactionDetailSheet.show(context, tx),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
