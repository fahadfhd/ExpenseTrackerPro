import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';

/// Add or edit a credit card.
///
/// Deliberately short: card name, credit limit, current outstanding and the
/// payment due date. The statement day is worked out from the due date, and
/// everything else (bank, last 4 digits, minimum-due %, the account the bill
/// is paid from, notes) is optional and tucked away.
class CardFormScreen extends ConsumerStatefulWidget {
  const CardFormScreen({super.key, this.initial});

  final CreditCard? initial;

  @override
  ConsumerState<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _bank = TextEditingController(text: widget.initial?.bankName);
  late final _last4 = TextEditingController(text: widget.initial?.last4);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late final _limit = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.creditLimitMinor),
  );
  late final _outstanding = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.openingOutstandingMinor),
  );
  late final _minPercent = TextEditingController(
    text: '${widget.initial?.minimumDuePercent ?? 5}',
  );
  late final _annualRate = TextEditingController(
    text: widget.initial?.annualRatePercent?.toString() ?? '',
  );

  /// The next payment due date; only its day of month is stored.
  late DateTime? _dueDate = widget.initial?.nextDueDate(DateTime.now());
  late PaymentSource? _linked = widget.initial?.linkedAccountId == null
      ? null
      : paymentFor(ref, widget.initial!.linkedAccountId, known: false);
  bool _dueMissing = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _bank,
      _last4,
      _notes,
      _limit,
      _outstanding,
      _minPercent,
      _annualRate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _dueMissing = _dueDate == null);
    if (!formOk || _dueDate == null) return;
    final repo = ref.read(creditCardRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final limit = Money.parse(_limit.text) ?? 0;
    final outstanding = Money.parse(_outstanding.text) ?? 0;
    final dueDay = _dueDate!.day;
    // Keep an existing statement day unless the due day changed.
    final statementDay = initial != null && initial.dueDay == dueDay
        ? initial.statementDay
        : CreditCard.defaultStatementDay(dueDay);
    final minPercent = NumberField.parse(_minPercent.text) ?? 5;
    final annualRate = NumberField.parse(_annualRate.text);
    final card = initial == null
        ? CreditCard(
            id: repo.newId(),
            name: _name.text.trim(),
            bankName: _bank.text.trim(),
            last4: _last4.text.trim(),
            creditLimitMinor: limit,
            openingOutstandingMinor: outstanding,
            statementDay: statementDay,
            dueDay: dueDay,
            minimumDuePercent: minPercent,
            annualRatePercent: annualRate,
            linkedAccountId: _linked?.accountId,
            notes: _notes.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            name: _name.text.trim(),
            bankName: _bank.text.trim(),
            last4: _last4.text.trim(),
            creditLimitMinor: limit,
            openingOutstandingMinor: outstanding,
            statementDay: statementDay,
            dueDay: dueDay,
            minimumDuePercent: minPercent,
            annualRatePercent: () => annualRate,
            linkedAccountId: () => _linked?.accountId,
            notes: _notes.text.trim(),
            updatedAt: now,
          );
    repo.save(card);
    ref.read(entityRemindersProvider).syncCard(card);
    Navigator.pop(context);
    showMessage(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(activeAccountsProvider);
    final isEdit = widget.initial != null;

    // Ask before discarding a half-filled new entry.
    return UnsavedChangesGuard(
      isDirty: () =>
          widget.initial == null &&
          (_name.text.trim().isNotEmpty ||
              _limit.text.trim().isNotEmpty ||
              _outstanding.text.trim().isNotEmpty),
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? l10n.editCard : l10n.newCard)),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                autofocus: !isEdit,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.cardName,
                  hintText: l10n.cardNameHint,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
              ),
              const SizedBox(height: 12),
              AmountField(controller: _limit, label: l10n.creditLimit),
              const SizedBox(height: 12),
              // When editing, this field is the *starting* outstanding; the
              // live figure adds every card transaction on top. Labelling it
              // "current" invited users to enter a total that got
              // double-counted.
              AmountField(
                controller: _outstanding,
                label: isEdit
                    ? l10n.outstandingWhenAdded
                    : l10n.currentOutstanding,
                required: false,
                allowZero: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Text(
                  !isEdit
                      ? l10n.currentOutstandingHelp
                      : l10n.outstandingWhenAddedHelp(
                          ref
                              .watch(currencyFormatterProvider)
                              .format(
                                ref
                                        .watch(
                                          cardsByIdProvider,
                                        )[widget.initial!.id]
                                        ?.outstandingMinor ??
                                    widget.initial!.outstandingMinor,
                              ),
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              DateField(
                label: l10n.cardDueDate,
                value: _dueDate,
                onChanged: (d) => setState(() {
                  _dueDate = d;
                  _dueMissing = false;
                }),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 366)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Text(
                  _dueMissing ? l10n.cardDueDateRequired : l10n.cardDueDateHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _dueMissing ? theme.colorScheme.error : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.cardMoreDetails),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  TextFormField(
                    controller: _bank,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.bankName),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _last4,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.last4,
                      helperText: l10n.last4Help,
                      counterText: '',
                    ),
                    validator: (v) {
                      final text = (v ?? '').trim();
                      return text.isEmpty ||
                              CreditCard.last4Pattern.hasMatch(text)
                          ? null
                          : l10n.last4Invalid;
                    },
                  ),
                  const SizedBox(height: 12),
                  NumberField(
                    controller: _minPercent,
                    label: l10n.minimumDuePercent,
                    suffix: '%',
                    min: 0,
                    max: 100,
                    helper: l10n.minimumDuePercentHelp,
                  ),
                  const SizedBox(height: 12),
                  NumberField(
                    controller: _annualRate,
                    label: l10n.cardAnnualRate,
                    suffix: '%',
                    min: 0,
                    max: 100,
                    required: false,
                    helper: l10n.cardAnnualRateHelp,
                  ),
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PaymentSourceField(
                      label: l10n.linkedAccount,
                      value: _linked,
                      accounts: accounts,
                      allowCash: false,
                      onChanged: (v) => setState(() => _linked = v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(labelText: l10n.notes),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(
                  l10n.noCredentialsNote,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
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
      ),
    );
  }
}
