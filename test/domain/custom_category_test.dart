import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/categories/domain/custom_category.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/transactions/domain/transaction_validator.dart';

CustomCategory _custom(String id, CategoryKind kind, {bool archived = false}) =>
    CustomCategory(
      id: id,
      name: 'Mine',
      kind: kind,
      iconKey: 'pets',
      colorValue: 0xFF3FA796,
      archived: archived,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Transaction _tx(TransactionType type, String categoryId) => Transaction(
  id: 't',
  date: DateTime(2026, 3, 1),
  amountMinor: 100,
  type: type,
  categoryId: categoryId,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  tearDown(() => Categories.setCustom(const []));

  group('CategoryNames.validate', () {
    CategoryNameIssue? check(String name) => CategoryNames.validate(
      name,
      builtInLabels: ['Food', 'Fuel'],
      existing: ['Pets'],
    );

    test('accepts a new name', () => expect(check('Coffee'), isNull));
    test('rejects empty and blank', () {
      expect(check(''), CategoryNameIssue.empty);
      expect(check('   '), CategoryNameIssue.empty);
    });
    test('rejects names that are too long', () {
      expect(check('x' * 31), CategoryNameIssue.tooLong);
      expect(check('x' * 30), isNull);
    });
    test('rejects duplicates ignoring case and spaces', () {
      expect(check(' food '), CategoryNameIssue.duplicate);
      expect(check('PETS'), CategoryNameIssue.duplicate);
    });
  });

  group('registry', () {
    test('resolves custom ids and falls back for unknown ones', () {
      Categories.setCustom([
        _custom('custom_a', CategoryKind.income).toCategory(),
      ]);
      final c = Categories.byId('custom_a');
      expect(c.isCustom, isTrue);
      expect(c.kind, CategoryKind.income);
      expect(Categories.customName('custom_a'), 'Mine');
      expect(Categories.customName('food'), isNull);
      expect(Categories.byId('custom_missing').id, Categories.otherExpenseId);
    });

    test('selectable hides archived unless asked, built-ins first', () {
      Categories.setCustom([
        _custom('custom_a', CategoryKind.expense).toCategory(),
        _custom('custom_b', CategoryKind.expense, archived: true).toCategory(),
        _custom('custom_c', CategoryKind.income).toCategory(),
      ]);
      final expense = Categories.selectable(CategoryKind.expense);
      expect(expense.map((c) => c.id), contains('custom_a'));
      expect(expense.map((c) => c.id), isNot(contains('custom_b')));
      expect(expense.first.id, Categories.expense.first.id);
      expect(
        Categories.selectable(
          CategoryKind.expense,
          includeArchived: true,
        ).map((c) => c.id),
        contains('custom_b'),
      );
      expect(
        Categories.selectable(CategoryKind.income).map((c) => c.id),
        contains('custom_c'),
      );
    });

    test('registry is cleared by setCustom(empty)', () {
      Categories.setCustom([
        _custom('custom_a', CategoryKind.expense).toCategory(),
      ]);
      Categories.setCustom(const []);
      expect(Categories.exists('custom_a'), isFalse);
    });
  });

  group('validation with custom categories', () {
    test('a custom income category is valid for income, not for expense', () {
      Categories.setCustom([
        _custom('custom_inc', CategoryKind.income).toCategory(),
      ]);
      expect(
        TransactionValidator.validate(
          _tx(TransactionType.income, 'custom_inc'),
        ),
        isEmpty,
      );
      expect(
        TransactionValidator.validate(
          _tx(TransactionType.expense, 'custom_inc'),
        ),
        contains(TransactionIssue.categoryMismatch),
      );
    });

    test('a custom expense category is valid for expenses', () {
      Categories.setCustom([
        _custom('custom_exp', CategoryKind.expense).toCategory(),
      ]);
      expect(
        TransactionValidator.validate(
          _tx(TransactionType.expense, 'custom_exp'),
        ),
        isEmpty,
      );
    });
  });

  test('model round-trips and tolerates unknown icons', () {
    final c = _custom('custom_a', CategoryKind.expense);
    final back = CustomCategory.fromMap('custom_a', c.toMap());
    expect(back.name, 'Mine');
    expect(back.kind, CategoryKind.expense);
    expect(back.icon, categoryIcons['pets']);
    final odd = CustomCategory.fromMap('x', {
      'name': 'Z',
      'iconKey': 'does-not-exist',
    });
    expect(odd.icon, categoryIcons[defaultCategoryIconKey]);
  });
}
