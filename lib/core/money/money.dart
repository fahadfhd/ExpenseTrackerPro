/// Money is stored everywhere as an [int] count of minor units (paise, cents)
/// so that sums never accumulate floating-point error.
///
/// All supported currencies use two fractional digits.
abstract final class Money {
  static const int minorPerMajor = 100;

  /// Parses user input such as `1,234.5` or `₹ 99` into minor units.
  ///
  /// Returns null for empty, malformed, negative, or over-precise input
  /// (more than two fractional digits).
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty || cleaned.startsWith('-')) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final major = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return major * minorPerMajor + int.parse(fraction);
  }

  static int fromMajor(num major) => (major * minorPerMajor).round();

  static double toMajor(int minor) => minor / minorPerMajor;

  /// Plain editable representation (no grouping, no symbol), e.g. `1234.50`.
  static String toEditable(int minor) {
    final major = minor ~/ minorPerMajor;
    final fraction = (minor.abs() % minorPerMajor).toString().padLeft(2, '0');
    return fraction == '00' ? '$major' : '$major.$fraction';
  }

  /// Percentage of [part] within [whole], 0 when [whole] is not positive.
  static double ratio(int part, int whole) => whole <= 0 ? 0 : part / whole;
}
