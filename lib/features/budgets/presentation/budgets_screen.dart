import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/features/budgets/application/budget_providers.dart';
import 'package:kept/features/budgets/domain/budget.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/month_switcher.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(customCategoriesProvider);
    final month = ref.watch(selectedMonthProvider);
    final usage = ref.watch(budgetUsageProvider(month));
    final money = ref.watch(currencyFormatterProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addBudget),
        onPressed: () => showFormSheet(context, const BudgetSheet()),
      ),
      body: Column(
        children: [
          const MonthSwitcher(),
          Expanded(
            child: AsyncView<List<BudgetUsage>>(
              value: usage,
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.pie_chart_rounded,
                      message: l10n.budgetsEmpty,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      children: [
                        for (final u in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => showFormSheet(
                                context,
                                BudgetSheet(initial: u.budget),
                              ),
                              child: SectionCard(
                                title: u.budget.isOverall
                                    ? l10n.budgetOverall
                                    : l10n.categoryLabel(u.budget.categoryId),
                                trailing: Text(
                                  '${u.percent}%',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ProgressMeter(
                                      ratio: u.ratio,
                                      semanticsLabel: l10n.budgetSpentOf(
                                        money.format(u.spentMinor),
                                        money.format(u.budget.amountMinor),
                                      ),
                                      warnAt: u.budget.thresholds.first / 100,
                                      alertAt: u.budget.thresholds.last / 100,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l10n.budgetSpentOf(
                                              money.format(u.spentMinor),
                                              money.format(
                                                u.budget.amountMinor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          u.isOver
                                              ? l10n.budgetOver(
                                                  money.format(
                                                    -u.remainingMinor,
                                                  ),
                                                )
                                              : l10n.budgetRemaining(
                                                  money.format(
                                                    u.remainingMinor,
                                                  ),
                                                ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (u.reachedThreshold != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          l10n.budgetReached(
                                            '${u.reachedThreshold}',
                                          ),
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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

class BudgetSheet extends ConsumerStatefulWidget {
  const BudgetSheet({super.key, this.initial});
  final Budget? initial;

  @override
  ConsumerState<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<BudgetSheet> {
  static const _overall = '__overall__';
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.amountMinor),
  );
  late final _thresholds = TextEditingController(
    text: (widget.initial?.thresholds ?? defaultBudgetThresholds).join(', '),
  );
  late String _target = widget.initial?.categoryId ?? _overall;

  @override
  void dispose() {
    _amount.dispose();
    _thresholds.dispose();
    super.dispose();
  }

  List<int>? _parseThresholds(String text) {
    final parts = text.split(',').map((p) => int.tryParse(p.trim())).toList();
    if (parts.isEmpty || parts.any((p) => p == null || p < 1 || p > 200)) {
      return null;
    }
    return (parts.cast<int>().toSet().toList()..sort());
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _target == _overall ? null : _target;
    final now = DateTime.now();
    final initial = widget.initial;
    // Switching category on an existing budget moves it to the new id.
    if (initial != null && initial.categoryId != categoryId) {
      ref.read(budgetRepositoryProvider).delete(initial.id);
    }
    ref
        .read(budgetRepositoryProvider)
        .save(
          Budget(
            id: Budget.idFor(categoryId),
            categoryId: categoryId,
            amountMinor: Money.parse(_amount.text)!,
            thresholds: _parseThresholds(_thresholds.text)!,
            createdAt: initial?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final initial = widget.initial;
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    initial == null ? l10n.addBudget : l10n.editBudget,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (initial != null)
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      ref.read(budgetRepositoryProvider).delete(initial.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PickerField<String>(
              label: l10n.budgetFor,
              value: _target,
              options: [
                PickerOption(
                  _overall,
                  l10n.budgetOverall,
                  icon: Icons.all_inclusive_rounded,
                ),
                for (final c in Categories.selectable(
                  CategoryKind.expense,
                  includeArchived: true,
                ))
                  PickerOption(c.id, l10n.categoryLabel(c.id), icon: c.icon),
              ],
              onChanged: (v) => setState(() => _target = v ?? _target),
            ),
            const SizedBox(height: 12),
            AmountField(controller: _amount, label: l10n.budgetLimit),
            const SizedBox(height: 12),
            TextFormField(
              controller: _thresholds,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: l10n.budgetThresholds,
                helperText: l10n.budgetThresholdsHelp,
                suffixText: '%',
              ),
              validator: (v) => _parseThresholds(v ?? '') == null
                  ? l10n.budgetThresholdsInvalid
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
