import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/features/categories/domain/category.dart';

/// Icons users can give their categories. Stored by key (never by code
/// point), so a stored value can't point at an unrelated glyph after an
/// icon-font update.
const categoryIcons = <String, IconData>{
  'shopping_cart': Icons.shopping_cart_rounded,
  'coffee': Icons.local_cafe_rounded,
  'pizza': Icons.local_pizza_rounded,
  'bar': Icons.local_bar_rounded,
  'gas': Icons.local_gas_station_rounded,
  'bus': Icons.directions_bus_rounded,
  'flight': Icons.flight_rounded,
  'bike': Icons.pedal_bike_rounded,
  'home': Icons.home_rounded,
  'bed': Icons.bed_rounded,
  'bolt': Icons.bolt_rounded,
  'wifi': Icons.wifi_rounded,
  'phone': Icons.smartphone_rounded,
  'tv': Icons.tv_rounded,
  'game': Icons.sports_esports_rounded,
  'music': Icons.music_note_rounded,
  'movie': Icons.movie_rounded,
  'book': Icons.menu_book_rounded,
  'school': Icons.school_rounded,
  'fitness': Icons.fitness_center_rounded,
  'health': Icons.favorite_rounded,
  'medical': Icons.medical_services_rounded,
  'pets': Icons.pets_rounded,
  'child': Icons.child_care_rounded,
  'gift': Icons.card_giftcard_rounded,
  'celebration': Icons.celebration_rounded,
  'shirt': Icons.checkroom_rounded,
  'beauty': Icons.spa_rounded,
  'tools': Icons.build_rounded,
  'car': Icons.directions_car_rounded,
  'work': Icons.work_rounded,
  'savings': Icons.savings_rounded,
  'trending': Icons.trending_up_rounded,
  'bank': Icons.account_balance_rounded,
  'receipt': Icons.receipt_long_rounded,
  'star': Icons.star_rounded,
};

const defaultCategoryIconKey = 'star';

/// Colors users can give their categories (opaque ARGB values).
const categoryColors = <int>[
  0xFFE07A3F,
  0xFFD9534F,
  0xFFCF6F9E,
  0xFFB65FCF,
  0xFF7A6FF0,
  0xFF4C7BD9,
  0xFF2F9BD6,
  0xFF3FA796,
  0xFF1B8A5A,
  0xFF5B8C5A,
  0xFFD9A93F,
  0xFF8C7B6B,
];

/// A subcategory the user created under one of their own categories.
/// Stored inside the parent's document, in its `subcategories` list.
class CustomSubcategory {
  const CustomSubcategory({required this.id, required this.name});

  final String id;
  final String name;

  CustomSubcategory copyWith({String? name}) =>
      CustomSubcategory(id: id, name: name ?? this.name);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  /// Null for malformed entries, which are skipped rather than failing the
  /// whole category.
  static CustomSubcategory? fromMap(Object? map) {
    if (map is! Map) return null;
    final id = Codec.stringOrNull(map['id'])?.trim();
    final name = Codec.stringOrNull(map['name'])?.trim();
    if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
    return CustomSubcategory(id: id, name: name);
  }
}

/// A category created by the user. Stored in `categories/{id}`.
class CustomCategory {
  const CustomCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.subcategories = const [],
  });

  /// Ids are prefixed so they can never collide with built-in ids.
  static const idPrefix = 'custom_';
  static const maxNameLength = 30;

  /// Subcategory ids embed the parent's id, so they stay unique across
  /// categories and never collide with built-in subcategory ids.
  static String subcategoryIdFor(String categoryId, String uniquePart) =>
      '$categoryId.sub_$uniquePart';

  final String id;
  final String name;
  final CategoryKind kind;
  final String iconKey;
  final int colorValue;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CustomSubcategory> subcategories;

  IconData get icon =>
      categoryIcons[iconKey] ?? categoryIcons[defaultCategoryIconKey]!;

  Color get color => Color(colorValue);

  /// The category as seen by the rest of the app.
  Category toCategory() => Category(
    id: id,
    kind: kind,
    icon: icon,
    color: color,
    customName: name,
    archived: archived,
    subcategories: [
      for (final s in subcategories) Subcategory(s.id, customName: s.name),
    ],
  );

  CustomCategory copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    bool? archived,
    DateTime? updatedAt,
    List<CustomSubcategory>? subcategories,
  }) => CustomCategory(
    id: id,
    name: name ?? this.name,
    kind: kind,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    subcategories: subcategories ?? this.subcategories,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'kind': kind.name,
    'iconKey': iconKey,
    'colorValue': colorValue,
    'archived': archived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'subcategories': [for (final s in subcategories) s.toMap()],
  };

  factory CustomCategory.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return CustomCategory(
      id: id,
      name: Codec.string(map['name'], 'Category').trim(),
      kind: Codec.enumByName(
        CategoryKind.values,
        map['kind'],
        CategoryKind.expense,
      ),
      iconKey: Codec.string(map['iconKey'], defaultCategoryIconKey),
      colorValue: Codec.integer(map['colorValue'], categoryColors.first),
      archived: Codec.boolean(map['archived']),
      createdAt: Codec.date(map['createdAt']) ?? now,
      updatedAt: Codec.date(map['updatedAt']) ?? now,
      subcategories: [
        if (map['subcategories'] case final List<dynamic> list)
          for (final raw in list) ?CustomSubcategory.fromMap(raw),
      ],
    );
  }
}

/// Why a category name was rejected.
enum CategoryNameIssue { empty, tooLong, duplicate }

abstract final class CategoryNames {
  /// Checks [name] for a new or edited category. [builtInLabels] are the
  /// localized built-in names of the same kind and [existing] the user's
  /// other categories of that kind (excluding the one being edited).
  /// Comparison ignores case and surrounding spaces.
  static CategoryNameIssue? validate(
    String name, {
    required Iterable<String> builtInLabels,
    required Iterable<String> existing,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return CategoryNameIssue.empty;
    if (trimmed.length > CustomCategory.maxNameLength) {
      return CategoryNameIssue.tooLong;
    }
    final key = trimmed.toLowerCase();
    final taken = {
      ...builtInLabels,
      ...existing,
    }.map((n) => n.trim().toLowerCase());
    return taken.contains(key) ? CategoryNameIssue.duplicate : null;
  }
}
