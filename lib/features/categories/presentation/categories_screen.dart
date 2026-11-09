import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/features/categories/application/category_providers.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/categories/domain/custom_category.dart';
import 'package:kept/features/categories/presentation/category_editor_sheet.dart';
import 'package:kept/shared/widgets/dialogs.dart';
import 'package:kept/shared/widgets/states.dart';

/// Manage categories: see the built-in ones and add, edit, archive or
/// delete your own.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final custom = ref.watch(customCategoriesProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.categoriesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.txTypeExpense),
              Tab(text: l10n.txTypeIncome),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.categoryAdd),
            onPressed: () {
              final tab = DefaultTabController.of(context).index;
              CategoryEditorSheet.show(
                context,
                kind: tab == 0 ? CategoryKind.expense : CategoryKind.income,
              );
            },
          ),
        ),
        body: AsyncView<List<CustomCategory>>(
          value: custom,
          onRetry: () => ref.invalidate(customCategoriesProvider),
          data: (list) => TabBarView(
            children: [
              _KindList(kind: CategoryKind.expense, custom: list),
              _KindList(kind: CategoryKind.income, custom: list),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindList extends ConsumerWidget {
  const _KindList({required this.kind, required this.custom});

  final CategoryKind kind;
  final List<CustomCategory> custom;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CustomCategory c,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(categoryRepositoryProvider);
    if (await repo.isInUse(c.id)) {
      if (context.mounted) showMessage(context, l10n.categoryInUse);
      return;
    }
    if (!context.mounted || !await confirmDelete(context, c.name)) return;
    repo.delete(c.id);
    if (context.mounted) showMessage(context, l10n.categoryDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mine = custom.where((c) => c.kind == kind).toList();
    final builtIn = kind == CategoryKind.income
        ? Categories.income
        : Categories.expense;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        header(l10n.categoryYours),
        if (mine.isEmpty)
          EmptyState(
            icon: Icons.category_rounded,
            message: l10n.categoryYoursEmpty,
            compact: true,
          ),
        for (final c in mine)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => CategoryEditorSheet.show(context, initial: c),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(c.icon, color: c.color),
              ),
              title: Text(
                c.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: c.archived ? Text(l10n.categoryArchived) : null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  final repo = ref.read(categoryRepositoryProvider);
                  if (v == 'edit') {
                    CategoryEditorSheet.show(context, initial: c);
                  } else if (v == 'archive') {
                    repo.save(
                      c.copyWith(
                        archived: !c.archived,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  } else if (v == 'delete') {
                    _delete(context, ref, c);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(
                      c.archived ? l10n.categoryRestore : l10n.categoryArchive,
                    ),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
            ),
          ),
        if (mine.any((c) => c.archived))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.categoryArchivedNote,
              style: theme.textTheme.bodySmall,
            ),
          ),
        header(l10n.categoryBuiltIn),
        for (final c in builtIn)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(c.icon, color: c.color, size: 22),
            ),
            title: Text(l10n.categoryLabel(c.id)),
          ),
      ],
    );
  }
}
