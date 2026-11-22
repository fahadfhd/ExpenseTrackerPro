import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/transactions/domain/transaction.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;
import 'form_selection_test.dart' show openAddForm, isSelected;

Future<void> seedCategory(
  TestEnv env, {
  List<Map<String, String>> subcategories = const [],
}) async {
  final now = DateTime.now();
  await env.db
      .collection('users')
      .doc(env.uid)
      .collection('categories')
      .doc('custom_a')
      .set({
        'name': 'Pets',
        'kind': 'expense',
        'iconKey': 'pets',
        'colorValue': 0xFFE07A3F,
        'archived': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'subcategories': subcategories,
      });
}

/// Long-presses the category (ChoiceChip) or subcategory (FilterChip)
/// labelled [label] in the open form.
Future<void> longPressChip(WidgetTester tester, String label) async {
  final chip = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ChoiceChip || w is FilterChip),
  );
  await reveal(tester, chip);
  await tester.longPress(chip.first);
  await settle(tester);
}

/// Types [name] into the subcategory dialog and saves it.
Future<void> nameSubcategory(WidgetTester tester, String name) async {
  final field = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, name);
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('Save')),
  );
  await settle(tester);
}

void main() {
  tearDown(() => Categories.setCustom(const []));

  testWidgets('create a category with subcategories, rename and delete '
      'one, then use it', (tester) async {
    final env = await pumpApp(tester);
    await openAddForm(tester);
    await tapText(tester, 'New');
    await tester.enterText(find.byType(TextField).last, 'Pets');

    await tapText(tester, 'Add subcategory');
    await nameSubcategory(tester, 'Food');
    await tapText(tester, 'Add subcategory');
    await nameSubcategory(tester, 'Vet');
    await tapText(tester, 'Add subcategory');
    await nameSubcategory(tester, 'Toys');

    // Duplicate names are rejected within a category.
    await tapText(tester, 'Add subcategory');
    await nameSubcategory(tester, ' vet ');
    expect(
      find.text('This category already has a subcategory with this name'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    // Rename one and delete another (never saved, so no in-use check).
    await tapText(tester, 'Vet');
    await tapText(tester, 'Rename');
    await nameSubcategory(tester, 'Vet visits');
    await tapText(tester, 'Toys');
    await tapText(tester, 'Delete');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await settle(tester);

    await tapText(tester, 'Save');
    final stored = (await env.docs('categories')).single;
    final subs = (stored['subcategories'] as List).cast<Map>();
    expect(subs.map((s) => s['name']), ['Food', 'Vet visits']);
    final id = stored['id'] as String;
    for (final s in subs) {
      expect(s['id'], startsWith('$id.sub_'));
    }

    // Selected straight away, with its subcategories offered.
    expect(await isSelected(tester, 'Pets'), isTrue);
    final vet = find.widgetWithText(FilterChip, 'Vet visits');
    await reveal(tester, vet);
    await tester.tap(vet);
    await settle(tester);

    await enterField(tester, 'Amount', '450');
    await tapText(tester, 'Save');
    final tx = (await env.docs('transactions')).single;
    expect(tx['categoryId'], id);
    expect(tx['subCategoryId'], subs[1]['id']);
    expect(find.text('Vet visits'), findsWidgets);
  });

  testWidgets('long-press a custom category in the form to delete it', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedCategory(env);
    await settle(tester);
    await openAddForm(tester);
    await chooseCategory(tester, 'Pets');

    await longPressChip(tester, 'Pets');
    expect(find.text('Archive'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await settle(tester);

    expect(await env.docs('categories'), isEmpty);
    expect(find.widgetWithText(ChoiceChip, 'Pets'), findsNothing);
  });

  testWidgets('long-press a built-in category explains it is fixed', (
    tester,
  ) async {
    await pumpApp(tester);
    await openAddForm(tester);
    await longPressChip(tester, 'Food');
    expect(find.textContaining("can't be edited or deleted"), findsOneWidget);
  });

  testWidgets('add, rename and delete subcategories from the form', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedCategory(env);
    await settle(tester);
    await openAddForm(tester);
    await chooseCategory(tester, 'Pets');

    final add = find.byTooltip('Add subcategory');
    await reveal(tester, add);
    await tester.tap(add);
    await settle(tester);
    await nameSubcategory(tester, 'Grooming');
    var subs = (await env.docs('categories')).single['subcategories'] as List;
    expect(subs.single['name'], 'Grooming');
    // The new subcategory is selected.
    final chip = find.widgetWithText(FilterChip, 'Grooming');
    await reveal(tester, chip);
    expect(tester.widget<FilterChip>(chip).selected, isTrue);

    await longPressChip(tester, 'Grooming');
    await tapText(tester, 'Rename');
    await nameSubcategory(tester, 'Haircut');
    subs = (await env.docs('categories')).single['subcategories'] as List;
    expect(subs.single['name'], 'Haircut');

    await longPressChip(tester, 'Haircut');
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await settle(tester);
    subs = (await env.docs('categories')).single['subcategories'] as List;
    expect(subs, isEmpty);
    expect(find.widgetWithText(FilterChip, 'Haircut'), findsNothing);
  });

  testWidgets('a subcategory in use cannot be deleted', (tester) async {
    final env = await pumpApp(tester);
    await seedCategory(
      env,
      subcategories: [
        {'id': 'custom_a.sub_1', 'name': 'Vet'},
      ],
    );
    final now = DateTime.now();
    await f.seedTransaction(
      env,
      Transaction(
        id: 't',
        date: DateTime(now.year, now.month, 1, 9),
        amountMinor: 1000,
        type: TransactionType.expense,
        categoryId: 'custom_a',
        subCategoryId: 'custom_a.sub_1',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await settle(tester);
    await openAddForm(tester);
    await chooseCategory(tester, 'Pets');
    await longPressChip(tester, 'Vet');
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    expect(find.textContaining("can't be deleted"), findsOneWidget);
    final subs = (await env.docs('categories')).single['subcategories'] as List;
    expect(subs, hasLength(1));
  });
}
