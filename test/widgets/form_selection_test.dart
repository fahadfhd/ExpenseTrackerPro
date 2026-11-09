import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/transactions/presentation/transaction_form_sheet.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

Future<void> seedCard(TestEnv env, {String name = 'Millennia'}) async {
  final now = DateTime.now();
  await env.db
      .collection('users')
      .doc(env.uid)
      .collection('credit_cards')
      .doc('card1')
      .set(
        CreditCard(
          id: 'card1',
          name: name,
          last4: '4242',
          creditLimitMinor: 10000000,
          openingOutstandingMinor: 2500000,
          statementDay: 1,
          dueDay: 20,
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );
}

/// The chosen account or card chips (the kind chips carry no icon).
Finder pickedSources() => find.byWidgetPredicate(
  (w) => w is ChoiceChip && w.selected && w.avatar != null,
);

Future<void> openAddForm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Add transaction'));
  await settle(tester);
}

/// Whether the chip is selected (scrolls it into view first: the form is a
/// lazy list).
Future<bool> isSelected(WidgetTester tester, String chipLabel) async {
  final chip = find.widgetWithText(ChoiceChip, chipLabel);
  await reveal(tester, chip);
  return tester.widget<ChoiceChip>(chip.first).selected;
}

/// Asserts that [message] is shown, scrolling to it.
Future<void> expectShown(WidgetTester tester, String message) async {
  await reveal(tester, find.text(message));
  expect(find.text(message), findsOneWidget);
}

void main() {
  group('category selection', () {
    testWidgets('nothing is preselected, and a selected chip can be cleared', (
      tester,
    ) async {
      await pumpApp(tester);
      await openAddForm(tester);
      expect(await isSelected(tester, 'Food'), isFalse);

      await chooseCategory(tester, 'Food');
      expect(await isSelected(tester, 'Food'), isTrue);
      // Tapping the selected chip again clears it.
      await chooseCategory(tester, 'Food');
      expect(await isSelected(tester, 'Food'), isFalse);
    });

    testWidgets('saving without a category shows an error and saves nothing', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await openAddForm(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '100',
      );
      await tapText(tester, 'Save');
      await expectShown(tester, 'Choose a category');
      expect(await env.docs('transactions'), isEmpty);
    });

    testWidgets('Refund and Card bill chips toggle back to a plain expense', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await seedCard(env);
      await settle(tester);
      await openAddForm(tester);

      await showMoreTypes(tester);
      await tapText(tester, 'Refund');
      expect(await isSelected(tester, 'Refund'), isTrue);
      await tapText(tester, 'Refund');
      expect(await isSelected(tester, 'Refund'), isFalse);
      await reveal(tester, find.byType(SegmentedButton<EntryKind>));
      expect(
        tester
            .widget<SegmentedButton<EntryKind>>(
              find.byType(SegmentedButton<EntryKind>),
            )
            .selected,
        isNotEmpty,
        reason: 'back on Expense',
      );

      await tapText(tester, 'Card bill payment');
      expect(await isSelected(tester, 'Card bill payment'), isTrue);
      await tapText(tester, 'Card bill payment');
      expect(await isSelected(tester, 'Card bill payment'), isFalse);
    });
  });

  group('payment source', () {
    testWidgets(
      'first offers only the kinds of payment, then that kind\'s list',
      (tester) async {
        final env = await pumpApp(tester);
        await f.seedAccount(env, name: 'Salary', opening: 1500000);
        await f.seedAccount(env, id: 'acc2', name: 'Savings', opening: 20000);
        await seedCard(env);
        await settle(tester);
        await openAddForm(tester);

        final field = find.byType(PaymentSourceField);
        Finder inField(Finder matching) =>
            find.descendant(of: field, matching: matching);
        Finder chip(String label) =>
            inField(find.widgetWithText(ChoiceChip, label));

        // Step 1: just the three kinds, no account or card yet.
        expect(find.text('Paid with'), findsOneWidget);
        for (final label in ['Bank account', 'Credit card', 'Cash']) {
          expect(chip(label), findsOneWidget, reason: label);
        }
        for (final name in ['Salary', 'Savings', 'Millennia ••4242']) {
          expect(inField(find.text(name)), findsNothing, reason: name);
        }

        // Step 2: bank accounts only, no balances (they may not be accurate).
        await tester.tap(chip('Bank account'));
        await settle(tester);
        expect(inField(find.text('Salary')), findsOneWidget);
        expect(inField(find.text('Savings')), findsOneWidget);
        expect(inField(find.text('Millennia ••4242')), findsNothing);
        expect(find.textContaining('Balance'), findsNothing);

        // Switching kind swaps the list.
        await tester.tap(chip('Credit card'));
        await settle(tester);
        expect(inField(find.text('Salary')), findsNothing);
        expect(inField(find.text('Millennia ••4242')), findsOneWidget);
        expect(find.textContaining('Available'), findsNothing);

        // Cash is chosen by its chip and changes no balance.
        await tester.tap(chip('Cash'));
        await settle(tester);
        expect(find.text("Doesn't change any balance"), findsOneWidget);
      },
    );

    testWidgets('changing kind clears the choice; the open kind closes again', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env, name: 'Salary');
      await seedCard(env);
      await settle(tester);
      await openAddForm(tester);
      await choosePayment(tester, 'Salary');
      expect(pickedSources(), findsOneWidget);

      final field = find.byType(PaymentSourceField);
      Finder chip(String label) => find.descendant(
        of: field,
        matching: find.widgetWithText(ChoiceChip, label),
      );
      await reveal(tester, chip('Credit card'));
      await tester.tap(chip('Credit card'));
      await settle(tester);
      expect(
        pickedSources(),
        findsNothing,
        reason: 'the account is no longer chosen',
      );

      // Tapping the open kind collapses its list.
      await reveal(tester, chip('Credit card'));
      await tester.tap(chip('Credit card'));
      await settle(tester);
      expect(
        find.descendant(of: field, matching: find.text('Millennia ••4242')),
        findsNothing,
      );
    });

    testWidgets('saving without choosing how you paid is blocked', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env);
      await settle(tester);
      await openAddForm(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '100',
      );
      await chooseCategory(tester, 'Food');
      await tapText(tester, 'Save');
      await expectShown(tester, 'Choose how you paid');
      expect(await env.docs('transactions'), isEmpty);
    });

    testWidgets(
      'choosing a card records a card expense that raises its outstanding',
      (tester) async {
        final env = await pumpApp(tester);
        await f.seedAccount(env);
        await seedCard(env);
        await settle(tester);
        await openAddForm(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '1,200',
        );
        await choosePayment(tester, 'Millennia ••4242');
        await chooseCategory(tester, 'Shopping');
        await tapText(tester, 'Save');

        final tx = (await env.docs('transactions')).single;
        expect(tx['type'], TransactionType.creditCardExpense.name);
        expect(tx['creditCardId'], 'card1');
        expect(tx['accountId'], isNull);
        final card = (await env.docs('credit_cards')).single;
        expect(card['ledgerDeltaMinor'], 120000);
      },
    );

    testWidgets(
      'untracked cash is an explicit choice that changes no balance',
      (tester) async {
        final env = await pumpApp(tester);
        await f.seedAccount(env);
        await settle(tester);
        await openAddForm(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'),
          '50',
        );
        await choosePayment(tester, 'Cash / not tracked');
        await chooseCategory(tester, 'Food');
        await tapText(tester, 'Save');
        final tx = (await env.docs('transactions')).single;
        expect(tx['accountId'], isNull);
        expect((await env.docs('accounts')).single['ledgerDeltaMinor'], 0);
      },
    );

    testWidgets('a chosen source can be cleared by tapping it again', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env);
      await settle(tester);
      await openAddForm(tester);
      Finder selected() => pickedSources();
      expect(selected(), findsNothing);
      await choosePayment(tester, 'Salary');
      expect(selected(), findsOneWidget);
      await choosePayment(tester, 'Salary');
      expect(selected(), findsNothing);
    });

    testWidgets('a transfer cannot pick the same account as destination', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env, name: 'Salary');
      await f.seedAccount(env, id: 'acc2', name: 'Savings');
      await settle(tester);
      await openAddForm(tester);
      await tapText(tester, 'Transfer');
      await choosePayment(tester, 'Salary');
      final destination = find.byType(PaymentSourceField).at(1);
      expect(
        find.descendant(of: destination, matching: find.text('Salary')),
        findsNothing,
      );
      expect(
        find.descendant(of: destination, matching: find.text('Savings')),
        findsOneWidget,
      );
    });

    testWidgets('an account screen shortcut preselects that account', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env, name: 'Salary');
      await settle(tester);
      await f.openTab(tester, 'Accounts');
      await tapText(tester, 'Salary');
      await tapText(tester, 'Add transaction');
      expect(pickedSources(), findsOneWidget);
    });
  });

  group('custom categories', () {
    tearDown(() => Categories.setCustom(const []));

    testWidgets('create one from the form, select it and use it', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await openAddForm(tester);
      await tapText(tester, 'New');
      expect(find.text('New category'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Pets');
      await tapText(tester, 'Save');

      final categories = await env.docs('categories');
      expect(categories.single['name'], 'Pets');
      expect(categories.single['kind'], 'expense');
      final id = categories.single['id'] as String;
      expect(id, startsWith('custom_'));
      // Selected straight away.
      expect(await isSelected(tester, 'Pets'), isTrue);

      await enterField(tester, 'Amount', '300');
      await tapText(tester, 'Save');
      final tx = (await env.docs('transactions')).single;
      expect(tx['categoryId'], id);
      // Shows its own name in the list.
      expect(find.text('Pets'), findsWidgets);
    });

    testWidgets('names must be unique, also against built-in ones', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await openAddForm(tester);
      await tapText(tester, 'New');
      await tester.enterText(find.byType(TextField).last, ' food ');
      await tapText(tester, 'Save');
      expect(
        find.text('A category with this name already exists'),
        findsOneWidget,
      );
      expect(await env.docs('categories'), isEmpty);
    });

    testWidgets(
      'manage screen: add income category, archive hides it in forms',
      (tester) async {
        final env = await pumpApp(tester);
        await f.openTab(tester, 'More');
        await tapText(tester, 'Manage categories');
        await tapText(tester, 'Income');
        await tapText(tester, 'New category');
        await tester.enterText(find.byType(TextField).last, 'Freelance');
        await tapText(tester, 'Save');
        final stored = (await env.docs('categories')).single;
        expect(stored['kind'], 'income');
        expect(find.text('Freelance'), findsOneWidget);

        // Archive via the menu.
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await settle(tester);
        await tapText(tester, 'Archive');
        expect((await env.docs('categories')).single['archived'], isTrue);
      },
    );

    testWidgets('a category in use cannot be deleted', (tester) async {
      final env = await pumpApp(tester);
      final now = DateTime.now();
      final userDoc = env.db.collection('users').doc(env.uid);
      await userDoc.collection('categories').doc('custom_a').set({
        'name': 'Pets',
        'kind': 'expense',
        'iconKey': 'pets',
        'colorValue': 0xFFE07A3F,
        'archived': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      await f.seedTransaction(
        env,
        Transaction(
          id: 't',
          date: DateTime(now.year, now.month, 1, 9),
          amountMinor: 1000,
          type: TransactionType.expense,
          categoryId: 'custom_a',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await settle(tester);
      await f.openTab(tester, 'More');
      await tapText(tester, 'Manage categories');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await settle(tester);
      await tapText(tester, 'Delete');
      expect(find.textContaining("can't be deleted"), findsOneWidget);
      expect(await env.docs('categories'), hasLength(1));
    });
  });

  group('repay a borrow', () {
    Future<void> seedBorrow(TestEnv env) async {
      final now = DateTime.now();
      await env.db
          .collection('users')
          .doc(env.uid)
          .collection('borrow_lend')
          .doc('b1')
          .set(
            DebtRecord(
              id: 'b1',
              direction: DebtDirection.borrowed,
              personName: 'Rahul',
              amountMinor: 500000,
              date: now,
              createdAt: now,
              updatedAt: now,
            ).toMap(),
          );
    }

    testWidgets('is offered only while a borrow is open', (tester) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env);
      await settle(tester);
      await openAddForm(tester);
      await showMoreTypes(tester);
      expect(find.text('Repay a borrow'), findsNothing);
    });

    testWidgets('closes the borrow and records the repayment', (tester) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env, name: 'Salary');
      await seedBorrow(env);
      await settle(tester);
      await openAddForm(tester);

      await showMoreTypes(tester);
      await tapText(tester, 'Repay a borrow');
      // No category, merchant or description to fill in.
      expect(find.text('Category'), findsNothing);
      expect(find.text('Merchant or person'), findsNothing);

      // Choosing the person fills in the amount still owed.
      await tapText(tester, 'Rahul · ₹5,000 left');
      await choosePayment(tester, 'Salary');
      await tapText(tester, 'Save');
      await settle(tester);

      final debts = await env.docs('borrow_lend');
      final settlements = debts.single['settlements'] as List;
      expect(settlements, hasLength(1));
      expect((settlements.single as Map)['amountMinor'], 500000);
      final txs = await env.docs('transactions');
      expect(txs.single['type'], 'debtRepayment');
      expect(txs.single['accountId'], 'acc1');
    });

    testWidgets('asks which borrow before saving', (tester) async {
      final env = await pumpApp(tester);
      await f.seedAccount(env);
      await seedBorrow(env);
      await settle(tester);
      await openAddForm(tester);
      await showMoreTypes(tester);
      await tapText(tester, 'Repay a borrow');
      await enterField(tester, 'Amount', '100');
      await tapText(tester, 'Save');
      await settle(tester);
      expect(find.text('Which borrow?'), findsWidgets);
      expect(await env.docs('transactions'), isEmpty);
    });
  });
}
