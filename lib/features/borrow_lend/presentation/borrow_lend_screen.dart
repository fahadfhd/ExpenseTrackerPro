import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/borrow_lend/application/debt_providers.dart';
import 'package:expensetrackerpro/features/borrow_lend/domain/debt_record.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/reminders/domain/reminder.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:expensetrackerpro/shared/widgets/offset_selector.dart';
import 'package:expensetrackerpro/shared/widgets/section_card.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _DebtFilter { open, borrowed, lent, settled, all }

class BorrowLendScreen extends ConsumerStatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  ConsumerState<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends ConsumerState<BorrowLendScreen> {
  _DebtFilter _filter = _DebtFilter.open;

  bool _matches(DebtRecord r) => switch (_filter) {
    _DebtFilter.open => !r.isSettled,
    _DebtFilter.borrowed => r.direction == DebtDirection.borrowed,
    _DebtFilter.lent => r.direction == DebtDirection.lent,
    _DebtFilter.settled => r.isSettled,
    _DebtFilter.all => true,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final records = ref.watch(debtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final labels = {
      _DebtFilter.open: l10n.filterOpen,
      _DebtFilter.borrowed: l10n.debtBorrowed,
      _DebtFilter.lent: l10n.debtLent,
      _DebtFilter.settled: l10n.filterSettled,
      _DebtFilter.all: l10n.all,
    };
    Widget figure(String label, int value, {Color? color, IconData? icon}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
              Flexible(child: Text(label, style: theme.textTheme.labelMedium)),
            ],
          ),
          MoneyText(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.borrowLendTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newDebt),
        onPressed: () => pushPage(context, const DebtFormScreen()),
      ),
      body: AsyncView<List<DebtRecord>>(
        value: records,
        onRetry: () => ref.invalidate(debtsProvider),
        data: (list) {
          final visible = list.where(_matches).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        figure(l10n.iOwe, summary.iOweMinor, icon: Icons.call_received_rounded),
                        figure(l10n.owedToMe, summary.owedToMeMinor, icon: Icons.call_made_rounded),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        figure(
                          l10n.overdueAmount,
                          summary.overdueMinor,
                          color: summary.overdueMinor > 0 ? context.finance.negative : null,
                          icon: summary.overdueMinor > 0 ? Icons.error_rounded : null,
                        ),
                        Expanded(child: Text(l10n.openRecords('${summary.openCount}'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        figure(l10n.totalBorrowed, summary.borrowedTotalMinor),
                        figure(l10n.totalLent, summary.lentTotalMinor),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _DebtFilter.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(labels[f]!),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                EmptyState(icon: Icons.handshake_rounded, message: l10n.debtsEmpty)
              else
                for (final r in visible) DebtTile(record: r),
            ],
          );
        },
      ),
    );
  }
}

class DebtStatusChip extends StatelessWidget {
  const DebtStatusChip(this.status, {super.key});
  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final finance = context.finance;
    final (icon, color) = switch (status) {
      DebtStatus.pending => (Icons.schedule_rounded, Theme.of(context).colorScheme.primary),
      DebtStatus.partiallySettled => (Icons.timelapse_rounded, finance.warning),
      DebtStatus.settled => (Icons.check_circle_rounded, finance.positive),
      DebtStatus.overdue => (Icons.error_rounded, finance.negative),
    };
    return StatusChip(label: context.l10n.debtStatus(status), icon: icon, color: color);
  }
}

class DebtTile extends ConsumerWidget {
  const DebtTile({super.key, required this.record});
  final DebtRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final money = ref.watch(currencyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final borrowed = record.direction == DebtDirection.borrowed;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => pushPage(context, DebtDetailScreen(recordId: record.id)),
        leading: CircleAvatar(
          child: Icon(borrowed ? Icons.call_received_rounded : Icons.call_made_rounded),
        ),
        title: Text(record.personName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            l10n.debtDirection(record.direction),
            if (record.dueDate != null) l10n.debtDueOn(DateFormat.MMMd(locale).format(record.dueDate!)),
            l10n.outstandingOf(money.format(record.outstandingMinor), money.format(record.amountMinor)),
          ].join(' · '),
        ),
        trailing: DebtStatusChip(record.statusAt(DateTime.now())),
      ),
    );
  }
}

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.initial});
  final DebtRecord? initial;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _person = TextEditingController(text: widget.initial?.personName);
  late final _amount = TextEditingController(
    text: widget.initial == null ? '' : Money.toEditable(widget.initial!.amountMinor),
  );
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late DebtDirection _direction = widget.initial?.direction ?? DebtDirection.lent;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late DateTime? _due = widget.initial?.dueDate;
  late String? _accountId = existingAccountId(ref, widget.initial?.accountId);
  late bool _reminder = widget.initial?.reminderEnabled ?? true;
  late List<int> _offsets = widget.initial?.reminderOffsetsMinutes ?? defaultDueOffsetsMinutes;

  @override
  void dispose() {
    for (final c in [_person, _amount, _description, _notes]) {
      c.dispose();
    }
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
    final repo = ref.read(debtRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final record = initial == null
        ? DebtRecord(
            id: repo.newId(),
            direction: _direction,
            personName: _person.text.trim(),
            amountMinor: Money.parse(_amount.text)!,
            date: _date,
            dueDate: _due,
            description: _description.text.trim(),
            notes: _notes.text.trim(),
            accountId: _accountId,
            reminderEnabled: _reminder,
            reminderOffsetsMinutes: _offsets,
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            direction: _direction,
            personName: _person.text.trim(),
            amountMinor: Money.parse(_amount.text)!,
            date: _date,
            dueDate: () => _due,
            description: _description.text.trim(),
            notes: _notes.text.trim(),
            accountId: () => _accountId,
            reminderEnabled: _reminder,
            reminderOffsetsMinutes: _offsets,
            updatedAt: now,
          );
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await repo.save(record);
    ref.read(entityRemindersProvider).syncDebt(record);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(activeAccountsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? l10n.newDebt : l10n.editDebt)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<DebtDirection>(
              segments: [
                ButtonSegment(value: DebtDirection.lent, label: Text(l10n.iLent), icon: const Icon(Icons.call_made_rounded)),
                ButtonSegment(value: DebtDirection.borrowed, label: Text(l10n.iBorrowed), icon: const Icon(Icons.call_received_rounded)),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.personName, hintText: l10n.personNameHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.personRequired : null,
            ),
            const SizedBox(height: 12),
            AmountField(controller: _amount),
            const SizedBox(height: 12),
            DateField(label: l10n.givenOn, value: _date, onChanged: (d) => setState(() => _date = d ?? _date)),
            const SizedBox(height: 12),
            DateField(label: l10n.dueDateOptional, value: _due, clearable: true, onChanged: (d) => setState(() => _due = d)),
            const SizedBox(height: 12),
            PickerField<String>(
              label: l10n.moneyMovedThrough,
              value: _accountId,
              allowNone: true,
              noneLabel: l10n.cashUntracked,
              options: [for (final a in accounts) PickerOption(a.id, a.displayName, icon: Icons.account_balance_rounded)],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(labelText: l10n.notes),
            ),
            if (_due != null) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.debtReminder),
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
              ),
              if (_reminder) ...[
                Text(l10n.debtReminderOffsets, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                OffsetSelector(selected: _offsets, onChanged: (v) => setState(() => _offsets = v)),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.recordId});
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final record = (ref.watch(debtsProvider).value ?? const <DebtRecord>[])
        .where((r) => r.id == recordId)
        .firstOrNull;
    if (record == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off_rounded, message: l10n.failureNotFound));
    }
    final locale = Localizations.localeOf(context).toString();
    final accounts = ref.watch(accountsByIdProvider);
    final repo = ref.read(debtRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(record.personName),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => pushPage(context, DebtFormScreen(initial: record)),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (!await confirmDelete(context, record.personName)) return;
              await repo.delete(record);
              ref.read(entityRemindersProvider).remove(ReminderEntityType.borrowLend, record.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: record.isSettled
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.payments_rounded),
              label: Text(l10n.addSettlement),
              onPressed: () => showFormSheet(context, SettlementSheet(record: record)),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SectionCard(
            title: l10n.debtDirection(record.direction),
            trailing: DebtStatusChip(record.statusAt(DateTime.now())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(record.outstandingMinor, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ProgressMeter(
                  ratio: Money.ratio(record.settledMinor, record.amountMinor),
                  semanticsLabel: l10n.settlements,
                  warnAt: 2,
                  alertAt: 3,
                ),
                const SizedBox(height: 8),
                Text(l10n.outstandingOf(
                  ref.watch(currencyFormatterProvider).format(record.outstandingMinor),
                  ref.watch(currencyFormatterProvider).format(record.amountMinor),
                )),
                const SizedBox(height: 8),
                Text('${l10n.givenOn}: ${DateFormat.yMMMd(locale).format(record.date)}'),
                if (record.dueDate != null) Text(l10n.debtDueOn(DateFormat.yMMMd(locale).format(record.dueDate!))),
                if (record.accountId != null) Text('${l10n.moneyMovedThrough}: ${accounts[record.accountId]?.name ?? '—'}'),
                if (record.description.isNotEmpty) ...[const SizedBox(height: 8), Text(record.description)],
                if (record.notes.isNotEmpty) Text(record.notes, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.settlements,
            child: record.settlements.isEmpty
                ? Text(l10n.noSettlements)
                : Column(
                    children: [
                      for (final s in record.settlements.reversed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.payments_rounded),
                          title: MoneyText(s.amountMinor),
                          subtitle: Text([
                            DateFormat.yMMMd(locale).format(s.date),
                            if (s.accountId != null) accounts[s.accountId]?.name ?? '',
                            if (s.note.isNotEmpty) s.note,
                          ].join(' · ')),
                          trailing: IconButton(
                            tooltip: l10n.delete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              if (!await confirmDelete(context, l10n.addSettlement)) return;
                              await repo.removeSettlement(record, s);
                              final updated = record.copyWith(
                                settlements: record.settlements.where((x) => x.id != s.id).toList(),
                              );
                              ref.read(entityRemindersProvider).syncDebt(updated);
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class SettlementSheet extends ConsumerStatefulWidget {
  const SettlementSheet({super.key, required this.record});
  final DebtRecord record;

  @override
  ConsumerState<SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends ConsumerState<SettlementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  late String? _accountId = existingAccountId(ref, widget.record.accountId);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(debtRepositoryProvider);
    final settlement = Settlement(
      id: repo.newId(),
      amountMinor: Money.parse(_amount.text)!,
      date: _date,
      note: _note.text.trim(),
      accountId: _accountId,
    );
    repo.addSettlement(widget.record, settlement);
    // Settling in full removes the due-date reminder.
    ref.read(entityRemindersProvider).syncDebt(
      widget.record.copyWith(settlements: [...widget.record.settlements, settlement]),
    );
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
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(l10n.addSettlement, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              label: l10n.settlementAmount,
              maxMinor: widget.record.outstandingMinor,
              autofocus: true,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => _amount.text = Money.toEditable(widget.record.outstandingMinor),
                child: Text(l10n.settleFull),
              ),
            ),
            DateField(label: l10n.date, value: _date, onChanged: (d) => setState(() => _date = d ?? _date)),
            const SizedBox(height: 12),
            PickerField<String>(
              label: l10n.moneyMovedThrough,
              value: _accountId,
              allowNone: true,
              noneLabel: l10n.cashUntracked,
              options: [for (final a in accounts) PickerOption(a.id, a.displayName, icon: Icons.account_balance_rounded)],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _note, decoration: InputDecoration(labelText: l10n.notes)),
            const SizedBox(height: 16),
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
