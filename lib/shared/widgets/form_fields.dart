import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/money/money.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Currency input that validates into minor units.
class AmountField extends ConsumerWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label,
    this.required = true,
    this.allowZero = false,
    this.autofocus = false,
    this.maxMinor,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final bool required;
  final bool allowZero;
  final bool autofocus;

  /// Optional upper bound (e.g. outstanding amount for a settlement).
  final int? maxMinor;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final symbol = ref.watch(currencyFormatterProvider).symbol;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label ?? l10n.amount,
        prefixText: '$symbol ',
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return required ? l10n.invalidAmount : null;
        final minor = Money.parse(text);
        if (minor == null || (!allowZero && minor <= 0)) {
          return l10n.invalidAmount;
        }
        if (maxMinor != null && minor > maxMinor!) {
          return l10n.valueBetween(
            ref.read(currencyFormatterProvider).format(allowZero ? 0 : 1),
            ref.read(currencyFormatterProvider).format(maxMinor!),
          );
        }
        return null;
      },
    );
  }
}

/// Numeric input (rates, distances, quantities) with optional bounds.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.min,
    this.max,
    this.integer = false,
    this.required = true,
    this.helper,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final double? min;
  final double? max;
  final bool integer;
  final bool required;
  final String? helper;
  final ValueChanged<String>? onChanged;

  static double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', ''));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.,]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
        helperMaxLines: 3,
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return required ? l10n.invalidNumber : null;
        final number = parse(text);
        if (number == null) return l10n.invalidNumber;
        if ((min != null && number < min!) || (max != null && number > max!)) {
          String fmt(double? v) => v == null
              ? '∞'
              : (v == v.roundToDouble() ? v.toInt().toString() : '$v');
          return l10n.valueBetween(fmt(min), fmt(max));
        }
        return null;
      },
    );
  }
}

/// Tappable field that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = value == null
        ? l10n.noDate
        : DateFormat.yMMMEd(Localizations.localeOf(context).toString())
              .format(value!);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(now.year - 30),
          lastDate: lastDate ?? DateTime(now.year + 40),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: clearable && value != null
              ? IconButton(
                  tooltip: l10n.clear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(text),
      ),
    );
  }
}

class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(value.format(context)),
      ),
    );
  }
}

class PickerOption<T> {
  const PickerOption(this.value, this.label, {this.icon, this.subtitle});
  final T value;
  final String label;
  final IconData? icon;
  final String? subtitle;
}

/// A field that shows the current choice and opens a bottom-sheet list.
/// Better than a dropdown for long lists and large touch targets.
class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allowNone = false,
    this.noneLabel,
    this.errorText,
  });

  final String label;
  final T? value;
  final List<PickerOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool allowNone;
  final String? noneLabel;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = options.where((o) => o.value == value).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final result = await showModalBottomSheet<_Picked<T>>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _PickerSheet<T>(
            title: label,
            options: options,
            selected: value,
            noneLabel: allowNone ? (noneLabel ?? l10n.none) : null,
          ),
        );
        if (result != null) onChanged(result.value);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: selected?.icon == null ? null : Icon(selected!.icon),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          selected?.label ?? (noneLabel ?? l10n.none),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _Picked<T> {
  const _Picked(this.value);
  final T? value;
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.noneLabel,
  });

  final String title;
  final List<PickerOption<T>> options;
  final T? selected;
  final String? noneLabel;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: options.length > 6 ? 0.7 : 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (noneLabel != null)
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text(noneLabel!),
              trailing: selected == null ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(context, _Picked<T>(null)),
            ),
          for (final option in options)
            ListTile(
              leading: option.icon == null ? null : Icon(option.icon),
              title: Text(option.label),
              subtitle: option.subtitle == null ? null : Text(option.subtitle!),
              selected: option.value == selected,
              trailing: option.value == selected
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(context, _Picked<T>(option.value)),
            ),
        ],
      ),
    );
  }
}
