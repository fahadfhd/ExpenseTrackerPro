import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction_query.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edits a copy of the current [TransactionFilter]; applied on "Apply".
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TransactionFilter _filter;
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    _filter = ref.read(transactionFilterProvider);
    _min = TextEditingController(
      text: _filter.minAmountMinor == null
          ? ''
          : Money.toEditable(_filter.minAmountMinor!),
    );
    _max = TextEditingController(
      text: _filter.maxAmountMinor == null
          ? ''
          : Money.toEditable(_filter.maxAmountMinor!),
    );
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final cards = ref.watch(cardsProvider).value ?? const [];

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(text, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(
                  l10n.filters,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                heading(l10n.sortBy),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in TransactionSort.values)
                      ChoiceChip(
                        label: Text(l10n.sort(s)),
                        selected: _filter.sort == s,
                        onSelected: (_) =>
                            setState(() => _filter = _filter.copyWith(sort: s)),
                      ),
                  ],
                ),
                heading(l10n.typeLabel),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in TransactionType.values)
                      FilterChip(
                        label: Text(l10n.transactionType(t)),
                        selected: _filter.types.contains(t),
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(
                            types: _toggle(_filter.types, t),
                          ),
                        ),
                      ),
                  ],
                ),
                heading(l10n.categoriesLabel),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in [...Categories.expense, ...Categories.income])
                      FilterChip(
                        avatar: Icon(c.icon, size: 16, color: c.color),
                        label: Text(l10n.categoryLabel(c.id)),
                        selected: _filter.categoryIds.contains(c.id),
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(
                            categoryIds: _toggle(_filter.categoryIds, c.id),
                          ),
                        ),
                      ),
                  ],
                ),
                if (accounts.isNotEmpty) ...[
                  heading(l10n.accountsLabel),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in accounts)
                        FilterChip(
                          label: Text(a.name),
                          selected: _filter.accountIds.contains(a.id),
                          onSelected: (_) => setState(
                            () => _filter = _filter.copyWith(
                              accountIds: _toggle(_filter.accountIds, a.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (cards.isNotEmpty) ...[
                  heading(l10n.cardsLabel),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in cards)
                        FilterChip(
                          label: Text(c.displayName),
                          selected: _filter.cardIds.contains(c.id),
                          onSelected: (_) => setState(
                            () => _filter = _filter.copyWith(
                              cardIds: _toggle(_filter.cardIds, c.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                heading(l10n.amountRange),
                Row(
                  children: [
                    Expanded(
                      child: AmountField(
                        controller: _min,
                        label: l10n.minAmount,
                        required: false,
                        allowZero: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AmountField(
                        controller: _max,
                        label: l10n.maxAmount,
                        required: false,
                        allowZero: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(transactionFilterProvider.notifier).clearFilters();
                        Navigator.pop(context);
                      },
                      child: Text(l10n.clearFilters),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final min = Money.parse(_min.text);
                        final max = Money.parse(_max.text);
                        ref.read(transactionFilterProvider.notifier).update(
                          _filter.copyWith(
                            text: ref.read(transactionFilterProvider).text,
                            minAmountMinor: () => min,
                            maxAmountMinor: () => max,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(l10n.apply),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
