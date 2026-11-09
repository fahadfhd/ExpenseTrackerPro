import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/money/money.dart';
import 'package:kept/core/routing/app_routes.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/loans/application/loan_providers.dart';
import 'package:kept/features/loans/data/loan_repository.dart';
import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/loans/presentation/loans_screen.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/shared/widgets/charts.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/form_fields.dart';
import 'package:kept/shared/widgets/money_text.dart';
import 'package:kept/shared/widgets/section_card.dart';
import 'package:kept/shared/widgets/states.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _loanEventsByIdProvider = Provider.family<List<LoanEvent>, String>(
  (ref, loanId) => (ref.watch(loanEventsProvider).value ?? const [])
      .where((e) => e.loanId == loanId)
      .toList(),
);

class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schedule = ref.watch(loanSchedulesProvider).value?[loanId];
    if (schedule == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ref.watch(loanSchedulesProvider).isLoading
            ? const Padding(padding: EdgeInsets.all(16), child: SkeletonList())
            : EmptyState(
                icon: Icons.search_off_rounded,
                message: l10n.failureNotFound,
              ),
      );
    }
    final loan = schedule.loan;
    final events = ref.watch(_loanEventsByIdProvider(loanId));
    final prepayments =
        events.where((e) => e.kind == LoanEventKind.prepayment).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final next = schedule.nextDue;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(currencyFormatterProvider);
    final status = schedule.effectiveStatus;

    Widget figure(String label, int value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          FitAmount(
            child: MoneyText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.name),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => AppRoutes.editLoan(context, loan),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              final repo = ref.read(loanRepositoryProvider);
              if (v == 'close') {
                final updated = loan.copyWith(
                  status: loan.status == LoanStatus.closed
                      ? LoanStatus.active
                      : LoanStatus.closed,
                  updatedAt: DateTime.now(),
                );
                repo.save(updated);
              } else if (v == 'delete') {
                if (!await confirmDelete(context, loan.name)) return;
                await repo.delete(loan);
                ref
                    .read(entityRemindersProvider)
                    .remove(ReminderEntityType.loan, loan.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'close',
                child: Text(
                  loan.status == LoanStatus.closed
                      ? l10n.reopenLoan
                      : l10n.closeLoan,
                ),
              ),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!schedule.emiCoversInterest)
            _Warning(l10n.emiDoesNotCoverInterest),
          SectionCard(
            title: l10n.outstandingPrincipal,
            trailing: LoanStatusChip(status),
            subtitle: loan.lender.isEmpty ? null : loan.lender,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  schedule.outstandingPrincipalMinor,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ProgressMeter(
                  ratio: schedule.paidRatio,
                  semanticsLabel: l10n.loanProgress(
                    '${schedule.paidCount}',
                    '${schedule.rows.length}',
                  ),
                  warnAt: 2,
                  alertAt: 3,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.loanProgress(
                    '${schedule.paidCount}',
                    '${schedule.rows.length}',
                  ),
                ),
                if (loan.status == LoanStatus.closed) ...[
                  const SizedBox(height: 6),
                  Text(l10n.loanClosedNote, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (next != null && loan.status != LoanStatus.closed)
            SectionCard(
              title: l10n.nextEmi,
              subtitle: l10n.nextEmiOn(
                '${next.number}',
                DateFormat.yMMMd(locale).format(next.dueDate),
              ),
              trailing: next.status == InstallmentStatus.overdue
                  ? StatusChip(
                      label: l10n.installmentOverdue,
                      icon: Icons.error_rounded,
                      color: context.finance.negative,
                    )
                  : null,
              // A Wrap, not a Row: with a long button label (translations,
              // large text) the amount used to be squeezed down to "₹1".
              // Now the button drops to its own line when they don't fit.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                children: [
                  MoneyText(
                    next.emiMinor,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.markPaid),
                    onPressed: () => showFormSheet(
                      context,
                      PayInstallmentSheet(loan: loan, row: next),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.principalVsInterest,
            child: Column(
              children: [
                SplitBar(
                  aLabel: l10n.principalLabel,
                  aMinor: loan.principalMinor,
                  bLabel: l10n.interestLabel,
                  bMinor: schedule.totalInterestMinor,
                ),
                const SizedBox(height: 12),
                figure(l10n.emiAmount, schedule.currentEmiMinor),
                figure(l10n.principalPaid, schedule.paidPrincipalMinor),
                figure(l10n.prepaid, schedule.prepaidPrincipalMinor),
                figure(l10n.paidInterest, schedule.paidInterestMinor),
                figure(l10n.remainingInterest, schedule.remainingInterestMinor),
                figure(l10n.totalInterest, schedule.totalInterestMinor),
                figure(l10n.calcTotalPayment, schedule.totalPaymentMinor),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.remainingEmis)),
                      FitAmount(
                        child: Text(
                          '${schedule.remainingCount}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.interestRate)),
                      FitAmount(
                        child: Text(
                          '${loan.annualRatePercent.toStringAsFixed(2)}% · ${l10n.emiFrequency(loan.frequency)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                if (schedule.unappliedPrepaymentMinor > 0)
                  _Warning(
                    l10n.unappliedPrepayment(
                      money.format(schedule.unappliedPrepaymentMinor),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (status == LoanStatus.active)
            OutlinedButton.icon(
              icon: const Icon(Icons.bolt_rounded),
              label: Text(l10n.recordPrepayment),
              onPressed: () => showFormSheet(
                context,
                PrepaymentSheet(schedule: schedule, events: events),
              ),
            ),
          if (prepayments.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: l10n.prepayments,
              child: Column(
                children: [
                  for (final p in prepayments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_rounded),
                      title: MoneyText(p.amountMinor),
                      subtitle: Text(
                        '${DateFormat.yMMMd(locale).format(p.date)} · ${p.prepaymentMode == PrepaymentMode.reduceEmi ? l10n.prepayReduceEmi : l10n.prepayReduceTenure}',
                      ),
                      trailing: IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          if (!await confirmDelete(
                            context,
                            l10n.recordPrepayment,
                          )) {
                            return;
                          }
                          final linked = p.transactionId == null
                              ? null
                              : await ref
                                    .read(transactionRepositoryProvider)
                                    .fetch(p.transactionId!);
                          ref
                              .read(loanRepositoryProvider)
                              .clearInstallment(p, linked: linked);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.schedule,
            trailing: TextButton(
              onPressed: () =>
                  pushPage(context, LoanScheduleScreen(loanId: loanId)),
              child: Text(
                l10n.seeAll,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            child: Column(
              children: [
                for (final row
                    in schedule.rows
                        .where((r) => r.status != InstallmentStatus.paid)
                        .take(3))
                  ScheduleRowTile(loan: loan, row: row),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.finance.negative;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class LoanScheduleScreen extends ConsumerWidget {
  const LoanScheduleScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(loanSchedulesProvider).value?[loanId];
    return Scaffold(
      appBar: AppBar(title: Text(schedule?.loan.name ?? l10n.schedule)),
      body: schedule == null
          ? const SizedBox.shrink()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedule.rows.length,
              itemBuilder: (context, i) =>
                  ScheduleRowTile(loan: schedule.loan, row: schedule.rows[i]),
            ),
    );
  }
}

class ScheduleRowTile extends ConsumerWidget {
  const ScheduleRowTile({super.key, required this.loan, required this.row});

  final Loan loan;
  final AmortizationRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final finance = context.finance;
    final (icon, color) = switch (row.status) {
      InstallmentStatus.paid => (Icons.check_circle_rounded, finance.positive),
      InstallmentStatus.skipped => (
        Icons.remove_circle_outline_rounded,
        finance.warning,
      ),
      InstallmentStatus.overdue => (Icons.error_rounded, finance.negative),
      InstallmentStatus.upcoming => (
        Icons.radio_button_unchecked_rounded,
        theme.colorScheme.onSurfaceVariant,
      ),
    };
    final date = DateFormat.yMMMd(locale).format(row.dueDate);
    return Semantics(
      button: true,
      label: l10n.scheduleRowSemantics(
        '${row.number}',
        date,
        money.format(row.emiMinor),
        money.format(row.principalMinor),
        money.format(row.interestMinor),
        money.format(row.closingMinor),
        l10n.installmentStatus(row.status),
      ),
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loan.status == LoanStatus.closed
              ? null
              : () => showModalBottomSheet(
                  context: context,
                  builder: (_) => _RowActions(loan: loan, row: row),
                ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '#${row.number}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${l10n.principalLabel} ${money.format(row.principalMinor)} · ${l10n.interestLabel} ${money.format(row.interestMinor)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${l10n.balanceLabel} ${money.format(row.closingMinor)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      row.emiMinor,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    StatusChip(
                      label: l10n.installmentStatus(row.status),
                      icon: icon,
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.loan, required this.row});

  final Loan loan;
  final AmortizationRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repo = ref.read(loanRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);
    final event = (ref.read(loanEventsProvider).value ?? const <LoanEvent>[])
        .where((e) => e.id == LoanEvent.installmentEventId(loan.id, row.number))
        .firstOrNull;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l10n.markPaidTitle('${row.number}'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (row.status != InstallmentStatus.paid)
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: Text(l10n.markPaid),
              onTap: () {
                Navigator.pop(context);
                showFormSheet(
                  context,
                  PayInstallmentSheet(loan: loan, row: row),
                );
              },
            ),
          if (row.status != InstallmentStatus.skipped &&
              row.status != InstallmentStatus.paid)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded),
              title: Text(l10n.skipEmi),
              onTap: () {
                repo.skipInstallment(loan, row.number);
                Navigator.pop(context);
              },
            ),
          if (event != null)
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: Text(l10n.clearMark),
              onTap: () async {
                final linked = event.transactionId == null
                    ? null
                    : await txRepo.fetch(event.transactionId!);
                repo.clearInstallment(event, linked: linked);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

/// Records one EMI as paid, optionally from an account (which creates the
/// linked loan-payment transaction and updates that account's balance).
class PayInstallmentSheet extends ConsumerStatefulWidget {
  const PayInstallmentSheet({super.key, required this.loan, required this.row});

  final Loan loan;
  final AmortizationRow row;

  @override
  ConsumerState<PayInstallmentSheet> createState() =>
      _PayInstallmentSheetState();
}

class _PayInstallmentSheetState extends ConsumerState<PayInstallmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: Money.toEditable(widget.row.emiMinor),
  );
  late DateTime _date = DateTime.now();
  late PaymentSource? _pay = paymentFor(
    ref,
    widget.loan.accountId,
    known: false,
  );
  String? _payError;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  // Guards against a double tap while the save awaits the network, which
  // would otherwise write the record (and its account movement) twice.
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _persist();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persist() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pay == null && ref.read(activeAccountsProvider).isNotEmpty) {
      setState(() => _payError = context.l10n.paymentRequired);
      return;
    }
    final txRepo = ref.read(transactionRepositoryProvider);
    final previous = await txRepo.fetch(
      LoanRepository.installmentTransactionId(
        widget.loan.id,
        widget.row.number,
      ),
    );
    ref
        .read(loanRepositoryProvider)
        .payInstallment(
          loan: widget.loan,
          number: widget.row.number,
          amountMinor: Money.parse(_amount.text)!,
          date: _date,
          accountId: _pay?.accountId,
          previousTransaction: previous,
        );
    if (!mounted) return;
    Navigator.pop(context);
    showMessage(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider);
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              l10n.markPaidTitle('${widget.row.number}'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            AmountField(controller: _amount),
            const SizedBox(height: 12),
            DateField(
              label: l10n.paidOn,
              value: _date,
              onChanged: (d) => setState(() => _date = d ?? _date),
            ),
            const SizedBox(height: 12),
            PaymentSourceField(
              label: l10n.paidWith,
              value: _pay,
              accounts: accounts,
              errorText: _payError,
              onChanged: (v) => setState(() {
                _pay = v;
                _payError = null;
              }),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Records a prepayment after showing exactly what it changes under the
/// chosen mode. Nothing is applied until the user confirms.
class PrepaymentSheet extends ConsumerStatefulWidget {
  const PrepaymentSheet({
    super.key,
    required this.schedule,
    required this.events,
  });

  final LoanSchedule schedule;
  final List<LoanEvent> events;

  @override
  ConsumerState<PrepaymentSheet> createState() => _PrepaymentSheetState();
}

class _PrepaymentSheetState extends ConsumerState<PrepaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  PrepaymentMode _mode = PrepaymentMode.reduceTenure;
  late PaymentSource? _pay = paymentFor(
    ref,
    widget.schedule.loan.accountId,
    known: false,
  );
  String? _payError;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  LoanSchedule? _preview() {
    final amount = Money.parse(_amount.text);
    if (amount == null || amount <= 0) return null;
    return LoanSchedule.build(widget.schedule.loan, [
      ...widget.events,
      LoanEvent(
        id: '_preview',
        loanId: widget.schedule.loan.id,
        kind: LoanEventKind.prepayment,
        amountMinor: amount,
        prepaymentMode: _mode,
        date: _date,
        createdAt: DateTime.now(),
      ),
    ], today: DateTime.now());
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_pay == null && ref.read(activeAccountsProvider).isNotEmpty) {
      setState(() => _payError = context.l10n.paymentRequired);
      return;
    }
    ref
        .read(loanRepositoryProvider)
        .addPrepayment(
          loan: widget.schedule.loan,
          amountMinor: Money.parse(_amount.text)!,
          date: _date,
          mode: _mode,
          accountId: _pay?.accountId,
        );
    Navigator.pop(context);
    showMessage(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final accounts = ref.watch(activeAccountsProvider);
    final before = widget.schedule;
    final after = _preview();
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              l10n.recordPrepayment,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.prepayExplain,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              label: l10n.prepaymentAmount,
              maxMinor: before.outstandingPrincipalMinor,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DateField(
              label: l10n.date,
              value: _date,
              onChanged: (d) => setState(() => _date = d ?? _date),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.prepaymentMode,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            RadioGroup<PrepaymentMode>(
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v ?? _mode),
              child: Column(
                children: [
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: PrepaymentMode.reduceTenure,
                    title: Text(l10n.prepayReduceTenure),
                  ),
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: PrepaymentMode.reduceEmi,
                    title: Text(l10n.prepayReduceEmi),
                  ),
                ],
              ),
            ),
            PaymentSourceField(
              label: l10n.paidWith,
              value: _pay,
              accounts: accounts,
              errorText: _payError,
              onChanged: (v) => setState(() {
                _pay = v;
                _payError = null;
              }),
            ),
            if (after != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.prepayPreview,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.prepayOutstanding(
                        money.format(before.outstandingPrincipalMinor),
                        money.format(after.outstandingPrincipalMinor),
                      ),
                    ),
                    Text(
                      l10n.prepayNewEmi(
                        money.format(before.currentEmiMinor),
                        money.format(after.currentEmiMinor),
                      ),
                    ),
                    Text(
                      l10n.prepayNewTenure(
                        '${before.remainingCount}',
                        '${after.remainingCount}',
                      ),
                    ),
                    Text(
                      l10n.prepayInterestSaved(
                        money.format(
                          before.remainingInterestMinor -
                              after.remainingInterestMinor,
                        ),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
