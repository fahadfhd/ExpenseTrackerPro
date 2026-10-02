import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/accounts/presentation/accounts_screen.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.initial});

  final Account? initial;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _bank = TextEditingController(text: widget.initial?.bankName);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late final _opening = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.openingBalanceMinor),
  );
  late AccountType _type = widget.initial?.type ?? AccountType.savings;

  @override
  void dispose() {
    _name.dispose();
    _bank.dispose();
    _notes.dispose();
    _opening.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(accountRepositoryProvider);
    final now = DateTime.now();
    final opening = Money.parse(_opening.text) ?? 0;
    final initial = widget.initial;
    final account = initial == null
        ? Account(
            id: repo.newId(),
            name: _name.text.trim(),
            bankName: _bank.text.trim(),
            type: _type,
            openingBalanceMinor: opening,
            notes: _notes.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            name: _name.text.trim(),
            bankName: _bank.text.trim(),
            type: _type,
            openingBalanceMinor: opening,
            notes: _notes.text.trim(),
            updatedAt: now,
          );
    repo.save(account);
    Navigator.pop(context);
    showMessage(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l10n.newAccount : l10n.editAccount),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.initial == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.accountName, hintText: l10n.accountNameHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bank,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: '${l10n.bankName} (${l10n.optional})'),
            ),
            const SizedBox(height: 12),
            PickerField<AccountType>(
              label: l10n.accountTypeLabel,
              value: _type,
              options: [
                for (final t in AccountType.values)
                  PickerOption(t, l10n.accountType(t), icon: accountIcon(t)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _opening,
              label: l10n.openingBalance,
              required: false,
              allowZero: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(l10n.openingBalanceHelp, style: Theme.of(context).textTheme.bodySmall),
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
