import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/core/utils/haptics.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/accounts/domain/account.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/budgets/application/budget_providers.dart';
import 'package:kept/features/budgets/domain/budget.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/categories/presentation/category_editor_sheet.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';

/// Kinds the quick-entry form can create. Loan payments and borrow/lend
/// movements are created by their own modules so their records stay linked.
///
/// [repayBorrow] closes (part of) money borrowed from a person: it is saved
/// as a settlement on that borrow, which records the repayment itself.
enum EntryKind { expense, income, transfer, cardPayment, refund, repayBorrow }

/// Add / edit / duplicate a transaction in a bottom sheet.
class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({
    super.key,
    this.initial,
    this.duplicate = false,
    this.initialKind,
    this.presetCardId,
    this.presetAccountId,
  });

  /// Transaction to edit (or to copy when [duplicate] is true).
  final Transaction? initial;
  final bool duplicate;
  final EntryKind? initialKind;

  /// Preselect a card or account, e.g. "Add expense" from its own screen.
  final String? presetCardId;
  final String? presetAccountId;

  static Future<void> show(
    BuildContext context, {
    Transaction? initial,
    bool duplicate = false,
    EntryKind? kind,
    String? presetCardId,
    String? presetAccountId,
  }) => showFormSheet(
    context,
    TransactionFormSheet(
      initial: initial,
      duplicate: duplicate,
      initialKind: kind,
      presetCardId: presetCardId,
      presetAccountId: presetAccountId,
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

  /// Null until the user picks one: nothing is silently preselected, and
  /// tapping the selected chip again clears it.
  String? _categoryId;
  String? _subCategoryId;

  /// The main payment choice: paid with / received in / refund to / transfer
  /// from / the card being paid. Null = not chosen yet.
  PaymentSource? _source;

  /// Transfer destination, or the account a card bill is paid from.
  PaymentSource? _second;

  /// The borrow being repaid (repay-a-borrow entries only).
  String? _borrowId;
  bool _moreTypes = false;
  bool _allCategories = false;
  String? _borrowError;
  bool _pending = false;
  String? _categoryError;
  String? _sourceError;
  String? _secondError;

  bool get _isEdit => widget.initial != null && !widget.duplicate;

  /// Whether leaving now would lose input.
  bool _isDirty() {
    final tx = widget.initial;
    String t(TextEditingController c) => c.text.trim();
    if (tx == null || widget.duplicate) {
      return [
        _amount,
        _description,
        _counterparty,
        _notes,
        _tags,
      ].any((c) => t(c).isNotEmpty);
    }
    return Money.parse(_amount.text) != tx.amountMinor ||
        t(_description) != tx.description ||
        t(_counterparty) != tx.counterparty ||
        t(_notes) != tx.notes;
  }

  /// Same day-of-month change as picking a date, keeping the time of day.
  void _setDay(DateTime d) => setState(
    () => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute),
  );

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
    _kind = tx == null
        ? (widget.initialKind ?? EntryKind.expense)
        : _kindOf(tx.type);
    _moreTypes = _kind.index > EntryKind.transfer.index;
    _date = widget.duplicate || tx == null ? DateTime.now() : tx.date;
    _pending = tx != null && !tx.isCleared;

    if (tx != null) {
      // Keep the stored category only if it still fits this kind of entry
      // (older versions could save a mismatched one).
      final kind = _categoryKind(_kind);
      if (kind == null || Categories.byId(tx.categoryId).kind == kind) {
        _categoryId = tx.categoryId;
        _subCategoryId = tx.subCategoryId;
      }
      _initSources(tx);
    } else if (widget.presetCardId != null) {
      _source = CardSource(widget.presetCardId!);
    } else if (widget.presetAccountId != null) {
      _source = AccountSource(widget.presetAccountId!);
    }
  }

  void _initSources(Transaction tx) {
    PaymentSource ofTx() => tx.creditCardId != null
        ? CardSource(tx.creditCardId!)
        : tx.accountId != null
        ? AccountSource(tx.accountId!)
        : const CashSource();
    switch (tx.type) {
      case TransactionType.transfer:
        _source = tx.accountId == null ? null : AccountSource(tx.accountId!);
        _second = tx.toAccountId == null
            ? null
            : AccountSource(tx.toAccountId!);
      case TransactionType.creditCardPayment:
        _source = tx.creditCardId == null ? null : CardSource(tx.creditCardId!);
        _second = tx.accountId == null
            ? const CashSource()
            : AccountSource(tx.accountId!);
      default:
        _source = ofTx();
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

  /// Which category list a kind of entry uses; null when the category is
  /// fixed by the system (transfers and card bills).
  static CategoryKind? _categoryKind(EntryKind kind) => switch (kind) {
    EntryKind.income => CategoryKind.income,
    EntryKind.expense || EntryKind.refund => CategoryKind.expense,
    _ => null,
  };

  /// Switches the kind, keeping whatever is still valid (category, payment
  /// source) so toggling doesn't make the user start over.
  void _setKind(EntryKind kind) {
    setState(() {
      final oldCategoryKind = _categoryKind(_kind);
      _kind = kind;
      if (_categoryKind(kind) != oldCategoryKind) {
        _categoryId = null;
        _subCategoryId = null;
      }
      _categoryError = _sourceError = _secondError = null;
      switch (kind) {
        case EntryKind.income:
          // Money can't be received on a card.
          if (_source is CardSource) _source = null;
        case EntryKind.transfer:
          if (_source is! AccountSource) _source = null;
          _second = _second is AccountSource ? _second : null;
        case EntryKind.cardPayment:
          if (_source is! CardSource) _source = null;
          _second = _second is CardSource ? null : _second;
        case EntryKind.expense || EntryKind.refund:
          if (_second != null) _second = null;
        case EntryKind.repayBorrow:
          // Repayments leave from an account or cash, never a card.
          if (_source is CardSource) _source = null;
          _second = null;
      }
      _borrowError = null;
    });
  }

  TransactionType get _type => switch (_kind) {
    EntryKind.expense =>
      _source is CardSource
          ? TransactionType.creditCardExpense
          : TransactionType.expense,
    EntryKind.income => TransactionType.income,
    EntryKind.transfer => TransactionType.transfer,
    EntryKind.cardPayment => TransactionType.creditCardPayment,
    EntryKind.refund => TransactionType.refund,
    EntryKind.repayBorrow => TransactionType.debtRepayment,
  };

  Transaction _build(TransactionRepository repo) {
    final now = DateTime.now();
    final base = widget.initial;
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    final categoryId = switch (_kind) {
      EntryKind.transfer => Categories.transferId,
      EntryKind.cardPayment => Categories.cardPaymentId,
      _ => _categoryId!,
    };
    final isCardPayment = _kind == EntryKind.cardPayment;
    return Transaction(
      id: _isEdit ? base!.id : repo.newId(),
      date: _date,
      amountMinor: Money.parse(_amount.text) ?? 0,
      type: _type,
      categoryId: categoryId,
      subCategoryId: _subCategoryId,
      description: _description.text.trim(),
      counterparty: _counterparty.text.trim(),
      notes: _notes.text.trim(),
      tags: tags,
      // For a card bill the main choice is the card and the paying account
      // is the second choice.
      accountId: isCardPayment ? _second?.accountId : _source?.accountId,
      toAccountId: _kind == EntryKind.transfer ? _second?.accountId : null,
      creditCardId: _source?.cardId,
      recurringRuleId: _isEdit ? base!.recurringRuleId : null,
      status: _pending ? TransactionStatus.pending : TransactionStatus.cleared,
      createdAt: _isEdit ? base!.createdAt : now,
      updatedAt: now,
    );
  }

  /// Checks the choices a plain `FormField` can't (category, payment).
  /// Returns whether everything is valid, filling the inline errors.
  bool _validateChoices({required bool hasSources}) {
    final l10n = context.l10n;
    String? category, source, second;
    if (_categoryKind(_kind) != null && _categoryId == null) {
      category = l10n.categoryRequired;
    }
    // With no accounts or cards at all, untracked cash is the only option
    // and is applied automatically.
    if (hasSources) {
      switch (_kind) {
        case EntryKind.expense || EntryKind.refund:
          source = _source == null ? l10n.paymentRequired : null;
        case EntryKind.income:
          source = _source == null ? l10n.receivedRequired : null;
        case EntryKind.transfer:
          source = _source is AccountSource
              ? null
              : l10n.issueSourceAccountRequired;
          if (_second is! AccountSource) {
            second = l10n.issueDestinationAccountRequired;
          } else if (_second == _source) {
            second = l10n.issueSameTransferAccounts;
          }
        case EntryKind.cardPayment:
          source = _source is CardSource ? null : l10n.issueCardRequired;
          second = _second == null ? l10n.paymentRequired : null;
        case EntryKind.repayBorrow:
          break; // validated by _saveRepayment
      }
    } else if (_kind == EntryKind.transfer) {
      source = l10n.issueSourceAccountRequired;
      second = l10n.issueDestinationAccountRequired;
    } else if (_kind == EntryKind.cardPayment) {
      source = l10n.issueCardRequired;
    }
    setState(() {
      _categoryError = category;
      _sourceError = source;
      _secondError = second;
    });
    return category == null && source == null && second == null;
  }

  /// Repaying a borrow is saved as a settlement on it (which also records
  /// the repayment transaction and updates the due-date reminder).
  void _saveRepayment(List<DebtRecord> open, {required bool hasAccounts}) {
    final l10n = context.l10n;
    final record = open.where((r) => r.id == _borrowId).firstOrNull;
    final amount = Money.parse(_amount.text);
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _borrowError = record == null ? l10n.repayWhich : null;
      _sourceError = hasAccounts && _source == null
          ? l10n.paymentRequired
          : null;
    });
    if (!formOk ||
        record == null ||
        amount == null ||
        (hasAccounts && _source == null)) {
      return;
    }
    final repo = ref.read(debtRepositoryProvider);
    final settlement = Settlement(
      id: repo.newId(),
      amountMinor: amount,
      date: _date,
      note: _notes.text.trim(),
      accountId: _source?.accountId,
    );
    repo.addSettlement(record, settlement);
    ref
        .read(entityRemindersProvider)
        .syncDebt(
          record.copyWith(settlements: [...record.settlements, settlement]),
        );
    Haptics.success();
    Navigator.pop(context);
    showMessage(context, l10n.saved);
  }

  Future<void> _save({required bool hasSources}) async {
    final l10n = context.l10n;
    final formOk = _formKey.currentState!.validate();
    final choicesOk = _validateChoices(hasSources: hasSources);
    if (!formOk || !choicesOk) return;
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
            _secondError = message;
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
        if (!budget.isOverall && budget.categoryId != tx.categoryId) {
          continue;
        }
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
    Haptics.success();
    Navigator.pop(context);
    showMessage(context, warning ?? l10n.transactionSaved);
  }

  Future<void> _newCategory(CategoryKind kind) async {
    final created = await CategoryEditorSheet.show(context, kind: kind);
    if (created != null && mounted) {
      setState(() {
        _categoryId = created;
        _subCategoryId = null;
        _categoryError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Rebuild when the user's own categories change.
    ref.watch(customCategoriesProvider);

    // Active accounts/cards, plus any archived one already chosen, so
    // editing never misreports it as untracked cash.
    final keepIds = {
      ?_source?.accountId,
      ?_source?.cardId,
      ?_second?.accountId,
    };
    final allAccounts = (ref.watch(accountsProvider).value ?? const <Account>[])
        .where((a) => !a.archived || keepIds.contains(a.id))
        .toList();
    final allCards = (ref.watch(cardsProvider).value ?? const <CreditCard>[])
        .where((c) => !c.archived || keepIds.contains(c.id))
        .toList();
    final hasSources = allAccounts.isNotEmpty || allCards.isNotEmpty;
    final repaying = _kind == EntryKind.repayBorrow;
    final openBorrows = [
      for (final r in ref.watch(debtsProvider).value ?? const <DebtRecord>[])
        if (r.direction == DebtDirection.borrowed && !r.isSettled) r,
    ];
    final borrow = openBorrows.where((r) => r.id == _borrowId).firstOrNull;

    final title = _isEdit
        ? l10n.editTransaction
        : widget.duplicate
        ? l10n.duplicateTransaction
        : l10n.addTransaction;

    final categoryKind = _categoryKind(_kind);
    final categories = categoryKind == null
        ? const <Category>[]
        : Categories.selectable(categoryKind);
    // An archived category already on this entry stays visible.
    final shown = [
      ...categories,
      if (_categoryId != null &&
          categoryKind != null &&
          !categories.any((c) => c.id == _categoryId))
        Categories.byId(_categoryId),
    ];
    // A short list first; "More" shows the rest. A chosen category is
    // always visible.
    const firstCategories = 8;
    final visibleCategories =
        _allCategories || shown.length <= firstCategories + 1
        ? shown
        : [
            ...shown.take(firstCategories),
            ...shown.skip(firstCategories).where((c) => c.id == _categoryId),
          ];
    final selectedCategory = _categoryId == null
        ? null
        : Categories.byId(_categoryId);

    final cardChip = ChoiceChip(
      label: Text(l10n.txTypeCreditCardPayment),
      selected: _kind == EntryKind.cardPayment,
      // Tapping the selected chip goes back to a normal expense.
      onSelected: allCards.isEmpty
          ? null
          : (on) => _setKind(on ? EntryKind.cardPayment : EntryKind.expense),
    );
    final refundChip = ChoiceChip(
      label: Text(l10n.txTypeRefund),
      selected: _kind == EntryKind.refund,
      onSelected: (on) => _setKind(on ? EntryKind.refund : EntryKind.expense),
    );

    final repayChip = ChoiceChip(
      label: Text(l10n.txTypeRepayBorrow),
      selected: repaying,
      onSelected: (on) =>
          _setKind(on ? EntryKind.repayBorrow : EntryKind.expense),
    );

    Widget? paymentSection;
    switch (_kind) {
      case EntryKind.expense:
        paymentSection = PaymentSourceField(
          label: l10n.paidWith,
          value: _source,
          accounts: allAccounts,
          cards: allCards,
          errorText: _sourceError,
          onChanged: (v) => setState(() {
            _source = v;
            _sourceError = null;
          }),
        );
      case EntryKind.refund:
        paymentSection = PaymentSourceField(
          label: l10n.refundTo,
          value: _source,
          accounts: allAccounts,
          cards: allCards,
          errorText: _sourceError,
          onChanged: (v) => setState(() {
            _source = v;
            _sourceError = null;
          }),
        );
      case EntryKind.income:
        paymentSection = PaymentSourceField(
          label: l10n.receivedIn,
          value: _source,
          accounts: allAccounts,
          errorText: _sourceError,
          onChanged: (v) => setState(() {
            _source = v;
            _sourceError = null;
          }),
        );
      case EntryKind.transfer:
        paymentSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaymentSourceField(
              label: l10n.fromAccount,
              value: _source,
              accounts: allAccounts,
              allowCash: false,
              errorText: _sourceError,
              onChanged: (v) => setState(() {
                _source = v;
                _sourceError = null;
                // The destination can't be the source.
                if (_second == v) _second = null;
              }),
            ),
            const SizedBox(height: 12),
            PaymentSourceField(
              label: l10n.toAccount,
              value: _second,
              accounts: [
                for (final a in allAccounts)
                  if (AccountSource(a.id) != _source) a,
              ],
              allowCash: false,
              errorText: _secondError,
              onChanged: (v) => setState(() {
                _second = v;
                _secondError = null;
              }),
            ),
          ],
        );
      case EntryKind.repayBorrow:
        paymentSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.repayWhich,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in openBorrows)
                  ChoiceChip(
                    label: Text(
                      '${r.personName} · ${l10n.repayLeft(ref.watch(currencyFormatterProvider).format(r.outstandingMinor))}',
                    ),
                    showCheckmark: false,
                    selected: _borrowId == r.id,
                    onSelected: (on) => setState(() {
                      Haptics.selection();
                      _borrowId = on ? r.id : null;
                      _borrowError = null;
                      // Start from the full amount still owed.
                      if (on && _amount.text.trim().isEmpty) {
                        _amount.text = Money.toEditable(r.outstandingMinor);
                      }
                    }),
                  ),
              ],
            ),
            if (_borrowError != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _borrowError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            PaymentSourceField(
              label: l10n.paidWith,
              value: _source,
              accounts: allAccounts,
              errorText: _sourceError,
              onChanged: (v) => setState(() {
                _source = v;
                _sourceError = null;
              }),
            ),
          ],
        );
      case EntryKind.cardPayment:
        paymentSection = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaymentSourceField(
              label: l10n.creditCard,
              value: _source,
              cards: allCards,
              allowCash: false,
              errorText: _sourceError,
              onChanged: (v) => setState(() {
                _source = v;
                _sourceError = null;
              }),
            ),
            const SizedBox(height: 12),
            PaymentSourceField(
              label: l10n.paymentPayingAccount,
              value: _second,
              accounts: allAccounts,
              errorText: _secondError,
              onChanged: (v) => setState(() {
                _second = v;
                _secondError = null;
              }),
            ),
          ],
        );
    }

    return UnsavedChangesGuard(
      isDirty: _isDirty,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<EntryKind>(
                      segments: [
                        ButtonSegment(
                          value: EntryKind.expense,
                          label: Text(l10n.txTypeExpense),
                        ),
                        ButtonSegment(
                          value: EntryKind.income,
                          label: Text(l10n.txTypeIncome),
                        ),
                        ButtonSegment(
                          value: EntryKind.transfer,
                          label: Text(l10n.txTypeTransfer),
                        ),
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
                      runSpacing: 8,
                      children: [
                        // The rarer kinds stay out of sight until asked for.
                        if (_moreTypes ||
                            _kind.index > EntryKind.transfer.index) ...[
                          cardChip,
                          refundChip,
                          if (openBorrows.isNotEmpty || repaying) repayChip,
                        ] else
                          ActionChip(
                            avatar: const Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                            ),
                            label: Text(l10n.moreTypes),
                            onPressed: () => setState(() => _moreTypes = true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AmountField(
                      controller: _amount,
                      autofocus: !_isEdit,
                      maxMinor: borrow?.outstandingMinor,
                    ),
                    const SizedBox(height: 16),
                    if (!hasSources && !repaying)
                      Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.paymentNoneYet,
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.account_balance_rounded,
                                    ),
                                    label: Text(l10n.addAccount),
                                    onPressed: () =>
                                        AppRoutes.newAccount(context),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.credit_card_rounded),
                                    label: Text(l10n.addCard),
                                    onPressed: () => AppRoutes.newCard(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      paymentSection,
                    if (categoryKind != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.category,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (_categoryId != null)
                            TextButton(
                              onPressed: () => setState(() {
                                _categoryId = null;
                                _subCategoryId = null;
                              }),
                              child: Text(l10n.clear),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in visibleCategories)
                            ChoiceChip(
                              avatar: Icon(c.icon, size: 18, color: c.color),
                              label: Text(l10n.categoryLabel(c.id)),
                              selected: _categoryId == c.id,
                              // Tapping the selected chip clears it.
                              onSelected: (on) => setState(() {
                                Haptics.selection();
                                _categoryId = on ? c.id : null;
                                _subCategoryId = null;
                                _categoryError = null;
                              }),
                            ),
                          if (visibleCategories.length < shown.length)
                            ActionChip(
                              avatar: const Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                              ),
                              label: Text(l10n.moreCategories),
                              onPressed: () =>
                                  setState(() => _allCategories = true),
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.categoryNew),
                            onPressed: () => _newCategory(categoryKind),
                          ),
                        ],
                      ),
                      if (_categoryError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 6),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _categoryError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      if (selectedCategory != null &&
                          selectedCategory.subcategories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.subcategory,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in selectedCategory.subcategories)
                              FilterChip(
                                label: Text(l10n.categoryLabel(s.id)),
                                selected: _subCategoryId == s.id,
                                onSelected: (on) => setState(
                                  () => _subCategoryId = on ? s.id : null,
                                ),
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
                        if (d == null) {
                          return;
                        }
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.today),
                          selected: Dates.sameDay(_date, DateTime.now()),
                          onSelected: (_) {
                            Haptics.selection();
                            _setDay(DateTime.now());
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.yesterday),
                          selected: Dates.sameDay(
                            _date,
                            DateTime.now().subtract(const Duration(days: 1)),
                          ),
                          onSelected: (_) {
                            Haptics.selection();
                            _setDay(
                              DateTime.now().subtract(const Duration(days: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (repaying)
                      TextFormField(
                        controller: _notes,
                        decoration: InputDecoration(labelText: l10n.notes),
                      ),
                    if (!repaying) ...[
                      TextFormField(
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l10n.description,
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        // An entry with details already filled in shows them.
                        initiallyExpanded:
                            _isEdit &&
                            (_counterparty.text.isNotEmpty ||
                                _notes.text.isNotEmpty ||
                                _tags.text.isNotEmpty ||
                                _pending),
                        title: Text(l10n.moreDetails),
                        children: [
                          TextFormField(
                            controller: _counterparty,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: l10n.merchantOrPerson,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                    ],
                  ],
                ),
              ),
              // Pinned, so saving never needs a scroll to the end.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => repaying
                      ? _saveRepayment(
                          openBorrows,
                          hasAccounts: allAccounts.isNotEmpty,
                        )
                      : _save(hasSources: hasSources),
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
