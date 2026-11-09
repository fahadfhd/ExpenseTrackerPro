import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/transactions/domain/transaction.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

Future<void> seedExpense(
  TestEnv env, {
  String id = 't1',
  int amount = 45000,
  String description = 'Lunch',
  String? accountId,
  String? loanId,
}) async {
  final now = DateTime.now();
  await f.seedTransaction(
    env,
    Transaction(
      id: id,
      date: DateTime(now.year, now.month, now.day, 9),
      amountMinor: amount,
      type: loanId != null
          ? TransactionType.loanPayment
          : TransactionType.expense,
      categoryId: loanId != null ? 'loan_emi' : 'food',
      description: description,
      accountId: accountId,
      loanId: loanId,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  group('keyboard', () {
    testWidgets('tapping outside a text field hides the keyboard', (
      tester,
    ) async {
      await pumpApp(tester);
      await f.openTab(tester, 'Accounts');
      await tapText(tester, 'Add account');
      await tester.tap(find.widgetWithText(TextFormField, 'Account name'));
      await settle(tester);
      expect(tester.testTextInput.isVisible, isTrue);

      // A tap on plain, non-interactive text elsewhere on the screen.
      await tester.tap(find.text('Account type'), warnIfMissed: false);
      await settle(tester);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('tapping a button still works while the keyboard is open', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await f.openTab(tester, 'Accounts');
      await tapText(tester, 'Add account');
      await enterField(tester, 'Account name', 'Wallet');
      await tapText(tester, 'Save');
      expect((await env.docs('accounts')).single['name'], 'Wallet');
    });
  });

  group('delete with undo', () {
    testWidgets('deleting from the detail sheet can be undone', (tester) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env, opening: 100000);
      await seedExpense(env, accountId: 'acc1');
      // Balance effect of the seeded expense.
      await env.db
          .collection('users')
          .doc(env.uid)
          .collection('accounts')
          .doc('acc1')
          .update({'ledgerDeltaMinor': -45000});
      await settle(tester);
      await f.openTab(tester, 'Transactions');
      await tapText(tester, 'Lunch');
      await tapText(tester, 'Delete');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);
      expect(await env.docs('transactions'), isEmpty);
      expect((await env.docs('accounts')).single['ledgerDeltaMinor'], 0);

      await tapText(tester, 'Undo');
      final restored = await env.docs('transactions');
      expect(restored.single['id'], 't1');
      expect(restored.single['amountMinor'], 45000);
      expect(
        (await env.docs('accounts')).single['ledgerDeltaMinor'],
        -45000,
        reason: 'undo re-applies the balance effect',
      );
    });

    testWidgets('swiping a transaction away deletes it, and Undo restores it', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await seedExpense(env);
      await settle(tester);
      await f.openTab(tester, 'Transactions');
      await tester.drag(find.text('Lunch'), const Offset(-600, 0));
      await settle(tester);
      expect(find.text('Lunch'), findsNothing);
      expect(await env.docs('transactions'), isEmpty);
      expect(tester.takeException(), isNull);

      await tapText(tester, 'Undo');
      expect(find.text('Lunch'), findsWidgets);
      expect((await env.docs('transactions')).single['id'], 't1');
    });

    testWidgets('records owned by the loans module cannot be swiped away', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await seedExpense(env, description: 'Car EMI', loanId: 'loan1');
      await settle(tester);
      await f.openTab(tester, 'Transactions');
      expect(find.byType(Dismissible), findsNothing);
      await tester.drag(find.text('Car EMI'), const Offset(-600, 0));
      await settle(tester);
      expect(await env.docs('transactions'), hasLength(1));
    });
  });

  group('discard guard', () {
    testWidgets('asks before discarding a half-filled transaction', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byTooltip('Add transaction'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '250',
      );
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Discard changes?'), findsOneWidget);

      // Keep editing: the form stays with its input.
      await tester.tap(find.text('Keep editing'));
      await settle(tester);
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
      await settle(tester);
      expect(find.widgetWithText(TextFormField, 'Amount'), findsNothing);
      expect(await env.docs('transactions'), isEmpty);
    });

    testWidgets('an empty form closes without asking', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Add transaction'));
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Amount'), findsNothing);
    });

    testWidgets('a successful save never asks', (tester) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byTooltip('Add transaction'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '90',
      );
      await choosePayment(tester, 'Cash / not tracked').catchError((_) {});
      await chooseCategory(tester, 'Food');
      await tapText(tester, 'Save');
      expect(find.text('Discard changes?'), findsNothing);
      expect(await env.docs('transactions'), hasLength(1));
    });

    testWidgets('a new account form asks before discarding', (tester) async {
      await pumpApp(tester);
      await f.openTab(tester, 'Accounts');
      await tapText(tester, 'Add account');
      await enterField(tester, 'Account name', 'Savings');
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('quick entry', () {
    testWidgets('Yesterday chip records the transaction for yesterday', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await tester.tap(find.byTooltip('Add transaction'));
      await settle(tester);
      await reveal(tester, find.widgetWithText(ChoiceChip, 'Today'));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Today'))
            .selected,
        isTrue,
      );
      await enterField(tester, 'Amount', '120');
      await chooseCategory(tester, 'Food');
      await tapText(tester, 'Yesterday');
      await tapText(tester, 'Save');
      final stored = (await env.docs('transactions')).single;
      final date = (stored['date'] as dynamic).toDate() as DateTime;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        DateTime(date.year, date.month, date.day),
        DateTime(yesterday.year, yesterday.month, yesterday.day),
      );
    });

    testWidgets('amount fields preview the formatted amount while typing', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Add transaction'));
      await settle(tester);
      expect(find.text('₹1,23,456'), findsNothing);
      await enterField(tester, 'Amount', '123456');
      expect(find.text('₹1,23,456'), findsOneWidget);
      await enterField(tester, 'Amount', '1234.5');
      expect(find.text('₹1,234.50'), findsOneWidget);
      await enterField(tester, 'Amount', '');
      expect(find.textContaining('₹1,2'), findsNothing);
    });
  });
}
