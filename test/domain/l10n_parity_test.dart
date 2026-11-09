import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps every translation in step with the English template: same messages,
/// same `{placeholders}`, nothing left blank or untranslated.
///
/// Adding a language: copy `lib/l10n/app_en.arb` to `app_<code>.arb`, set
/// `@@locale`, translate every value, add the code to [_languages] and to
/// `ios/Runner/Info.plist` (CFBundleLocalizations) and
/// `android/app/src/main/res/xml/locales_config.xml`.
const _languages = ['ml'];

/// Messages that are legitimately identical to English: brand names,
/// acronyms, units and symbols that are not translated.
const _sameAsEnglish = {
  'appTitle',
  'fuelCng',
  'fuelLpg',
  'unitKwh',
  'markPaidTitle',
  'prepayNewEmi',
  'noMileageYet',
};

final _placeholder = RegExp(r'\{(\w+)\}');
final _malayalamScript = RegExp('[ഀ-ൿ]');

Map<String, String> _messages(String code) {
  final raw =
      jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

Set<String> _placeholders(String message) =>
    _placeholder.allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final english = _messages('en');

  test('the English template has no blank messages', () {
    expect(
      english.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key),
      isEmpty,
    );
  });

  for (final code in _languages) {
    group('$code translation', () {
      final translated = _messages(code);

      test('declares its locale', () {
        final raw =
            jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
                as Map<String, dynamic>;
        expect(raw['@@locale'], code);
      });

      test('has exactly the same messages as English', () {
        expect(
          english.keys.toSet().difference(translated.keys.toSet()),
          isEmpty,
          reason: 'untranslated keys',
        );
        expect(
          translated.keys.toSet().difference(english.keys.toSet()),
          isEmpty,
          reason: 'keys that do not exist in English',
        );
      });

      test('uses the same placeholders in every message', () {
        final mismatched = [
          for (final e in english.entries)
            if (translated[e.key] != null &&
                !_setEquals(
                  _placeholders(e.value),
                  _placeholders(translated[e.key]!),
                ))
              '${e.key}: ${_placeholders(e.value)} vs '
                  '${_placeholders(translated[e.key]!)}',
        ];
        expect(mismatched, isEmpty);
      });

      test('has no blank or untranslated messages', () {
        final blank = translated.entries
            .where((e) => e.value.trim().isEmpty)
            .map((e) => e.key);
        expect(blank, isEmpty);

        if (code == 'ml') {
          // Every message is written in Malayalam script, apart from the
          // few that are brand names, acronyms or symbols.
          final latinOnly = translated.entries
              .where(
                (e) =>
                    !_malayalamScript.hasMatch(e.value) &&
                    !_sameAsEnglish.contains(e.key) &&
                    e.key != 'nextEmiOn',
              )
              .map((e) => e.key);
          expect(latinOnly, isEmpty, reason: 'still English?');
        }
        final copied = translated.entries
            .where(
              (e) =>
                  e.value == english[e.key] && !_sameAsEnglish.contains(e.key),
            )
            .map((e) => e.key);
        expect(copied, isEmpty, reason: 'identical to English');
      });
    });
  }
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
