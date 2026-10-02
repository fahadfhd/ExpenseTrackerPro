import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/routing/app_routes.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/ledger_effects.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_tile.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:expensetrackerpro/shared/widgets/section_card.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Account account) async {
    final l10n = context.l10n;
    final repo = ref.read(accountRepositoryProvider);
    if (await repo.isInUse(account.id)) {
      if (context.mounted) showMessage(context, l10n.accountInUse);
      return;
    }
    if (!context.mounted || !await confirmDelete(context, account.name)) return;
    repo.delete(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = ref.watch(accountsByIdProvider)[accountId];
    if (account == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off_rounded, message: l10n.failureNotFound));
    }
    final outgoing = ref.watch(linkedTransactionsProvider(('accountId', accountId)));
    final incoming = ref.watch(linkedTransactionsProvider(('toAccountId', accountId)));
    final month = Dates.monthOf(DateTime.now());
    final monthTx = ref.watch(monthTransactionsProvider(month)).value ?? const <Transaction>[];
    var monthIn = 0, monthOut = 0;
    for (final tx in monthTx) {
      final delta = LedgerEffects.of(tx).accounts[accountId] ?? 0;
      if (delta > 0) monthIn += delta;
      if (delta < 0) monthOut -= delta;
    }
    final merged = {
      for (final t in [...?outgoing.value, ...?incoming.value]) t.id: t,
    }.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => AppRoutes.editAccount(context, account),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              final repo = ref.read(accountRepositoryProvider);
              if (v == 'archive') {
                repo.save(account.copyWith(archived: !account.archived, updatedAt: DateTime.now()));
                showMessage(context, account.archived ? l10n.saved : l10n.accountArchived);
              } else if (v == 'delete') {
                _delete(context, ref, account);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'archive', child: Text(account.archived ? l10n.unarchive : l10n.archive)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: l10n.currentBalance,
            subtitle: [
              if (account.bankName.isNotEmpty) account.bankName,
              l10n.accountType(account.type),
            ].join(' · '),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  account.balanceMinor,
                  tone: account.balanceMinor < 0 ? MoneyTone.negative : MoneyTone.neutral,
                  signed: account.balanceMinor < 0,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.inThisMonth, style: theme.textTheme.labelMedium),
                          MoneyText(monthIn, tone: MoneyTone.positive, signed: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.outThisMonth, style: theme.textTheme.labelMedium),
                          MoneyText(monthOut, tone: MoneyTone.negative, signed: true),
                        ],
                      ),
                    ),
                  ],
                ),
                if (account.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(account.notes),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.recentActivity, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (outgoing.isLoading && merged.isEmpty)
            const SkeletonList(count: 3)
          else if (outgoing.hasError)
            ErrorState(error: outgoing.error!)
          else if (merged.isEmpty)
            EmptyState(icon: Icons.receipt_long_rounded, message: l10n.noActivity, compact: true)
          else
            for (final tx in merged.take(50))
              TransactionTile(tx, showDate: true, onTap: () => TransactionDetailSheet.show(context, tx)),
        ],
      ),
    );
  }
}
