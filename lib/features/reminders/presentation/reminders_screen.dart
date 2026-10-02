import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/utils/recurrence.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/reminders/domain/reminder.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/form_fields.dart';
import 'package:expensetrackerpro/shared/widgets/offset_selector.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

IconData reminderIcon(ReminderType type) => switch (type) {
  ReminderType.loanEmi => Icons.account_balance_wallet_rounded,
  ReminderType.creditCardPayment => Icons.credit_card_rounded,
  ReminderType.borrowed => Icons.call_received_rounded,
  ReminderType.lent => Icons.call_made_rounded,
  ReminderType.gym => Icons.fitness_center_rounded,
  ReminderType.meeting => Icons.groups_rounded,
  ReminderType.insurance => Icons.verified_user_rounded,
  ReminderType.subscription => Icons.subscriptions_rounded,
  ReminderType.bill => Icons.receipt_rounded,
  ReminderType.custom => Icons.notifications_rounded,
};

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminders = ref.watch(remindersProvider);
    final enabled = ref.watch(notificationsEnabledProvider);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alert_rounded),
        label: Text(l10n.reminderNew),
        onPressed: () => pushPage(context, const ReminderFormScreen()),
      ),
      body: AsyncView<List<Reminder>>(
        value: reminders,
        onRetry: () => ref.invalidate(remindersProvider),
        data: (list) {
          final withNext = [
            for (final r in list) (r, r.enabled ? r.nextOccurrence(now) : null),
          ];
          final upcoming = withNext.where((e) => e.$2 != null).toList()
            ..sort((a, b) => a.$2!.compareTo(b.$2!));
          final inactive = withNext.where((e) => e.$2 == null).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (enabled.value == false)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_off_rounded),
                    title: Text(l10n.notificationsOff),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(notificationServiceProvider).requestPermission();
                        ref.invalidate(notificationsEnabledProvider);
                        ref.read(notificationSyncProvider).resync();
                      },
                      child: Text(l10n.notificationsEnable),
                    ),
                  ),
                ),
              if (list.isEmpty)
                EmptyState(icon: Icons.notifications_none_rounded, message: l10n.remindersEmpty),
              if (upcoming.isNotEmpty) _Header(l10n.remindersUpcoming),
              for (final (r, next) in upcoming) _ReminderTile(reminder: r, next: next),
              if (inactive.isNotEmpty) _Header(l10n.remindersInactive),
              for (final (r, _) in inactive) _ReminderTile(reminder: r, next: null),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
    ),
  );
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder, required this.next});

  final Reminder reminder;
  final DateTime? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => pushPage(context, ReminderFormScreen(initial: reminder)),
        leading: CircleAvatar(child: Icon(reminderIcon(reminder.type))),
        title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([
          l10n.recurrence(reminder.recurrence),
          next == null
              ? l10n.reminderEnded
              : l10n.reminderNext(DateFormat.MMMEd(locale).add_jm().format(next!)),
        ].join(' · ')),
        trailing: Switch(
          value: reminder.enabled,
          onChanged: (v) => ref.read(reminderRepositoryProvider).save(
            reminder.copyWith(enabled: v, updatedAt: DateTime.now()),
          ),
        ),
      ),
    );
  }
}

class ReminderFormScreen extends ConsumerStatefulWidget {
  const ReminderFormScreen({super.key, this.initial});
  final Reminder? initial;

  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _interval = TextEditingController(text: '${widget.initial?.recurrence.interval ?? 1}');
  late ReminderType _type = widget.initial?.type ?? ReminderType.custom;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late TimeOfDay _time = widget.initial == null
      ? const TimeOfDay(hour: 9, minute: 0)
      : TimeOfDay(hour: widget.initial!.hour, minute: widget.initial!.minute);
  late RecurrenceFrequency _frequency = widget.initial?.recurrence.frequency ?? RecurrenceFrequency.once;
  late DateTime? _until = widget.initial?.recurrence.until;
  late List<int> _offsets = widget.initial?.offsetsMinutes ?? const [0];
  late bool _enabled = widget.initial?.enabled ?? true;

  bool get _isEntity => widget.initial?.isEntityReminder ?? false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _interval.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(reminderRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final recurrence = Recurrence(
      frequency: _frequency,
      interval: int.tryParse(_interval.text)?.clamp(1, 365) ?? 1,
      until: _until,
    );
    final offsets = _offsets.isEmpty ? const [0] : _offsets;
    final reminder = initial == null
        ? Reminder(
            id: repo.newId(),
            title: _title.text.trim(),
            description: _description.text.trim(),
            type: _type,
            date: _date,
            hour: _time.hour,
            minute: _time.minute,
            recurrence: recurrence,
            offsetsMinutes: offsets,
            enabled: _enabled,
            createdAt: now,
            updatedAt: now,
          )
        : _isEntity
        // Entity reminders: only time, alerts and on/off are user-owned.
        ? initial.copyWith(
            hour: _time.hour,
            minute: _time.minute,
            offsetsMinutes: offsets,
            enabled: _enabled,
            updatedAt: now,
          )
        : initial.copyWith(
            title: _title.text.trim(),
            description: _description.text.trim(),
            type: _type,
            date: _date,
            hour: _time.hour,
            minute: _time.minute,
            recurrence: recurrence,
            offsetsMinutes: offsets,
            enabled: _enabled,
            updatedAt: now,
          );
    // Notification permission is requested by NotificationSync once the
    // reminder streams back, so saving never waits on a system dialog.
    repo.save(reminder);
    Navigator.pop(context);
    showMessage(context, context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final initial = widget.initial;
    final module = switch (initial?.entityType) {
      ReminderEntityType.loan => l10n.moduleLoans,
      ReminderEntityType.creditCard => l10n.moduleCards,
      ReminderEntityType.borrowLend => l10n.moduleBorrowLend,
      _ => null,
    };
    final userTypes = ReminderType.values.where(
      (t) => !{ReminderType.loanEmi, ReminderType.creditCardPayment, ReminderType.borrowed, ReminderType.lent}.contains(t),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(initial == null ? l10n.reminderNew : l10n.reminderEdit),
        actions: [
          if (initial != null && !_isEntity)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (!await confirmDelete(context, initial.title)) return;
                ref.read(reminderRepositoryProvider).delete(initial.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (module != null)
              Card(
                child: ListTile(leading: const Icon(Icons.link_rounded), title: Text(l10n.reminderLinked(module))),
              ),
            TextFormField(
              controller: _title,
              enabled: !_isEntity,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.reminderTitleLabel, hintText: l10n.reminderTitleHint),
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            if (!_isEntity) ...[
              PickerField<ReminderType>(
                label: l10n.reminderTypeLabel,
                value: _type,
                options: [for (final t in userTypes) PickerOption(t, l10n.reminderType(t), icon: reminderIcon(t))],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: 12),
              DateField(label: l10n.date, value: _date, onChanged: (d) => setState(() => _date = d ?? _date)),
              const SizedBox(height: 12),
            ],
            TimeField(label: l10n.time, value: _time, onChanged: (t) => setState(() => _time = t)),
            if (!_isEntity) ...[
              const SizedBox(height: 16),
              Text(l10n.reminderRepeat, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in RecurrenceFrequency.values)
                    ChoiceChip(
                      label: Text(l10n.frequency(f)),
                      selected: _frequency == f,
                      onSelected: (_) => setState(() => _frequency = f),
                    ),
                ],
              ),
              if (_frequency != RecurrenceFrequency.once) ...[
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
                        helper: l10n.recurrence(Recurrence(frequency: _frequency, interval: int.tryParse(_interval.text) ?? 1)),
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
              ],
            ],
            const SizedBox(height: 16),
            Text(l10n.reminderNotify, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            OffsetSelector(selected: _offsets, onChanged: (v) => setState(() => _offsets = v)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reminderEnabled),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
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
