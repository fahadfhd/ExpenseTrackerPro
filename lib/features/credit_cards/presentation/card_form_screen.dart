import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/credit_cards/domain/credit_card.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    text: widget.initial == null ? '' : Money.toEditable(widget.initial!.creditLimitMinor),
  );
  late final _outstanding = TextEditingController(
    text: widget.initial == null ? '' : Money.toEditable(widget.initial!.openingOutstandingMinor),
  );
  late final _statementDay = TextEditingController(text: '${widget.initial?.statementDay ?? ''}');
  late final _dueDay = TextEditingController(text: '${widget.initial?.dueDay ?? ''}');
  late final _minPercent = TextEditingController(
    text: '${widget.initial?.minimumDuePercent ?? 5}',
  );
  late String? _linkedAccountId = existingAccountId(ref, widget.initial?.linkedAccountId);

  @override
  void dispose() {
    for (final c in [_name, _bank, _last4, _notes, _limit, _outstanding, _statementDay, _dueDay, _minPercent]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(creditCardRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final limit = Money.parse(_limit.text) ?? 0;
    final outstanding = Money.parse(_outstanding.text) ?? 0;
    final statementDay = int.parse(_statementDay.text);
    final dueDay = int.parse(_dueDay.text);
    final minPercent = NumberField.parse(_minPercent.text) ?? 5;
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
            linkedAccountId: _linkedAccountId,
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
            linkedAccountId: () => _linkedAccountId,
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
    final accounts = ref.watch(activeAccountsProvider);
    String? dayValidator(String? v) {
      final n = int.tryParse(v ?? '');
      return n == null || n < 1 || n > 31 ? l10n.dayInvalid : null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? l10n.newCard : l10n.editCard)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.initial == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.cardName, hintText: l10n.cardNameHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bank,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.bankName),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    controller: _last4,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.last4, counterText: ''),
                    validator: (v) {
                      final text = (v ?? '').trim();
                      return text.isEmpty || CreditCard.last4Pattern.hasMatch(text)
                          ? null
                          : l10n.last4Invalid;
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(l10n.last4Help, style: Theme.of(context).textTheme.bodySmall),
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
              label: widget.initial == null ? l10n.currentOutstanding : l10n.outstandingWhenAdded,
              required: false,
              allowZero: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(
                widget.initial == null
                    ? l10n.currentOutstandingHelp
                    : l10n.outstandingWhenAddedHelp(
                        ref.watch(currencyFormatterProvider).format(
                          ref.watch(cardsByIdProvider)[widget.initial!.id]?.outstandingMinor ??
                              widget.initial!.outstandingMinor,
                        ),
                      ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _statementDay,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.statementDay, helperText: l10n.dayOfMonth),
                    validator: dayValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dueDay,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.dueDay, helperText: l10n.dayOfMonth),
                    validator: dayValidator,
                  ),
                ),
              ],
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
            PickerField<String>(
              label: l10n.linkedAccount,
              value: _linkedAccountId,
              allowNone: true,
              options: [
                for (final a in accounts)
                  PickerOption(a.id, a.displayName, icon: Icons.account_balance_rounded),
              ],
              onChanged: (v) => setState(() => _linkedAccountId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l10n.notes),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(l10n.noCredentialsNote, style: Theme.of(context).textTheme.bodySmall),
              subtitle: Text(l10n.cardReminderNote, style: Theme.of(context).textTheme.bodySmall),
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
}
