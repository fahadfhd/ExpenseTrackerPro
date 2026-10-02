import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

/// Visits every main screen and form, collecting layout overflow errors
/// with the source location of the overflowing widget.
Future<Set<String>> _collectOverflows(
  WidgetTester tester, {
  Size physicalSize = const Size(1170, 2532),
  double devicePixelRatio = 3,
}) async {
  final errors = <String>{};
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    final location = RegExp(r'lib/[^\s:]+\.dart:\d+').firstMatch(text)?.group(0) ?? '?';
    errors.add('${details.exceptionAsString().split('\n').first} @ $location');
  };
  try {
    final env = await pumpApp(
      tester,
      physicalSize: physicalSize,
      devicePixelRatio: devicePixelRatio,
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
        find.descendant(of: find.byType(NavigationBar), matching: find.text(label)).first,
        warnIfMissed: false,
      );
      await settle(tester);
    }

    Future<void> openAndBack(String label) async {
      await tapText(tester, label);
      await tester.pageBack();
      await settle(tester);
    }

    for (final t in ['Transactions', 'Accounts', 'Loans', 'Home']) {
      await tab(t);
    }
    await tester.tap(find.byTooltip('Add transaction'));
    await settle(tester);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);

    await tab('More');
    for (final screen in [
      'Borrow & lend',
      'Budgets',
      'Recurring',
      'Reports',
      'Vehicles',
      'Reminders',
      'EMI calculator',
      'Mileage calculator',
      'Settings',
    ]) {
      await openAndBack(screen);
    }

    await tab('Accounts');
    await openAndBack('Add account');
    await tab('Loans');
    await openAndBack('Add loan');
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
}
