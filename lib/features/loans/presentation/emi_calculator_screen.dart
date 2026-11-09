import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

/// Stand-alone EMI calculator and interest-rate finder (Financial tools).
class EmiCalculatorScreen extends StatelessWidget {
  const EmiCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.financialTools),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.emiCalculator),
              Tab(text: l10n.rateFinder),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EmiCalculator(),
            SingleChildScrollView(child: RateFinderSheet(embedded: true)),
          ],
        ),
      ),
    );
  }
}

class _EmiCalculator extends StatefulWidget {
  const _EmiCalculator();

  @override
  State<_EmiCalculator> createState() => _EmiCalculatorState();
}

class _EmiCalculatorState extends State<_EmiCalculator> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _installments = TextEditingController();
  EmiFrequency _frequency = EmiFrequency.monthly;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _installments.dispose();
    super.dispose();
  }

  EmiQuote? get _quote {
    final p = Money.parse(_principal.text);
    final rate = NumberField.parse(_rate.text);
    final n = int.tryParse(_installments.text);
    if (p == null ||
        p <= 0 ||
        rate == null ||
        rate < 0 ||
        rate > 100 ||
        n == null ||
        n <= 0 ||
        n > 1200) {
      return null;
    }
    return LoanSchedule.quote(
      principalMinor: p,
      annualRatePercent: rate,
      installments: n,
      frequency: _frequency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final quote = _quote;
    void refresh(String _) => setState(() {});
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        const SizedBox(height: 12),
        NumberField(
          controller: _installments,
          label: l10n.tenure,
          integer: true,
          min: 1,
          max: 1200,
          onChanged: refresh,
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
        if (quote == null)
          Text(l10n.calcEnterValues)
        else
          SectionCard(
            title: l10n.calcResultEmi,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  quote.emiMinor,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _Row(l10n.calcTotalPayment, MoneyText(quote.totalPaymentMinor)),
                _Row(l10n.totalInterest, MoneyText(quote.totalInterestMinor)),
                _Row(l10n.principalLabel, MoneyText(quote.principalMinor)),
                const SizedBox(height: 4),
                Text(
                  l10n.calcInterestPercent(
                    (quote.interestRatio * 100).toStringAsFixed(1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.principalVsInterest,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SplitBar(
                  aLabel: l10n.principalLabel,
                  aMinor: quote.principalMinor,
                  bLabel: l10n.interestLabel,
                  bMinor: quote.totalInterestMinor,
                ),
                const SizedBox(height: 16),
                Text(l10n.calcFirstEmiSplit, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SplitBar(
                  aLabel: l10n.principalLabel,
                  aMinor: quote.firstPrincipalMinor,
                  bLabel: l10n.interestLabel,
                  bMinor: quote.firstInterestMinor,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        FitAmount(child: value),
      ],
    ),
  );
}

/// Solves for the interest rate from principal, EMI and installment count
/// using bisection on the EMI formula (see [EmiEngine.solvePeriodicRate]).
/// Pops with the annual rate when "Use this rate" is tapped.
class RateFinderSheet extends StatefulWidget {
  const RateFinderSheet({
    super.key,
    this.principalMinor,
    this.emiMinor,
    this.installments,
    this.frequency = EmiFrequency.monthly,
    this.embedded = false,
  });

  final int? principalMinor;
  final int? emiMinor;
  final int? installments;
  final EmiFrequency frequency;

  /// True inside the tools screen (no "use this rate" action).
  final bool embedded;

  @override
  State<RateFinderSheet> createState() => _RateFinderSheetState();
}

class _RateFinderSheetState extends State<RateFinderSheet> {
  late final _principal = TextEditingController(
    text: widget.principalMinor == null
        ? ''
        : Money.toEditable(widget.principalMinor!),
  );
  late final _emi = TextEditingController(
    text: widget.emiMinor == null ? '' : Money.toEditable(widget.emiMinor!),
  );
  late final _installments = TextEditingController(
    text: widget.installments?.toString() ?? '',
  );
  late EmiFrequency _frequency = widget.frequency;

  @override
  void dispose() {
    _principal.dispose();
    _emi.dispose();
    _installments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = Money.parse(_principal.text);
    final emi = Money.parse(_emi.text);
    final n = int.tryParse(_installments.text);
    final ready =
        p != null && p > 0 && emi != null && emi > 0 && n != null && n > 0;
    final periodic = ready
        ? EmiEngine.solvePeriodicRate(
            principalMinor: p,
            emiMinor: emi,
            installments: n,
          )
        : null;
    final annual = periodic == null
        ? null
        : EmiEngine.annualPercent(periodic, _frequency);
    void refresh(String _) => setState(() {});

    String resultText() {
      if (!ready) return l10n.calcEnterValues;
      if (annual == null) {
        return emi * n < p ? l10n.calcRateImpossible : l10n.calcRateTooHigh;
      }
      if (annual == 0) return l10n.calcRateZero;
      return l10n.calcRateValue(annual.toStringAsFixed(2));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded)
              Text(
                l10n.rateFinder,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 12),
            AmountField(
              controller: _principal,
              label: l10n.principal,
              onChanged: refresh,
            ),
            const SizedBox(height: 12),
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
            SectionCard(
              title: l10n.calcRateResult,
              child: Text(
                resultText(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!widget.embedded && annual != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  double.parse(annual.toStringAsFixed(4)),
                ),
                child: Text(l10n.useThisRate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
