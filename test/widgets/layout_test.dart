import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

/// Visits every main screen and form, collecting layout overflow errors
/// with the source location of the overflowing widget. Screens are found by
/// their localized labels, so the same walk runs in every language.
Future<Set<String>> _collectOverflows(
  WidgetTester tester, {
  Size physicalSize = const Size(1170, 2532),
  double devicePixelRatio = 3,
  String localeCode = 'en',
}) async {
  final l10n = lookupAppLocalizations(Locale(localeCode));
  final errors = <String>{};
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    final location =
        RegExp(r'lib/[^\s:]+\.dart:\d+').firstMatch(text)?.group(0) ?? '?';
    errors.add('${details.exceptionAsString().split('\n').first} @ $location');
  };
  try {
    final env = await pumpApp(
      tester,
      physicalSize: physicalSize,
      devicePixelRatio: devicePixelRatio,
      localeCode: localeCode,
    );
    await f.seedAccount(env, name: 'Primary savings account with a long name');
    final day = DateTime(DateTime.now().year, DateTime.now().month, 1, 9);
    await f.seedTransaction(
      env,
      Transaction(
        id: 't',
        date: day,
        amountMinor: 123456789,
        type: TransactionType.expense,
        categoryId: 'entertainment',
        description: 'A fairly long transaction description for testing',
        accountId: 'acc1',
        createdAt: day,
        updatedAt: day,
      ),
    );
    await settle(tester);

    Future<void> tab(String label) async {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            )
            .first,
        warnIfMissed: false,
      );
      await settle(tester);
    }

    Future<void> openAndBack(String label) async {
      await tapText(tester, label);
      // Not `pageBack()`: it finds the button by its English tooltip.
      await tester.tap(find.byType(BackButton));
      await settle(tester);
    }

    for (final t in [
      l10n.navTransactions,
      l10n.navAccounts,
      l10n.navLoans,
      l10n.navHome,
    ]) {
      await tab(t);
    }
    await tester.tap(find.byTooltip(l10n.addTransaction));
    await settle(tester);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);

    await tab(l10n.navMore);
    for (final screen in [
      l10n.borrowLendTitle,
      l10n.budgetsTitle,
      l10n.recurringTitle,
      l10n.reportsTitle,
      l10n.vehiclesTitle,
      l10n.remindersTitle,
      l10n.emiCalculator,
      l10n.mileageCalculator,
      l10n.settingsTitle,
    ]) {
      await openAndBack(screen);
    }

    await tab(l10n.navAccounts);
    await openAndBack(l10n.addAccount);
    await tab(l10n.navLoans);
    await openAndBack(l10n.addLoan);
  } finally {
    FlutterError.onError = original;
    debugPrint('LAYOUT ERRORS: $errors');
  }
  return errors;
}

void main() {
  testWidgets('no overflow at 2x text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    expect(await _collectOverflows(tester), isEmpty);
  });

  testWidgets('no overflow on a 320 dp wide phone', (tester) async {
    final errors = await _collectOverflows(
      tester,
      physicalSize: const Size(640, 1136),
      devicePixelRatio: 2,
    );
    expect(errors, isEmpty);
  });

  // Malayalam text is usually longer than English and its glyphs are taller,
  // so it gets the same two stress cases.
  testWidgets('Malayalam: no overflow at 2x text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    expect(await _collectOverflows(tester, localeCode: 'ml'), isEmpty);
  });

  testWidgets('Malayalam: no overflow on a 320 dp wide phone', (tester) async {
    final errors = await _collectOverflows(
      tester,
      physicalSize: const Size(640, 1136),
      devicePixelRatio: 2,
      localeCode: 'ml',
    );
    expect(errors, isEmpty);
  });
}
