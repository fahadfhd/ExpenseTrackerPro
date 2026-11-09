import 'package:flutter/material.dart';

enum CategoryKind { expense, income }

class Subcategory {
  const Subcategory(this.id);
  final String id;
}

/// A transaction category: built-in (localized label, fixed id) or created
/// by the user (stored in Firestore, [customName] holds its label).
///
/// Ids are persisted in transactions and budgets, so they must never change.
class Category {
  const Category({
    required this.id,
    required this.kind,
    required this.icon,
    required this.color,
    this.subcategories = const [],
    this.customName,
    this.archived = false,
  });

  final String id;
  final CategoryKind kind;
  final IconData icon;
  final Color color;
  final List<Subcategory> subcategories;

  /// Set only for user-created categories.
  final String? customName;

  /// Archived custom categories are hidden from pickers but still resolve,
  /// so existing transactions keep their name and icon.
  final bool archived;

  bool get isCustom => customName != null;
}

abstract final class Categories {
  static const otherExpenseId = 'other';
  static const otherIncomeId = 'other_income';
  static const transferId = 'transfer';
  static const debtId = 'debt';
  static const loanId = 'loan_emi';
  static const cardPaymentId = 'card_payment';
  static const fuelId = 'transport';
  static const fuelSubId = 'transport.fuel';

  static const expense = <Category>[
    Category(
      id: 'food',
      kind: CategoryKind.expense,
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE07A3F),
      subcategories: [
        Subcategory('food.groceries'),
        Subcategory('food.dining'),
        Subcategory('food.delivery'),
      ],
    ),
    Category(
      id: 'transport',
      kind: CategoryKind.expense,
      icon: Icons.directions_car_rounded,
      color: Color(0xFF4C7BD9),
      subcategories: [
        Subcategory(fuelSubId),
        Subcategory('transport.public'),
        Subcategory('transport.cab'),
        Subcategory('transport.parking'),
        Subcategory('transport.service'),
      ],
    ),
    Category(
      id: 'shopping',
      kind: CategoryKind.expense,
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFB65FCF),
      subcategories: [
        Subcategory('shopping.clothing'),
        Subcategory('shopping.electronics'),
        Subcategory('shopping.home'),
      ],
    ),
    Category(
      id: 'bills',
      kind: CategoryKind.expense,
      icon: Icons.receipt_rounded,
      color: Color(0xFFD9A93F),
      subcategories: [
        Subcategory('bills.electricity'),
        Subcategory('bills.water'),
        Subcategory('bills.internet'),
        Subcategory('bills.phone'),
      ],
    ),
    Category(
      id: 'housing',
      kind: CategoryKind.expense,
      icon: Icons.home_rounded,
      color: Color(0xFF3FA796),
      subcategories: [
        Subcategory('housing.rent'),
        Subcategory('housing.maintenance'),
      ],
    ),
    Category(
      id: 'health',
      kind: CategoryKind.expense,
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFD9534F),
      subcategories: [
        Subcategory('health.medical'),
        Subcategory('health.pharmacy'),
        Subcategory('health.fitness'),
      ],
    ),
    Category(
      id: 'entertainment',
      kind: CategoryKind.expense,
      icon: Icons.movie_rounded,
      color: Color(0xFF7A6FF0),
      subcategories: [
        Subcategory('entertainment.subscriptions'),
        Subcategory('entertainment.outings'),
        Subcategory('entertainment.travel'),
      ],
    ),
    Category(
      id: 'education',
      kind: CategoryKind.expense,
      icon: Icons.school_rounded,
      color: Color(0xFF2F9BD6),
    ),
    Category(
      id: 'insurance',
      kind: CategoryKind.expense,
      icon: Icons.verified_user_rounded,
      color: Color(0xFF5B8C5A),
    ),
    Category(
      id: 'personal',
      kind: CategoryKind.expense,
      icon: Icons.spa_rounded,
      color: Color(0xFFCF6F9E),
    ),
    Category(
      id: 'gifts',
      kind: CategoryKind.expense,
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFE0654F),
    ),
    Category(
      id: 'fees',
      kind: CategoryKind.expense,
      icon: Icons.account_balance_rounded,
      color: Color(0xFF8C8C8C),
    ),
    Category(
      id: otherExpenseId,
      kind: CategoryKind.expense,
      icon: Icons.category_rounded,
      color: Color(0xFF7D8B99),
    ),
  ];

  static const income = <Category>[
    Category(
      id: 'salary',
      kind: CategoryKind.income,
      icon: Icons.work_rounded,
      color: Color(0xFF1B8A5A),
    ),
    Category(
      id: 'business',
      kind: CategoryKind.income,
      icon: Icons.storefront_rounded,
      color: Color(0xFF2E9E6E),
    ),
    Category(
      id: 'interest',
      kind: CategoryKind.income,
      icon: Icons.savings_rounded,
      color: Color(0xFF3FA796),
    ),
    Category(
      id: 'investment',
      kind: CategoryKind.income,
      icon: Icons.trending_up_rounded,
      color: Color(0xFF4C7BD9),
    ),
    Category(
      id: 'gift_income',
      kind: CategoryKind.income,
      icon: Icons.redeem_rounded,
      color: Color(0xFFB65FCF),
    ),
    Category(
      id: otherIncomeId,
      kind: CategoryKind.income,
      icon: Icons.add_card_rounded,
      color: Color(0xFF7D8B99),
    ),
  ];

  /// Categories assigned automatically to non-spending movements.
  static const system = <Category>[
    Category(
      id: transferId,
      kind: CategoryKind.expense,
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF6C7A89),
    ),
    Category(
      id: debtId,
      kind: CategoryKind.expense,
      icon: Icons.handshake_rounded,
      color: Color(0xFF8E6C4A),
    ),
    Category(
      id: loanId,
      kind: CategoryKind.expense,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF9A5B3F),
    ),
    Category(
      id: cardPaymentId,
      kind: CategoryKind.expense,
      icon: Icons.credit_score_rounded,
      color: Color(0xFF6C7A89),
    ),
  ];

  static final Map<String, Category> _builtIn = {
    for (final c in [...expense, ...income, ...system]) c.id: c,
  };

  /// User-created categories, mirrored from Firestore by
  /// `customCategoriesProvider`. Domain code (validation, migration) needs
  /// to resolve ids without a widget `ref`, hence this registry; widgets
  /// that display categories also watch the provider so they rebuild.
  static Map<String, Category> _custom = const {};

  static void setCustom(Iterable<Category> categories) =>
      _custom = {for (final c in categories) c.id: c};

  /// Makes a just-saved category resolvable immediately, before its
  /// Firestore snapshot arrives.
  static void upsertCustom(Category category) =>
      _custom = {..._custom, category.id: category};

  static Category byId(String? id) =>
      _custom[id] ?? _builtIn[id] ?? _builtIn[otherExpenseId]!;

  static bool exists(String? id) =>
      _custom.containsKey(id) || _builtIn.containsKey(id);

  /// Label of a user-created category, or null for built-ins.
  static String? customName(String? id) => _custom[id]?.customName;

  /// Categories offered when picking one for [kind]. Built-ins first, then
  /// the user's own; archived ones only with [includeArchived] (filters and
  /// reports still need to match old transactions).
  static List<Category> selectable(
    CategoryKind kind, {
    bool includeArchived = false,
  }) => [
    ...(kind == CategoryKind.income ? income : expense),
    ..._custom.values.where(
      (c) => c.kind == kind && (includeArchived || !c.archived),
    ),
  ];

  static List<Category> forKind(CategoryKind kind) => selectable(kind);

  /// Maps category names written by app versions before schema 2.
  static String fromLegacyName(String? name) =>
      switch (name?.toLowerCase().trim()) {
        'food' => 'food',
        'travel' => 'transport',
        'shopping' => 'shopping',
        'income' => otherIncomeId,
        'transfers' => transferId,
        _ => otherExpenseId,
      };
}
