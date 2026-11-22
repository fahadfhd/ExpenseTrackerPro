import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/categories/domain/custom_category.dart';
import 'package:kept/features/categories/presentation/category_editor_sheet.dart';
import 'package:kept/shared/widgets/dialogs.dart';

/// What the user did from a category's or subcategory's options sheet.
enum CategoryAction { edited, archived, restored, deleted }

/// A short notice shown as a dialog: these actions run from inside modal
/// sheets, where a snackbar would sit hidden behind the sheet.
Future<void> showNotice(BuildContext context, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );

/// Deletes [category] after confirmation, unless something still refers to
/// it. Returns whether it was deleted.
Future<bool> deleteCustomCategory(
  BuildContext context,
  WidgetRef ref,
  CustomCategory category,
) async {
  final l10n = context.l10n;
  final repo = ref.read(categoryRepositoryProvider);
  if (await repo.isInUse(category.id)) {
    if (context.mounted) await showNotice(context, l10n.categoryInUse);
    return false;
  }
  if (!context.mounted || !await confirmDelete(context, category.name)) {
    return false;
  }
  repo.delete(category.id);
  return true;
}

/// Long-press menu for one of the user's own categories: edit, archive or
/// restore, delete.
Future<CategoryAction?> showCategoryActions(
  BuildContext context,
  WidgetRef ref,
  CustomCategory category,
) async {
  final l10n = context.l10n;
  final choice = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(category.icon, color: category.color),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: Text(l10n.edit),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: Icon(
              category.archived
                  ? Icons.unarchive_rounded
                  : Icons.archive_rounded,
            ),
            title: Text(
              category.archived ? l10n.categoryRestore : l10n.categoryArchive,
            ),
            onTap: () => Navigator.pop(context, 'archive'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return null;
  switch (choice) {
    case 'edit':
      final saved = await CategoryEditorSheet.show(context, initial: category);
      return saved == null ? null : CategoryAction.edited;
    case 'archive':
      final updated = category.copyWith(
        archived: !category.archived,
        updatedAt: DateTime.now(),
      );
      ref.read(categoryRepositoryProvider).save(updated);
      Categories.upsertCustom(updated.toCategory());
      return updated.archived
          ? CategoryAction.archived
          : CategoryAction.restored;
    case 'delete':
      final deleted = await deleteCustomCategory(context, ref, category);
      return deleted ? CategoryAction.deleted : null;
  }
  return null;
}

/// Asks for a subcategory name, checked against its siblings. Returns the
/// trimmed name, or null when cancelled.
Future<String?> showSubcategoryNameDialog(
  BuildContext context, {
  required Iterable<String> siblingNames,
  String? initial,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _SubcategoryNameDialog(siblingNames: siblingNames, initial: initial),
);

class _SubcategoryNameDialog extends StatefulWidget {
  const _SubcategoryNameDialog({required this.siblingNames, this.initial});

  final Iterable<String> siblingNames;
  final String? initial;

  @override
  State<_SubcategoryNameDialog> createState() => _SubcategoryNameDialogState();
}

class _SubcategoryNameDialogState extends State<_SubcategoryNameDialog> {
  late final _name = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final issue = CategoryNames.validate(
      _name.text,
      builtInLabels: const [],
      existing: widget.siblingNames,
    );
    if (issue != null) {
      setState(
        () => _error = switch (issue) {
          CategoryNameIssue.empty => l10n.categoryNameEmpty,
          CategoryNameIssue.tooLong => l10n.categoryNameTooLong(
            '${CustomCategory.maxNameLength}',
          ),
          CategoryNameIssue.duplicate => l10n.subcategoryNameDuplicate,
        },
      );
      return;
    }
    Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.subcategoryAdd : l10n.subcategoryRename,
      ),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: CustomCategory.maxNameLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.subcategoryNameLabel,
          errorText: _error,
          counterText: '',
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

/// Long-press menu for a subcategory: rename or delete. Returns the
/// subcategory list to keep, or null when nothing changed. A subcategory
/// still used by a transaction or recurring rule can't be deleted, so only
/// pass [checkInUse] false for one that has never been saved.
Future<List<CustomSubcategory>?> showSubcategoryActions(
  BuildContext context,
  WidgetRef ref, {
  required List<CustomSubcategory> subcategories,
  required CustomSubcategory target,
  bool checkInUse = true,
}) async {
  final l10n = context.l10n;
  final choice = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              target.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: Text(l10n.rename),
            onTap: () => Navigator.pop(context, 'rename'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return null;
  switch (choice) {
    case 'rename':
      final name = await showSubcategoryNameDialog(
        context,
        initial: target.name,
        siblingNames: [
          for (final s in subcategories)
            if (s.id != target.id) s.name,
        ],
      );
      if (name == null || name == target.name) return null;
      return [
        for (final s in subcategories)
          s.id == target.id ? s.copyWith(name: name) : s,
      ];
    case 'delete':
      if (checkInUse &&
          await ref
              .read(categoryRepositoryProvider)
              .isSubcategoryInUse(target.id)) {
        if (context.mounted) await showNotice(context, l10n.subcategoryInUse);
        return null;
      }
      if (!context.mounted || !await confirmDelete(context, target.name)) {
        return null;
      }
      return [
        for (final s in subcategories)
          if (s.id != target.id) s,
      ];
  }
  return null;
}
