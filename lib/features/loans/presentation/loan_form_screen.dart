import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/loans/application/loan_providers.dart';
import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';
import 'package:kept/shared/widgets/section_card.dart';

enum _CalcState { incomplete, impossible, tooHigh, ok }

/// The loan's EMI and annual interest rate worked out from the form.
class _Calc {
  const _Calc.invalid(this.state) : emiMinor = 0, annualRatePercent = 0;

  const _Calc.ok({required this.emiMinor, required this.annualRatePercent})
    : state = _CalcState.ok;

  final _CalcState state;
  final int emiMinor;
  final double annualRatePercent;
}

/// Add or edit a loan.
///
/// The user gives the principal, the EMI amount and the number of EMIs
/// (all printed on a loan statement) and the app works out the interest
/// rate, so nobody has to look it up. People who do know the rate can
/// switch to entering it instead, and the EMI is calculated.
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
  late final _emi = TextEditingController(
    text: widget.initial == null
        ? ''
        : Money.toEditable(widget.initial!.emiMinor),
  );
  late final _installments = TextEditingController(
    text: widget.initial == null ? '' : '${widget.initial!.installments}',
  );
  late final _rate = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.annualRatePercent.toStringAsFixed(2),
  );
  final _paid = TextEditingController(text: '0');

  late EmiFrequency _frequency =
      widget.initial?.frequency ?? EmiFrequency.monthly;

  /// Due date of the first EMI when editing; otherwise the *next unpaid* EMI
  /// (which is the first one while none are paid).
  late DateTime _dueDate =
      widget.initial?.firstDueDate ??
      DateTime(DateTime.now().year, DateTime.now().month + 1, 5);
  late PaymentSource? _pay = widget.initial?.accountId == null
      ? null
      : paymentFor(ref, widget.initial!.accountId, known: false);
  late bool _reminder = widget.initial?.reminderEnabled ?? true;

  /// Enter the rate and calculate the EMI, instead of the default.
  bool _knowRate = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _lender,
      _notes,
      _principal,
      _emi,
      _installments,
      _rate,
      _paid,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _paidCount => int.tryParse(_paid.text.trim()) ?? 0;

  _Calc _calc() {
    final principal = Money.parse(_principal.text);
    final n = int.tryParse(_installments.text.trim());
    if (principal == null || principal <= 0 || n == null || n < 1 || n > 1200) {
      return const _Calc.invalid(_CalcState.incomplete);
    }
    if (_knowRate) {
      final rate = NumberField.parse(_rate.text);
      if (rate == null || rate < 0 || rate > 100) {
        return const _Calc.invalid(_CalcState.incomplete);
      }
      return _Calc.ok(
        emiMinor: EmiEngine.emi(
          principalMinor: principal,
          periodicRate: EmiEngine.periodicRate(rate, _frequency),
          installments: n,
        ),
        annualRatePercent: rate,
      );
    }
    final emi = Money.parse(_emi.text);
    if (emi == null || emi <= 0) {
      return const _Calc.invalid(_CalcState.incomplete);
    }
    final periodic = EmiEngine.solvePeriodicRate(
      principalMinor: principal,
      emiMinor: emi,
      installments: n,
    );
    if (periodic == null) {
      // Either the EMIs add up to less than the principal, or the implied
      // rate is absurd; tell the user which.
      return _Calc.invalid(
        emi * n < principal ? _CalcState.impossible : _CalcState.tooHigh,
      );
    }
    return _Calc.ok(
      emiMinor: emi,
      annualRatePercent: EmiEngine.annualPercent(periodic, _frequency),
    );
  }

  /// First EMI date, derived from the date of the next unpaid EMI when some
  /// are already paid.
  DateTime get _firstDueDate {
    if (_isEdit) return _dueDate;
    final paid = _paidCount;
    if (paid <= 0) return _dueDate;
    return Dates.addMonths(
      Dates.dayOf(_dueDate),
      -paid * _frequency.monthsPerPeriod,
      preferredDay: _dueDate.day,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final calc = _calc();
    if (calc.state != _CalcState.ok) {
      setState(() {});
      return;
    }
    final repo = ref.read(loanRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final principal = Money.parse(_principal.text)!;
    final n = int.parse(_installments.text.trim());
    final loan = initial == null
        ? Loan(
            id: repo.newId(),
            name: _name.text.trim(),
            lender: _lender.text.trim(),
            principalMinor: principal,
            annualRatePercent: calc.annualRatePercent,
            installments: n,
            frequency: _frequency,
            emiMinor: calc.emiMinor,
            firstDueDate: _firstDueDate,
            accountId: _pay?.accountId,
            notes: _notes.text.trim(),
            reminderEnabled: _reminder,
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            name: _name.text.trim(),
            lender: _lender.text.trim(),
            principalMinor: principal,
            annualRatePercent: calc.annualRatePercent,
            installments: n,
            frequency: _frequency,
            emiMinor: calc.emiMinor,
            firstDueDate: _firstDueDate,
            accountId: () => _pay?.accountId,
            notes: _notes.text.trim(),
            reminderEnabled: _reminder,
            updatedAt: now,
          );
    repo.save(loan);
    final paid = _isEdit ? 0 : _paidCount;
    repo.recordPastPayments(loan, paid);
    final l10n = context.l10n;
    Navigator.pop(context);
    showMessage(
      context,
      paid > 0 ? l10n.loanSavedWithPaid('$paid') : l10n.saved,
    );
  }

  String? _calcMessage(AppLocalizations l10n, _Calc calc) =>
      switch (calc.state) {
        _CalcState.impossible => l10n.calcRateImpossible,
        _CalcState.tooHigh => l10n.calcRateTooHigh,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final accounts = ref.watch(activeAccountsProvider);
    final calc = _calc();
    final n = int.tryParse(_installments.text.trim());
    void refresh([String? _]) => setState(() {});

    Widget result() {
      final problem = _calcMessage(l10n, calc);
      if (problem != null) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                problem,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      }
      if (calc.state != _CalcState.ok) {
        return Text(l10n.calcEnterValues);
      }
      final quote = LoanSchedule.quote(
        principalMinor: Money.parse(_principal.text)!,
        annualRatePercent: calc.annualRatePercent,
        installments: int.parse(_installments.text.trim()),
        frequency: _frequency,
      );
      final headline = _knowRate
          ? l10n.loanEmiCalculated(money.format(calc.emiMinor))
          : calc.annualRatePercent == 0
          ? l10n.calcRateZero
          : l10n.calcRateValue(calc.annualRatePercent.toStringAsFixed(2));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.loanInterestSummary(
              money.format(quote.totalInterestMinor),
              money.format(quote.totalPaymentMinor),
            ),
          ),
          if (!_knowRate) ...[
            const SizedBox(height: 6),
            Text(l10n.loanRateFromEmi, style: theme.textTheme.bodySmall),
          ],
        ],
      );
    }

    // Ask before discarding a half-filled new entry.
    return UnsavedChangesGuard(
      isDirty: () =>
          widget.initial == null &&
          (_name.text.trim().isNotEmpty ||
              _principal.text.trim().isNotEmpty ||
              _emi.text.trim().isNotEmpty ||
              _installments.text.trim().isNotEmpty),
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? l10n.editLoan : l10n.newLoan)),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.loanName,
                  hintText: l10n.loanNameHint,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
              ),
              const SizedBox(height: 12),
              AmountField(
                controller: _principal,
                label: l10n.principal,
                onChanged: refresh,
              ),
              const SizedBox(height: 12),
              if (_knowRate)
                NumberField(
                  controller: _rate,
                  label: l10n.interestRate,
                  suffix: '%',
                  min: 0,
                  max: 100,
                  onChanged: refresh,
                )
              else
                AmountField(
                  controller: _emi,
                  label: l10n.emiAmount,
                  onChanged: refresh,
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
                    : l10n.tenureMonthsHelp(
                        '${n * _frequency.monthsPerPeriod}',
                      ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _knowRate = !_knowRate),
                  child: Text(_knowRate ? l10n.loanUseEmi : l10n.loanKnowRate),
                ),
              ),
              SectionCard(
                title: _knowRate ? l10n.calcResultEmi : l10n.loanRateCalculated,
                child: result(),
              ),
              const SizedBox(height: 16),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _paid,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.loanEmisPaid,
                    helperText: l10n.loanEmisPaidHelp,
                    helperMaxLines: 3,
                  ),
                  onChanged: refresh,
                  validator: (v) {
                    final value = int.tryParse((v ?? '').trim());
                    final max = n ?? 0;
                    return value == null || value < 0 || value > max
                        ? l10n.loanEmisPaidInvalid('$max')
                        : null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              DateField(
                label: !_isEdit && _paidCount > 0
                    ? l10n.loanNextEmiDate
                    : l10n.loanFirstEmiDate,
                value: _dueDate,
                onChanged: (d) => setState(() => _dueDate = d ?? _dueDate),
              ),
              if (!_isEdit && _paidCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Text(
                    l10n.loanNextEmiHelp('${_paidCount + 1}'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              PickerField<EmiFrequency>(
                label: l10n.emiFrequencyLabel,
                value: _frequency,
                options: [
                  for (final f in EmiFrequency.values)
                    PickerOption(f, l10n.emiFrequency(f)),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lender,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.lender),
              ),
              const SizedBox(height: 16),
              if (accounts.isNotEmpty) ...[
                PaymentSourceField(
                  label: l10n.payFromAccount,
                  value: _pay,
                  accounts: accounts,
                  allowCash: false,
                  onChanged: (v) => setState(() => _pay = v),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    l10n.loanPayFromHelp,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
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
      ),
    );
  }
}
