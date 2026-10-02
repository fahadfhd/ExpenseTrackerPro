import 'package:cloud_firestore/cloud_firestore.dart';

/// Lenient readers for Firestore maps. Documents may come from older app
/// versions, so every read tolerates missing or differently-typed fields.
abstract final class Codec {
  static DateTime? date(Object? value) => switch (value) {
    Timestamp t => t.toDate(),
    DateTime d => d,
    String s => DateTime.tryParse(s),
    int ms => DateTime.fromMillisecondsSinceEpoch(ms),
    _ => null,
  };

  static Timestamp? timestamp(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);

  static int integer(Object? value, [int fallback = 0]) =>
      value is num ? value.toInt() : fallback;

  static int? intOrNull(Object? value) => value is num ? value.toInt() : null;

  static double decimal(Object? value, [double fallback = 0]) =>
      value is num ? value.toDouble() : fallback;

  static String string(Object? value, [String fallback = '']) =>
      value is String ? value : fallback;

  static String? stringOrNull(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static bool boolean(Object? value, [bool fallback = false]) =>
      value is bool ? value : fallback;

  static List<String> strings(Object? value) =>
      (value as List<dynamic>? ?? const []).whereType<String>().toList();

  static List<int> ints(Object? value) => (value as List<dynamic>? ?? const [])
      .whereType<num>()
      .map((e) => e.toInt())
      .toList();

  static T enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
