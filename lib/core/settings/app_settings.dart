import 'package:expensetrackerpro/core/money/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the instance loaded before `runApp`, so
/// settings are available synchronously on the first frame.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.currencyCode = 'INR',
    this.localeCode,
    this.autoBackup = true,
    this.budgetAlerts = true,
  });

  final ThemeMode themeMode;
  final String currencyCode;

  /// Null follows the device language.
  final String? localeCode;
  final bool autoBackup;
  final bool budgetAlerts;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currencyCode,
    String? Function()? localeCode,
    bool? autoBackup,
    bool? budgetAlerts,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    currencyCode: currencyCode ?? this.currencyCode,
    localeCode: localeCode != null ? localeCode() : this.localeCode,
    autoBackup: autoBackup ?? this.autoBackup,
    budgetAlerts: budgetAlerts ?? this.budgetAlerts,
  );

  Map<String, dynamic> toMap() => {
    'themeMode': themeMode.name,
    'currencyCode': currencyCode,
    'localeCode': localeCode,
    'autoBackup': autoBackup,
    'budgetAlerts': budgetAlerts,
  };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final currency = map['currencyCode'];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      currencyCode: supportedCurrencies.containsKey(currency)
          ? currency as String
          : 'INR',
      localeCode: map['localeCode'] as String?,
      autoBackup: map['autoBackup'] as bool? ?? true,
      budgetAlerts: map['budgetAlerts'] as bool? ?? true,
    );
  }
}

/// Device-local preferences. Cloud copies are part of backups; the local
/// copy is authoritative so the app themes correctly before sign-in.
class SettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'settings.themeMode';
  static const _currencyKey = 'settings.currency';
  static const _localeKey = 'settings.locale';
  static const _autoBackupKey = 'settings.autoBackup';
  static const _budgetAlertsKey = 'settings.budgetAlerts';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings.fromMap({
      'themeMode': prefs.getString(_themeKey),
      'currencyCode': prefs.getString(_currencyKey),
      'localeCode': prefs.getString(_localeKey),
      'autoBackup': prefs.getBool(_autoBackupKey),
      'budgetAlerts': prefs.getBool(_budgetAlertsKey),
    });
  }

  void apply(AppSettings settings) {
    state = settings;
    _prefs
      ..setString(_themeKey, settings.themeMode.name)
      ..setString(_currencyKey, settings.currencyCode)
      ..setBool(_autoBackupKey, settings.autoBackup)
      ..setBool(_budgetAlertsKey, settings.budgetAlerts);
    if (settings.localeCode == null) {
      _prefs.remove(_localeKey);
    } else {
      _prefs.setString(_localeKey, settings.localeCode!);
    }
  }

  void setThemeMode(ThemeMode mode) => apply(state.copyWith(themeMode: mode));

  void setCurrency(String code) => apply(state.copyWith(currencyCode: code));

  void setLocale(String? code) => apply(state.copyWith(localeCode: () => code));

  void setAutoBackup(bool value) => apply(state.copyWith(autoBackup: value));

  void setBudgetAlerts(bool value) => apply(state.copyWith(budgetAlerts: value));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

final currencyFormatterProvider = Provider<CurrencyFormatter>(
  (ref) => CurrencyFormatter(
    currencyCode: ref.watch(settingsProvider.select((s) => s.currencyCode)),
  ),
);
