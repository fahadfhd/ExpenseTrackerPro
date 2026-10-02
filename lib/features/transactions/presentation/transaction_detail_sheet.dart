import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_tile.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet(this.tx, {super.key});

  final Transaction tx;

  static Future<void> show(BuildContext context, Transaction tx) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TransactionDetailSheet(tx),
      );

  /// Entries owned by another module must be changed there, or the
  /// module's own records (installments, settlements, fuel logs) would no
  /// longer match.
  String? _managedBy(AppLocalizations l10n) {
    if (tx.loanId != null) return l10n.moduleLoans;
    if (tx.borrowLendId != null) return l10n.moduleBorrowLend;
    if (tx.vehicleId != null) return l10n.moduleVehicles;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsByIdProvider);
    final cards = ref.watch(cardsByIdProvider);
    final category = Categories.byId(tx.categoryId);
    final locale = Localizations.localeOf(context).toString();
    final managedBy = _managedBy(l10n);

    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
              ],
            ),
          );

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titleOf(l10n, tx),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MoneyText(
            tx.amountMinor,
            tone: toneOf(tx),
            signed: true,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          row(l10n.typeLabel, l10n.transactionType(tx.type)),
          row(
            l10n.category,
            [
              l10n.categoryLabel(tx.categoryId),
              if (tx.subCategoryId != null) l10n.categoryLabel(tx.subCategoryId),
            ].join(' › '),
          ),
          row(l10n.date, DateFormat.yMMMEd(locale).add_jm().format(tx.date)),
          row(
            tx.type == TransactionType.transfer ? l10n.fromAccount : l10n.paidWith,
            accounts[tx.accountId]?.displayName,
          ),
          row(l10n.toAccount, accounts[tx.toAccountId]?.displayName),
          row(l10n.creditCard, cards[tx.creditCardId]?.displayName),
          row(l10n.merchantOrPerson, tx.counterparty),
          row(l10n.notes, tx.notes),
          row(l10n.tags, tx.tags.join(', ')),
          if (!tx.isCleared) row(l10n.status, l10n.txStatusPending),
          if (tx.recurringRuleId != null) row('', l10n.recurringGenerated),
          if (tx.importSource != null) row('', l10n.importedFrom(tx.importSource!)),
          const SizedBox(height: 16),
          if (managedBy != null)
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.link_rounded,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.managedElsewhere(managedBy),
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.edit),
                  onPressed: () {
                    Navigator.pop(context);
                    TransactionFormSheet.show(context, initial: tx);
                  },
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(l10n.duplicate),
                  onPressed: () {
                    Navigator.pop(context);
                    TransactionFormSheet.show(
                      context,
                      initial: tx,
                      duplicate: true,
                    );
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () async {
                    if (!await confirmDelete(context, titleOf(l10n, tx))) return;
                    ref.read(transactionRepositoryProvider).delete(tx);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    showMessage(context, l10n.transactionDeleted);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
