import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/loans/application/loan_providers.dart';
import 'package:expensetrackerpro/features/loans/domain/emi_engine.dart';
import 'package:expensetrackerpro/features/loans/domain/loan.dart';
import 'package:expensetrackerpro/features/loans/presentation/emi_calculator_screen.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanFormScreen extends ConsumerStatefulWidget {
  const LoanFormScreen({super.key, this.initial});

  final Loan? initial;

  @override
  ConsumerState<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends ConsumerState<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _lender = TextEditingController(text: widget.initial?.lender);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late final _principal = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.principalMinor),
  );
  late final _rate = TextEditingController(
    text: widget.initial == null ? '' : '${widget.initial!.annualRatePercent}',
  );
  late final _installments = TextEditingController(
    text: widget.initial == null ? '' : '${widget.initial!.installments}',
  );
  late final _emi = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.emiMinor),
  );
  late EmiFrequency _frequency =
      widget.initial?.frequency ?? EmiFrequency.monthly;
  late DateTime _firstDue =
      widget.initial?.firstDueDate ??
      DateTime(DateTime.now().year, DateTime.now().month + 1, 5);
  late String? _accountId = existingAccountId(ref, widget.initial?.accountId);
  late bool _reminder = widget.initial?.reminderEnabled ?? true;
  late bool _overrideEmi =
      widget.initial != null && widget.initial!.emiMinor != _computedEmi();

  @override
  void dispose() {
    for (final c in [
      _name,
      _lender,
      _notes,
      _principal,
      _rate,
      _installments,
      _emi,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _computedEmi() {
    final p = Money.parse(_principal.text);
    final rate = NumberField.parse(_rate.text);
    final n = int.tryParse(_installments.text);
    if (p == null || p <= 0 || rate == null || rate < 0 || n == null || n <= 0) {
      return null;
    }
    return EmiEngine.emi(
      principalMinor: p,
      periodicRate: EmiEngine.periodicRate(rate, _frequency),
      installments: n,
    );
  }

  Future<void> _findRate() async {
    final rate = await showFormSheet<double>(
      context,
      RateFinderSheet(
        principalMinor: Money.parse(_principal.text),
        emiMinor: Money.parse(_emi.text),
        installments: int.tryParse(_installments.text),
        frequency: _frequency,
      ),
    );
    if (rate != null) setState(() => _rate.text = rate.toStringAsFixed(2));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final computed = _computedEmi();
    final emi = _overrideEmi ? Money.parse(_emi.text) : computed;
    if (emi == null || emi <= 0) return;
    final repo = ref.read(loanRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final fields = (
      name: _name.text.trim(),
      lender: _lender.text.trim(),
      principal: Money.parse(_principal.text)!,
      rate: NumberField.parse(_rate.text)!,
      n: int.parse(_installments.text),
    );
    final loan = initial == null
        ? Loan(
            id: repo.newId(),
            name: fields.name,
            lender: fields.lender,
            principalMinor: fields.principal,
            annualRatePercent: fields.rate,
            installments: fields.n,
            frequency: _frequency,
            emiMinor: emi,
            firstDueDate: _firstDue,
            accountId: _accountId,
            notes: _notes.text.trim(),
            reminderEnabled: _reminder,
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            name: fields.name,
            lender: fields.lender,
            principalMinor: fields.principal,
            annualRatePercent: fields.rate,
            installments: fields.n,
            frequency: _frequency,
            emiMinor: emi,
            firstDueDate: _firstDue,
            accountId: () => _accountId,
            notes: _notes.text.trim(),
            reminderEnabled: _reminder,
            updatedAt: now,
          );
    repo.save(loan);
    Navigator.pop(context);
    showMessage(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final accounts = ref.watch(activeAccountsProvider);
    final computed = _computedEmi();
    final n = int.tryParse(_installments.text);
    void refresh(String _) => setState(() {});

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l10n.newLoan : l10n.editLoan),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.loanName,
                hintText: l10n.loanNameHint,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lender,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.lender),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _principal,
              label: l10n.principal,
              onChanged: refresh,
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _rate,
              label: l10n.interestRate,
              suffix: '%',
              min: 0,
              max: 100,
              onChanged: refresh,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.manage_search_rounded),
                label: Text(l10n.findRate),
                onPressed: _findRate,
              ),
            ),
            PickerField<EmiFrequency>(
              label: l10n.emiFrequencyLabel,
              value: _frequency,
              options: [
                for (final f in EmiFrequency.values)
                  PickerOption(f, l10n.emiFrequency(f)),
              ],
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _installments,
              label: l10n.tenure,
              integer: true,
              min: 1,
              max: 1200,
              onChanged: refresh,
              helper: n == null
                  ? null
                  : l10n.tenureMonthsHelp('${n * _frequency.monthsPerPeriod}'),
            ),
            const SizedBox(height: 12),
            DateField(
              label: l10n.firstEmiDate,
              value: _firstDue,
              onChanged: (d) => setState(() => _firstDue = d ?? _firstDue),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  computed == null
                      ? l10n.calcEnterValues
                      : l10n.emiComputed(money.format(computed)),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.emiOverride),
              subtitle: Text(l10n.emiOverrideHelp),
              value: _overrideEmi,
              onChanged: (v) => setState(() {
                _overrideEmi = v;
                if (v && _emi.text.isEmpty && computed != null) {
                  _emi.text = Money.toEditable(computed);
                }
              }),
            ),
            if (_overrideEmi)
              AmountField(controller: _emi, label: l10n.emiAmount),
            const SizedBox(height: 12),
            PickerField<String>(
              label: l10n.payFromAccount,
              value: _accountId,
              allowNone: true,
              options: [
                for (final a in accounts)
                  PickerOption(
                    a.id,
                    a.displayName,
                    icon: Icons.account_balance_rounded,
                  ),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.loanReminder),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
            ),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l10n.notes),
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
