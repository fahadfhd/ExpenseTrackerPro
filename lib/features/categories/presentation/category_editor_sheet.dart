import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/categories/domain/custom_category.dart';
import 'package:kept/shared/widgets/dialogs.dart';

/// Create or edit one of the user's own categories. Pops with the saved
/// category's id, so callers (the transaction form) can select it at once.
class CategoryEditorSheet extends ConsumerStatefulWidget {
  const CategoryEditorSheet({super.key, this.initial, this.kind});

  final CustomCategory? initial;

  /// Preset type for a new category (the form passes the kind being
  /// entered). When null the user chooses.
  final CategoryKind? kind;

  static Future<String?> show(
    BuildContext context, {
    CustomCategory? initial,
    CategoryKind? kind,
  }) => showFormSheet<String>(
    context,
    CategoryEditorSheet(initial: initial, kind: kind),
  );

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late CategoryKind _kind =
      widget.initial?.kind ?? widget.kind ?? CategoryKind.expense;
  late String _iconKey = widget.initial?.iconKey ?? defaultCategoryIconKey;
  late int _color = widget.initial?.colorValue ?? categoryColors.first;
  CategoryNameIssue? _issue;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Names that would clash: built-in labels and the user's other
  /// categories of the same kind.
  CategoryNameIssue? _check(AppLocalizations l10n) {
    final custom = ref.read(customCategoriesProvider).value ?? const [];
    return CategoryNames.validate(
      _name.text,
      builtInLabels: [
        for (final c
            in _kind == CategoryKind.income
                ? Categories.income
                : Categories.expense)
          l10n.categoryLabel(c.id),
      ],
      existing: [
        for (final c in custom)
          if (c.kind == _kind && c.id != widget.initial?.id) c.name,
      ],
    );
  }

  void _save() {
    final l10n = context.l10n;
    final issue = _check(l10n);
    setState(() => _issue = issue);
    if (issue != null) return;
    final repo = ref.read(categoryRepositoryProvider);
    final now = DateTime.now();
    final initial = widget.initial;
    final category = initial == null
        ? CustomCategory(
            id: repo.newId(),
            name: _name.text.trim(),
            kind: _kind,
            iconKey: _iconKey,
            colorValue: _color,
            createdAt: now,
            updatedAt: now,
          )
        : initial.copyWith(
            name: _name.text.trim(),
            iconKey: _iconKey,
            colorValue: _color,
            updatedAt: now,
          );
    repo.save(category);
    Categories.upsertCustom(category.toCategory());
    Navigator.pop(context, category.id);
  }

  String? _message(AppLocalizations l10n) => switch (_issue) {
    CategoryNameIssue.empty => l10n.categoryNameEmpty,
    CategoryNameIssue.tooLong => l10n.categoryNameTooLong(
      '${CustomCategory.maxNameLength}',
    ),
    CategoryNameIssue.duplicate => l10n.categoryNameDuplicate,
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preview = Color(_color);
    return SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(
            _isEdit ? l10n.categoryEdit : l10n.categoryAdd,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: preview.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(categoryIcons[_iconKey], color: preview),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: !_isEdit,
                  maxLength: CustomCategory.maxNameLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.categoryNameLabel,
                    hintText: l10n.categoryNameHint,
                    errorText: _message(l10n),
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (_issue != null) setState(() => _issue = null);
                  },
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          if (widget.kind == null || _isEdit) ...[
            const SizedBox(height: 16),
            Text(l10n.categoryTypeLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<CategoryKind>(
              segments: [
                ButtonSegment(
                  value: CategoryKind.expense,
                  label: Text(l10n.txTypeExpense),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text(l10n.txTypeIncome),
                ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              // The type is fixed once created: transactions already use it.
              onSelectionChanged: _isEdit
                  ? null
                  : (s) => setState(() {
                      _kind = s.first;
                      if (_issue != null) _issue = _check(l10n);
                    }),
            ),
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.categoryTypeLocked,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(l10n.categoryColorLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in categoryColors)
                Semantics(
                  button: true,
                  selected: c == _color,
                  label: l10n.categoryColorLabel,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == _color
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: c == _color
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.categoryIconLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in categoryIcons.entries)
                Semantics(
                  button: true,
                  selected: entry.key == _iconKey,
                  label: l10n.categoryIconLabel,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _iconKey = entry.key),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: entry.key == _iconKey
                            ? preview.withValues(alpha: 0.18)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: entry.key == _iconKey
                              ? preview
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color: entry.key == _iconKey
                            ? preview
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
