import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/credit_cards/domain/credit_card.dart';
import 'package:expensetrackerpro/features/budgets/application/budget_providers.dart';
import 'package:expensetrackerpro/features/budgets/domain/budget.dart';
import 'package:expensetrackerpro/features/categories/domain/category.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/data/transaction_repository.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kinds the quick-entry form can create. Loan payments and borrow/lend
/// movements are created by their own modules so their records stay linked.
enum EntryKind { expense, income, transfer, cardPayment, refund }

/// A "where did the money go/come from" choice: an account, a card, or
/// neither (cash that isn't tracked).
sealed class _Source {
  const _Source();
}

class _AccountSource extends _Source {
  const _AccountSource(this.id);
  final String id;
  @override
  bool operator ==(Object other) => other is _AccountSource && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class _CardSource extends _Source {
  const _CardSource(this.id);
  final String id;
  @override
  bool operator ==(Object other) => other is _CardSource && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Add / edit / duplicate a transaction in a bottom sheet.
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({
    super.key,
    this.initial,
    this.duplicate = false,
    this.initialKind,
    this.presetCardId,
  });

  /// Transaction to edit (or to copy when [duplicate] is true).
  final Transaction? initial;
  final bool duplicate;
  final EntryKind? initialKind;

  /// Preselects a card, e.g. "Pay bill" from a card screen.
  final String? presetCardId;

  static Future<void> show(
    BuildContext context, {
    Transaction? initial,
    bool duplicate = false,
    EntryKind? kind,
    String? presetCardId,
  }) => showFormSheet(
    context,
    TransactionFormSheet(
      initial: initial,
      duplicate: duplicate,
      initialKind: kind,
      presetCardId: presetCardId,
    ),
  );

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late final TextEditingController _counterparty;
  late final TextEditingController _notes;
  late final TextEditingController _tags;

  late EntryKind _kind;
  late DateTime _date;
  late String _categoryId;
  String? _subCategoryId;
  _Source? _source;
  String? _toAccountId;
  bool _pending = false;
  String? _sourceError;
  String? _destinationError;

  bool get _isEdit => widget.initial != null && !widget.duplicate;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial;
    _amount = TextEditingController(
      text: tx == null ? '' : Money.toEditable(tx.amountMinor),
    );
    _description = TextEditingController(text: tx?.description ?? '');
    _counterparty = TextEditingController(text: tx?.counterparty ?? '');
    _notes = TextEditingController(text: tx?.notes ?? '');
    _tags = TextEditingController(text: tx?.tags.join(', ') ?? '');
    _kind = tx == null ? (widget.initialKind ?? EntryKind.expense) : _kindOf(tx.type);
    _date = widget.duplicate || tx == null ? DateTime.now() : tx.date;
    _pending = tx != null && !tx.isCleared;
    _categoryId = tx?.categoryId ?? _defaultCategory(_kind);
    _subCategoryId = tx?.subCategoryId;
    // Records from older versions may carry a category of the wrong kind;
    // fall back to the default instead of failing validation on save.
    final allowed = switch (_kind) {
      EntryKind.income => Categories.income,
      EntryKind.expense || EntryKind.refund => Categories.expense,
      _ => null,
    };
    if (allowed != null && !allowed.any((c) => c.id == _categoryId)) {
      _categoryId = _defaultCategory(_kind);
      _subCategoryId = null;
    }
    // For card payments the paying account sits in the second picker.
    _toAccountId = tx?.type == TransactionType.creditCardPayment
        ? tx?.accountId
        : tx?.toAccountId;
    if (tx?.creditCardId != null) {
      _source = _CardSource(tx!.creditCardId!);
    } else if (tx?.accountId != null) {
      _source = _AccountSource(tx!.accountId!);
    } else if (widget.presetCardId != null) {
      _source = _CardSource(widget.presetCardId!);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _counterparty.dispose();
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  static EntryKind _kindOf(TransactionType type) => switch (type) {
    TransactionType.income => EntryKind.income,
    TransactionType.transfer => EntryKind.transfer,
    TransactionType.creditCardPayment => EntryKind.cardPayment,
    TransactionType.refund => EntryKind.refund,
    _ => EntryKind.expense,
  };

  static String _defaultCategory(EntryKind kind) => switch (kind) {
    EntryKind.income => 'salary',
    EntryKind.transfer => Categories.transferId,
    EntryKind.cardPayment => Categories.cardPaymentId,
    _ => 'food',
  };

  void _setKind(EntryKind kind) {
    setState(() {
      _kind = kind;
      _categoryId = _defaultCategory(kind);
      _subCategoryId = null;
      _sourceError = null;
      _destinationError = null;
      // Cards cannot receive income or send transfers.
      if ((kind == EntryKind.income || kind == EntryKind.transfer) &&
          _source is _CardSource) {
        _source = null;
      }
      if (kind == EntryKind.cardPayment && _source is! _CardSource) {
        _source = null;
      }
    });
  }

  TransactionType get _type => switch (_kind) {
    EntryKind.expense =>
      _source is _CardSource
          ? TransactionType.creditCardExpense
          : TransactionType.expense,
    EntryKind.income => TransactionType.income,
    EntryKind.transfer => TransactionType.transfer,
    EntryKind.cardPayment => TransactionType.creditCardPayment,
    EntryKind.refund => TransactionType.refund,
  };

  Transaction _build(TransactionRepository repo) {
    final now = DateTime.now();
    final source = _source;
    String? accountId = source is _AccountSource ? source.id : null;
    String? cardId = source is _CardSource ? source.id : null;
    if (_kind == EntryKind.cardPayment) {
      // Source = card being paid; destination picker holds the paying account.
      accountId = _toAccountId;
    }
    final base = widget.initial;
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    return Transaction(
      id: _isEdit ? base!.id : repo.newId(),
      date: _date,
      amountMinor: Money.parse(_amount.text) ?? 0,
      type: _type,
      categoryId: _categoryId,
      subCategoryId: _subCategoryId,
      description: _description.text.trim(),
      counterparty: _counterparty.text.trim(),
      notes: _notes.text.trim(),
      tags: tags,
      accountId: accountId,
      toAccountId: _kind == EntryKind.transfer ? _toAccountId : null,
      creditCardId: cardId,
      recurringRuleId: _isEdit ? base!.recurringRuleId : null,
      status: _pending ? TransactionStatus.pending : TransactionStatus.cleared,
      createdAt: _isEdit ? base!.createdAt : now,
      updatedAt: now,
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() {
      _sourceError = null;
      _destinationError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(transactionRepositoryProvider);
    final tx = _build(repo);

    // Budget usage before saving, to warn when this entry crosses a limit.
    final month = Dates.monthOf(tx.date);
    final before = ref.read(monthlySummaryProvider(month)).value;
    final budgets = ref.read(budgetsProvider).value ?? const <Budget>[];
    final alerts = ref.read(settingsProvider).budgetAlerts;

    try {
      repo.save(tx, before: _isEdit ? widget.initial : null);
    } on TransactionValidationException catch (e) {
      setState(() {
        for (final issue in e.issues) {
          final message = l10n.issue(issue);
          if (issue.name.contains('destination') ||
              issue.name.contains('sameTransfer')) {
            _destinationError = message;
          } else {
            _sourceError = message;
          }
        }
      });
      return;
    }

    String? warning;
    if (alerts && before != null && tx.type.isSpending && tx.isCleared) {
      final oldAmount = _isEdit && widget.initial!.type.isSpending
          ? widget.initial!.amountMinor
          : 0;
      for (final budget in budgets.where((b) => b.enabled)) {
        if (!budget.isOverall && budget.categoryId != tx.categoryId) continue;
        final spent = budget.isOverall
            ? before.spending
            : before.byCategory[budget.categoryId] ?? 0;
        final crossed = BudgetCalculator.crossedThreshold(
          budget,
          spent,
          spent - oldAmount + tx.amountMinor,
        );
        if (crossed != null) {
          warning = l10n.budgetWarning(
            budget.isOverall
                ? l10n.budgetOverall
                : l10n.categoryLabel(budget.categoryId),
            '$crossed',
          );
        }
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    showMessage(context, warning ?? l10n.transactionSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Active accounts/cards, plus any archived one this transaction already
    // uses, so editing never misreports it as "Cash / not tracked".
    final keepIds = {
      if (_source case _AccountSource(:final id)) id,
      if (_source case _CardSource(:final id)) id,
      ?_toAccountId,
    };
    final accounts = (ref.watch(accountsProvider).value ?? const <Account>[])
        .where((a) => !a.archived || keepIds.contains(a.id))
        .toList();
    final cards = (ref.watch(cardsProvider).value ?? const <CreditCard>[])
        .where((c) => !c.archived || keepIds.contains(c.id))
        .toList();
    final title = _isEdit
        ? l10n.editTransaction
        : widget.duplicate
        ? l10n.duplicateTransaction
        : l10n.addTransaction;

    final accountOptions = [
      for (final a in accounts)
        PickerOption<_Source>(
          _AccountSource(a.id),
          a.displayName,
          icon: Icons.account_balance_rounded,
        ),
    ];
    final cardOptions = [
      for (final c in cards)
        PickerOption<_Source>(
          _CardSource(c.id),
          c.displayName,
          icon: Icons.credit_card_rounded,
        ),
    ];
    final accountIdOptions = [
      for (final a in accounts)
        PickerOption<String>(a.id, a.displayName, icon: Icons.account_balance_rounded),
    ];

    final categories = switch (_kind) {
      EntryKind.income => Categories.income,
      EntryKind.transfer || EntryKind.cardPayment => const <Category>[],
      _ => Categories.expense,
    };
    final selectedCategory = Categories.byId(_categoryId);

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            SegmentedButton<EntryKind>(
              segments: [
                ButtonSegment(value: EntryKind.expense, label: Text(l10n.txTypeExpense)),
                ButtonSegment(value: EntryKind.income, label: Text(l10n.txTypeIncome)),
                ButtonSegment(value: EntryKind.transfer, label: Text(l10n.txTypeTransfer)),
              ],
              selected: {
                if (_kind.index <= EntryKind.transfer.index) _kind,
              },
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                if (s.isNotEmpty) _setKind(s.first);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.txTypeCreditCardPayment),
                  selected: _kind == EntryKind.cardPayment,
                  onSelected: cards.isEmpty
                      ? null
                      : (_) => _setKind(EntryKind.cardPayment),
                ),
                ChoiceChip(
                  label: Text(l10n.txTypeRefund),
                  selected: _kind == EntryKind.refund,
                  onSelected: (_) => _setKind(EntryKind.refund),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AmountField(controller: _amount, autofocus: !_isEdit),
            const SizedBox(height: 12),
            if (accounts.isEmpty && cards.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.noAccountsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ..._sourceFields(l10n, accountOptions, cardOptions, accountIdOptions),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.category, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 18, color: c.color),
                      label: Text(l10n.categoryLabel(c.id)),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() {
                        _categoryId = c.id;
                        _subCategoryId = null;
                      }),
                    ),
                ],
              ),
              if (selectedCategory.subcategories.isNotEmpty &&
                  selectedCategory.id == _categoryId) ...[
                const SizedBox(height: 12),
                Text(l10n.subcategory, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in selectedCategory.subcategories)
                      FilterChip(
                        label: Text(l10n.categoryLabel(s.id)),
                        selected: _subCategoryId == s.id,
                        onSelected: (on) =>
                            setState(() => _subCategoryId = on ? s.id : null),
                      ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 16),
            DateField(
              label: l10n.date,
              value: _date,
              onChanged: (d) {
                if (d == null) return;
                setState(
                  () => _date = DateTime(
                    d.year,
                    d.month,
                    d.day,
                    _date.hour,
                    _date.minute,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _counterparty,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.merchantOrPerson),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.optional),
              children: [
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(labelText: l10n.notes),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tags,
                  decoration: InputDecoration(
                    labelText: l10n.tags,
                    hintText: l10n.tagsHint,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.markPending),
                  subtitle: Text(l10n.markPendingHelp),
                  value: _pending,
                  onChanged: (v) => setState(() => _pending = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sourceFields(
    AppLocalizations l10n,
    List<PickerOption<_Source>> accountOptions,
    List<PickerOption<_Source>> cardOptions,
    List<PickerOption<String>> accountIdOptions,
  ) {
    switch (_kind) {
      case EntryKind.expense:
      case EntryKind.refund:
        return [
          PickerField<_Source>(
            label: _kind == EntryKind.refund ? l10n.refundTo : l10n.paidWith,
            value: _source,
            options: [...accountOptions, ...cardOptions],
            allowNone: true,
            noneLabel: l10n.cashUntracked,
            errorText: _sourceError,
            onChanged: (v) => setState(() => _source = v),
          ),
        ];
      case EntryKind.income:
        return [
          PickerField<_Source>(
            label: l10n.receivedIn,
            value: _source,
            options: accountOptions,
            allowNone: true,
            noneLabel: l10n.cashUntracked,
            errorText: _sourceError,
            onChanged: (v) => setState(() => _source = v),
          ),
        ];
      case EntryKind.transfer:
        return [
          PickerField<_Source>(
            label: l10n.fromAccount,
            value: _source,
            options: accountOptions,
            errorText: _sourceError,
            onChanged: (v) => setState(() => _source = v),
          ),
          const SizedBox(height: 12),
          PickerField<String>(
            label: l10n.toAccount,
            value: _toAccountId,
            options: accountIdOptions,
            errorText: _destinationError,
            onChanged: (v) => setState(() => _toAccountId = v),
          ),
        ];
      case EntryKind.cardPayment:
        return [
          PickerField<_Source>(
            label: l10n.creditCard,
            value: _source,
            options: cardOptions,
            errorText: _sourceError,
            onChanged: (v) => setState(() => _source = v),
          ),
          const SizedBox(height: 12),
          PickerField<String>(
            label: l10n.fromAccount,
            value: _toAccountId,
            options: accountIdOptions,
            allowNone: true,
            noneLabel: l10n.cashUntracked,
            onChanged: (v) => setState(() => _toAccountId = v),
          ),
        ];
    }
  }
}
