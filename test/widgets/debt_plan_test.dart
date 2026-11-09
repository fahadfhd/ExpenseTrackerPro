import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/debt_plan/application/debt_plan_sync.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

Future<void> seedDebts(TestEnv env) async {
  final now = DateTime.now();
  final user = env.db.collection('users').doc(env.uid);
  await user
      .collection('loans')
      .doc('car')
      .set(
        Loan(
          id: 'car',
          name: 'Car loan',
          principalMinor: 60000000,
          annualRatePercent: 10.5,
          installments: 60,
          frequency: EmiFrequency.monthly,
          emiMinor: 1289600,
          firstDueDate: DateTime(now.year, now.month + 1, 5),
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );
  await user
      .collection('credit_cards')
      .doc('visa')
      .set(
        CreditCard(
          id: 'visa',
          name: 'Travel card',
          creditLimitMinor: 30000000,
          statementDay: 10,
          dueDay: 28,
          openingOutstandingMinor: 15000000,
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );
  await user
      .collection('borrow_lend')
      .doc('ravi')
      .set(
        DebtRecord(
          id: 'ravi',
          direction: DebtDirection.borrowed,
          personName: 'Ravi',
          amountMinor: 2000000,
          date: now,
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );
}

Future<void> openPlan(WidgetTester tester) async {
  await f.openTab(tester, 'More');
  await tapText(tester, 'Debt-free plan');
}

void main() {
  testWidgets('nothing owed shows the empty state', (tester) async {
    await pumpApp(tester);
    await openPlan(tester);
    expect(find.textContaining("You're debt-free"), findsOneWidget);
  });

  testWidgets('the plan combines loans, cards and borrowed money', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedDebts(env);
    await settle(tester);
    await openPlan(tester);

    expect(find.text('Debt-free by'), findsOneWidget);
    await reveal(tester, find.text('Your roadmap'));
    expect(find.text('Car loan'), findsWidgets);
    expect(find.text('Travel card'), findsWidgets);
    expect(find.text('Ravi'), findsWidgets);
  });

  testWidgets('extra payment and strategy are remembered', (tester) async {
    final env = await pumpApp(tester);
    await seedDebts(env);
    await settle(tester);
    await openPlan(tester);

    await enterField(tester, 'Extra per month', '5000');
    await settle(tester);
    await tapText(tester, 'Smallest balance first');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('debtPlan.extraMinor'), 500000);
    expect(prefs.getString('debtPlan.strategy'), 'snowball');
  });

  testWidgets('entering the real card rate replaces the estimate', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedDebts(env);
    await settle(tester);
    await openPlan(tester);

    expect(find.textContaining('estimated 36%'), findsOneWidget);
    await tapText(tester, 'Set interest rate');
    await enterField(tester, 'Interest rate (% a year)', '42');
    await tapText(tester, 'Save');
    await settle(tester);

    final card = (await env.docs('credit_cards')).single;
    expect(card['annualRatePercent'], 42);
    expect(find.textContaining('estimated 36%'), findsNothing);
  });

  testWidgets('the whole screen fits a narrow phone in Malayalam', (
    tester,
  ) async {
    final env = await pumpApp(tester, localeCode: 'ml');
    await f.openTab(tester, 'കൂടുതൽ');
    await tapText(tester, 'കടരഹിത പ്ലാൻ');
    // Narrowed only now: tall enough to lay out every section at 320 dp.
    tester.view.physicalSize = const Size(960, 9000);
    // Seeded last so only this screen lays out with the data.
    await seedDebts(env);
    await settle(tester);
    expect(find.text('നിങ്ങളുടെ റോഡ്മാപ്പ്'), findsOneWidget);
  });

  testWidgets('extra money and switch screens fit a narrow phone', (
    tester,
  ) async {
    final env = await pumpApp(tester, localeCode: 'ml');
    await f.openTab(tester, 'കൂടുതൽ');
    await tapText(tester, 'അധിക പണം കിട്ടിയോ?');
    tester.view.physicalSize = const Size(960, 6000);
    await seedDebts(env);
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, '100000');
    await settle(tester);
    expect(find.text('ഇങ്ങനെ ചെയ്യുക'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tapText(tester, 'കുറഞ്ഞ പലിശയിലേക്ക് മാറണോ?');
    await settle(tester);
    expect(find.byType(TextFormField), findsNWidgets(5));
  });

  testWidgets('overdue items on the dashboard fit in Malayalam', (
    tester,
  ) async {
    final env = await pumpApp(tester, localeCode: 'ml');
    await seedDebts(env);
    await settle(tester);
    expect(find.byType(ListTile), findsWidgets);
  });

  group('extra income', () {
    Future<void> seedIncome(TestEnv env, {required int thisMonth}) async {
      final now = DateTime.now();
      Future<void> add(String id, DateTime date, int amount) =>
          f.seedTransaction(
            env,
            Transaction(
              id: id,
              date: date,
              amountMinor: amount,
              type: TransactionType.income,
              categoryId: 'salary',
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var back = 1; back <= 3; back++) {
        await add('m$back', DateTime(now.year, now.month - back, 2), 5000000);
      }
      await add('now', DateTime(now.year, now.month, 1), thisMonth);
    }

    testWidgets('entering extra money says which debt to pay', (tester) async {
      final env = await pumpApp(tester);
      await seedDebts(env);
      await settle(tester);
      await f.openTab(tester, 'More');
      await tapText(tester, 'Got extra money?');

      await enterField(tester, 'Extra money received', '200000');
      await settle(tester);

      expect(find.text('Do this'), findsOneWidget);
      // Dearest first: the card closes, the rest goes to the loan.
      expect(find.text('Closes this debt'), findsOneWidget);
      expect(find.text('Part payment'), findsOneWidget);
      await reveal(tester, find.text('Interest saved'));
      expect(find.text('Interest saved'), findsOneWidget);
    });

    testWidgets('a bonus month is offered on the dashboard', (tester) async {
      final env = await pumpApp(tester);
      await seedDebts(env);
      await seedIncome(env, thisMonth: 9000000);
      await settle(tester);

      final nudge = find.textContaining('more income than usual');
      expect(nudge, findsOneWidget);
      await tester.tap(nudge);
      await settle(tester);

      // Prefilled with the 40,000 above the usual 50,000.
      expect(find.text('Do this'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '40000'), findsOneWidget);
    });

    testWidgets('a normal month shows no nudge', (tester) async {
      final env = await pumpApp(tester);
      await seedDebts(env);
      await seedIncome(env, thisMonth: 5000000);
      await settle(tester);
      expect(find.textContaining('more income than usual'), findsNothing);
      expect(find.textContaining('Debt-free by'), findsOneWidget);
    });
  });

  testWidgets('the debt history is recorded in the background', (tester) async {
    final env = await pumpApp(tester);
    await seedDebts(env);
    await settle(tester);

    final doc = (await env.docs(
      'settings',
    )).singleWhere((d) => d['id'] == 'debt_progress');
    final months = doc['months'] as Map;
    expect((months.values.single as Map)['totalMinor'], 77000000);
  });

  testWidgets('the monthly reminder is opt-in and can be removed', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedDebts(env);
    await settle(tester);
    await openPlan(tester);
    bool hasPlanReminder(List<Map<String, dynamic>> docs) =>
        docs.any((d) => d['id'] == debtPlanReminderId);
    expect(hasPlanReminder(await env.docs('reminders')), isFalse);

    await tapText(tester, 'Remind me each month');
    await settle(tester);
    final reminders = await env.docs('reminders');
    expect(hasPlanReminder(reminders), isTrue);
    expect(
      reminders.firstWhere((d) => d['id'] == debtPlanReminderId)['title'],
      startsWith('Debt plan: pay'),
    );

    await tapText(tester, 'Remind me each month');
    await settle(tester);
    expect(hasPlanReminder(await env.docs('reminders')), isFalse);
  });

  testWidgets('the switch calculator gives a verdict after fees', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedDebts(env);
    await settle(tester);
    await f.openTab(tester, 'More');
    await tapText(tester, 'Move to a cheaper loan?');
    await settle(tester);

    // Prefilled from the card.
    expect(find.widgetWithText(TextFormField, '150000'), findsOneWidget);
    await enterField(tester, 'New interest rate (% a year)', '16');
    await settle(tester);
    await reveal(tester, find.textContaining('Worth it'));
    expect(find.textContaining('Worth it'), findsOneWidget);
  });
}
