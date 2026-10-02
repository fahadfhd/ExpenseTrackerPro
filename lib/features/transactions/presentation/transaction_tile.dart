import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// How a transaction reads in lists: inflows are +, spending and debt
/// outflows are −, internal movements (transfers, card bills) are neutral.
MoneyTone toneOf(Transaction tx) {
  if (tx.type.isInflow) return MoneyTone.positive;
  if (tx.type == TransactionType.transfer ||
      tx.type == TransactionType.creditCardPayment) {
    return MoneyTone.neutral;
  }
  return MoneyTone.negative;
}

String titleOf(AppLocalizations l10n, Transaction tx) {
  if (tx.description.isNotEmpty) return tx.description;
  if (tx.counterparty.isNotEmpty) return tx.counterparty;
  return l10n.categoryLabel(tx.subCategoryId ?? tx.categoryId);
}

class TransactionTile extends ConsumerWidget {
  const TransactionTile(
    this.tx, {
    super.key,
    this.onTap,
    this.showDate = false,
  });

  final Transaction tx;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final category = Categories.byId(tx.categoryId);
    final accounts = ref.watch(accountsByIdProvider);
    final cards = ref.watch(cardsByIdProvider);

    final source = switch (tx.type) {
      TransactionType.transfer =>
        '${accounts[tx.accountId]?.name ?? '?'} → ${accounts[tx.toAccountId]?.name ?? '?'}',
      _ when tx.creditCardId != null => cards[tx.creditCardId]?.displayName,
      _ => accounts[tx.accountId]?.name,
    };
    final subtitleParts = [
      l10n.categoryLabel(tx.subCategoryId ?? tx.categoryId),
      ?source,
      if (showDate)
        DateFormat.MMMd(
          Localizations.localeOf(context).toString(),
        ).format(tx.date),
    ];
    final tone = toneOf(tx);

    // A custom row rather than ListTile: at large text sizes the amount may
    // be wider than ListTile allows for a trailing widget, which breaks the
    // whole list. Here the amount scales down to fit instead.
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleOf(l10n, tx),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: MoneyText(
                        tx.amountMinor,
                        tone: tone,
                        signed: true,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!tx.isCleared)
                      Text(
                        l10n.txStatusPending,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
