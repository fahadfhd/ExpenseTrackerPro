import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/recurring/application/recurring_providers.dart';
import 'package:kept/features/recurring/domain/recurring_rule.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(customCategoriesProvider);
    final rules = ref.watch(recurringRulesProvider);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addRecurring),
        onPressed: () => pushPage(context, const RecurringFormScreen()),
      ),
      body: AsyncView<List<RecurringRule>>(
        value: rules,
        onRetry: () => ref.invalidate(recurringRulesProvider),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.recurringAutoNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (list.isEmpty)
              EmptyState(
                icon: Icons.repeat_rounded,
                message: l10n.recurringEmpty,
              ),
            for (final rule in list)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () =>
                      pushPage(context, RecurringFormScreen(initial: rule)),
                  leading: Icon(
                    Categories.byId(rule.categoryId).icon,
                    color: Categories.byId(rule.categoryId).color,
                  ),
                  title: Text(
                    rule.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      l10n.recurrence(rule.recurrence),
                      if (!rule.enabled)
                        l10n.recurringPaused
                      else if (rule.upcoming(now, count: 1).firstOrNull
                          case final next?)
                        l10n.recurringNext(
                          DateFormat.yMMMd(locale).format(next),
                        ),
                    ].join(' · '),
                  ),
                  trailing: MoneyText(
                    rule.amountMinor,
                    tone: rule.type == TransactionType.income
                        ? MoneyTone.positive
                        : MoneyTone.negative,
                    signed: rule.type != TransactionType.transfer,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key, this.initial});
  final RecurringRule? initial;

  @override
  ConsumerState<RecurringFormScreen> createState() =>
      _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.amountMinor),
  );
  late final _interval = TextEditingController(
    text: '${widget.initial?.recurrence.interval ?? 1}',
  );
  late TransactionType _type = widget.initial?.type ?? TransactionType.expense;
  late String _categoryId = widget.initial?.categoryId ?? 'bills';
  late String? _accountId = existingAccountId(ref, widget.initial?.accountId);
  late String? _toAccountId = existingAccountId(
    ref,
    widget.initial?.toAccountId,
  );
  late String? _cardId = widget.initial?.creditCardId;
  late DateTime _start = widget.initial?.startDate ?? DateTime.now();
  late RecurrenceFrequency _frequency =
      widget.initial?.recurrence.frequency ?? RecurrenceFrequency.monthly;
  late DateTime? _until = widget.initial?.recurrence.until;
  late bool _enabled = widget.initial?.enabled ?? true;
  String? _error;
  // Untracked cash was chosen explicitly (as opposed to nothing chosen yet).
  late bool _cashChosen =
      widget.initial != null &&
      widget.initial!.accountId == null &&
      widget.initial!.creditCardId == null;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _interval.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_type == TransactionType.creditCardExpense && _cardId == null) {
      setState(() => _error = l10n.issueCardRequired);
      return;
    }
    if (_type != TransactionType.transfer &&
        _type != TransactionType.creditCardExpense &&
        _accountId == null &&
        !_cashChosen &&
        ref.read(activeAccountsProvider).isNotEmpty) {
      setState(() => _error = l10n.paymentRequired);
      return;
    }
    if (_type == TransactionType.transfer &&
        (_accountId == null ||
            _toAccountId == null ||
            _accountId == _toAccountId)) {
      setState(() => _error = l10n.issueSameTransferAccounts);
      return;
    }
    final repo = ref.read(recurringRepositoryProvider);
    final now = DateTime.now();
    final recurrence = Recurrence(
      frequency: _frequency,
      interval: int.tryParse(_interval.text)?.clamp(1, 365) ?? 1,
      until: _until,
    );
    final initial = widget.initial;
    final category = _type == TransactionType.transfer
        ? Categories.transferId
        : _categoryId;
    final rule = initial == null
        ? RecurringRule(
            id: repo.newId(),
            title: _title.text.trim(),
            type: _type,
            amountMinor: Money.parse(_amount.text)!,
            categoryId: category,
            accountId: _accountId,
            toAccountId: _toAccountId,
            creditCardId: _cardId,
            startDate: _start,
            recurrence: recurrence,
            enabled: _enabled,
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            title: _title.text.trim(),
            type: _type,
            amountMinor: Money.parse(_amount.text)!,
            categoryId: category,
            accountId: () => _accountId,
            toAccountId: () => _toAccountId,
            creditCardId: () => _cardId,
            startDate: _start,
            recurrence: recurrence,
            enabled: _enabled,
            updatedAt: now,
          );
    repo.save(rule);
    Navigator.pop(context);
    showMessage(context, l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider);
    final cards = ref.watch(activeCardsProvider);
    final categories = _type == TransactionType.income
        ? Categories.selectable(CategoryKind.income)
        : Categories.selectable(CategoryKind.expense);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? l10n.addRecurring : l10n.editRecurring,
        ),
        actions: [
          if (widget.initial != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (!await confirmDelete(context, widget.initial!.title)) {
                  return;
                }
                ref
                    .read(recurringRepositoryProvider)
                    .delete(widget.initial!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in RecurringRule.allowedTypes)
                  ChoiceChip(
                    label: Text(l10n.transactionType(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      _type = t;
                      _categoryId = t == TransactionType.income
                          ? 'salary'
                          : 'bills';
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.recurringTitleLabel,
                hintText: l10n.recurringTitleHint,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            AmountField(controller: _amount),
            const SizedBox(height: 12),
            if (_type != TransactionType.transfer) ...[
              PickerField<String>(
                label: l10n.category,
                value: _categoryId,
                options: [
                  for (final c in categories)
                    PickerOption(c.id, l10n.categoryLabel(c.id), icon: c.icon),
                ],
                onChanged: (v) =>
                    setState(() => _categoryId = v ?? _categoryId),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == TransactionType.creditCardExpense)
              PaymentSourceField(
                label: l10n.creditCard,
                value: _cardId == null ? null : CardSource(_cardId!),
                cards: cards,
                allowCash: false,
                errorText: _error,
                onChanged: (v) => setState(() {
                  _cardId = v?.cardId;
                  _error = null;
                }),
              )
            else
              PaymentSourceField(
                label: _type == TransactionType.income
                    ? l10n.receivedIn
                    : _type == TransactionType.transfer
                    ? l10n.fromAccount
                    : l10n.paidWith,
                value: _accountId != null
                    ? AccountSource(_accountId!)
                    : (_cashChosen ? const CashSource() : null),
                accounts: accounts,
                allowCash: _type != TransactionType.transfer,
                errorText: _error,
                onChanged: (v) => setState(() {
                  _accountId = v?.accountId;
                  _cashChosen = v is CashSource;
                  if (_toAccountId == _accountId) _toAccountId = null;
                  _error = null;
                }),
              ),
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 12),
              PaymentSourceField(
                label: l10n.toAccount,
                value: _toAccountId == null
                    ? null
                    : AccountSource(_toAccountId!),
                accounts: [
                  for (final a in accounts)
                    if (a.id != _accountId) a,
                ],
                allowCash: false,
                onChanged: (v) => setState(() => _toAccountId = v?.accountId),
              ),
            ],
            const SizedBox(height: 16),
            DateField(
              label: l10n.startsOn,
              value: _start,
              onChanged: (d) => setState(() => _start = d ?? _start),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final f in RecurrenceFrequency.values.where(
                  (f) => f != RecurrenceFrequency.once,
                ))
                  ChoiceChip(
                    label: Text(l10n.frequency(f)),
                    selected: _frequency == f,
                    onSelected: (_) => setState(() => _frequency = f),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _interval,
                    label: l10n.reminderEvery,
                    integer: true,
                    min: 1,
                    max: 365,
                    helper: l10n.recurrence(
                      Recurrence(
                        frequency: _frequency,
                        interval: int.tryParse(_interval.text) ?? 1,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateField(
                    label: l10n.reminderUntil,
                    value: _until,
                    clearable: true,
                    onChanged: (d) => setState(() => _until = d),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _enabled ? l10n.recurringActive : l10n.recurringPaused,
              ),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 12),
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
