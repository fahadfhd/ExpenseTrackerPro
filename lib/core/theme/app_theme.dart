import 'package:flutter/material.dart';

/// Semantic colors for money and charts. Financial state is never shown by
/// color alone: widgets pair these with signs, icons or labels.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.series1,
    required this.series2,
    required this.track,
  });

  static const light = FinanceColors(
    positive: Color(0xFF137A4C),
    negative: Color(0xFFC0392B),
    warning: Color(0xFFA86400),
    // Validated categorical slots 1–2 (blue, orange) for the light surface.
    series1: Color(0xFF2A78D6),
    series2: Color(0xFFEB6834),
    track: Color(0xFFE3E8E4),
  );

  static const dark = FinanceColors(
    positive: Color(0xFF4CC38A),
    negative: Color(0xFFFF7A6B),
    warning: Color(0xFFF0B04A),
    series1: Color(0xFF3987E5),
    series2: Color(0xFFD95926),
    track: Color(0xFF223038),
  );

  final Color positive;
  final Color negative;
  final Color warning;

  /// Primary chart series (spending, single-series bars).
  final Color series1;

  /// Second chart series (income in income-vs-spending charts).
  final Color series2;

  /// Background of progress bars and meters.
  final Color track;

  @override
  FinanceColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? series1,
    Color? series2,
    Color? track,
  }) => FinanceColors(
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning ?? this.warning,
    series1: series1 ?? this.series1,
    series2: series2 ?? this.series2,
    track: track ?? this.track,
  );

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      series1: Color.lerp(series1, other.series1, t)!,
      series2: Color.lerp(series2, other.series2, t)!,
      track: Color.lerp(track, other.track, t)!,
    );
  }
}

extension FinanceTheme on BuildContext {
  FinanceColors get finance =>
      Theme.of(this).extension<FinanceColors>() ?? FinanceColors.light;
}

class AppTheme {
  static const seed = Color(0xFF0E7C66);

  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: isDark ? const Color(0xFF0F1720) : const Color(0xFFF4F7F2),
    );
    final cardColor = isDark ? const Color(0xFF111C24) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF091116)
          : const Color(0xFFEEF4EE),
      extensions: [isDark ? FinanceColors.dark : FinanceColors.light],
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 10,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF15222B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF0F1A21) : const Color(0xFFF7FAF6),
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF0E171E)
            : Colors.white.withValues(alpha: 0.96),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
