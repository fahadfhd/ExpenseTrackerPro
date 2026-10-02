import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Preset reminder offsets in minutes: at the time, 1 h, 1, 2 and 7 days.
const offsetPresets = [0, 60, 1440, 2 * 1440, 7 * 1440];

String offsetLabel(AppLocalizations l10n, int minutes) {
  if (minutes == 0) return l10n.reminderOffsetAtTime;
  if (minutes % 1440 == 0) return l10n.reminderOffsetDays('${minutes ~/ 1440}');
  if (minutes % 60 == 0) return l10n.reminderOffsetHours('${minutes ~/ 60}');
  return l10n.reminderOffsetMinutes('$minutes');
}

/// Multi-select chips for "notify me N before". Supports custom day
/// offsets in addition to the presets.
class OffsetSelector extends StatelessWidget {
  const OffsetSelector({super.key, required this.selected, required this.onChanged});

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  Future<void> _addCustom(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reminderOffsetCustomTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: Text(l10n.add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (days == null || days < 0 || days > 365) return;
    onChanged(({...selected, days * 1440}.toList()..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = {...offsetPresets, ...selected}.toList()..sort();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in all)
          FilterChip(
            label: Text(offsetLabel(l10n, m)),
            selected: selected.contains(m),
            onSelected: (on) {
              final next = {...selected};
              on ? next.add(m) : next.remove(m);
              onChanged(next.toList()..sort());
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.reminderOffsetCustom),
          onPressed: () => _addCustom(context),
        ),
      ],
    );
  }
}
