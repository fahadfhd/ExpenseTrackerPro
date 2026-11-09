import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/utils/dates.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

Future<void> openLoanForm(WidgetTester tester) async {
  await f.openTab(tester, 'Loans');
  await tapText(tester, 'Add loan');
}

Future<void> fillBasics(
  WidgetTester tester, {
  String emi = '8884.88',
  String installments = '12',
}) async {
  await enterField(tester, 'Loan name', 'Bike loan');
  await enterField(tester, 'Principal amount', '100000');
  await enterField(tester, 'EMI amount', emi);
  await enterField(tester, 'Number of installments', installments);
}

void main() {
  testWidgets('EMIs already paid are marked paid without touching balances', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await f.seedAccount(env, opening: 500000);
    await settle(tester);
    await openLoanForm(tester);
    await fillBasics(tester);
    await enterField(tester, 'EMIs already paid', '3');
    // With paid EMIs the date asked for is the next unpaid one (EMI #4).
    await reveal(tester, find.text('Next EMI date'));
    expect(find.text('Due date of EMI #4'), findsOneWidget);
    await tapText(tester, 'Save');

    final loan = (await env.docs('loans')).single;
    final events = await env.docs('loan_payments');
    expect(events, hasLength(3));
    expect(events.every((e) => e['kind'] == 'emiPaid'), isTrue);
    expect(events.map((e) => e['installmentNumber']).toSet(), {1, 2, 3});
    // History only: no transactions and no account movement.
    expect(await env.docs('transactions'), isEmpty);
    expect((await env.docs('accounts')).single['ledgerDeltaMinor'], 0);

    // The first EMI is three months before the date entered for EMI #4.
    final now = DateTime.now();
    final nextDue = DateTime(now.year, now.month + 1, 5);
    final first = (loan['firstDueDate'] as dynamic).toDate() as DateTime;
    expect(Dates.dayOf(first), DateTime(nextDue.year, nextDue.month - 3, 5));

    await tapText(tester, 'Bike loan');
    expect(find.text('3 of 12 EMIs paid'), findsWidgets);
  });

  testWidgets('numbers that cannot repay the principal are rejected', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await openLoanForm(tester);
    // 12 × ₹5,000 = ₹60,000 < ₹1,00,000.
    await fillBasics(tester, emi: '5000');
    await reveal(tester, find.textContaining("These numbers can't work"));
    await tapText(tester, 'Save');
    expect(await env.docs('loans'), isEmpty);
  });

  testWidgets('paid EMIs cannot exceed the number of EMIs', (tester) async {
    final env = await pumpApp(tester);
    await openLoanForm(tester);
    await fillBasics(tester);
    await enterField(tester, 'EMIs already paid', '13');
    await tapText(tester, 'Save');
    await reveal(tester, find.text('Enter a number from 0 to 12'));
    expect(find.text('Enter a number from 0 to 12'), findsOneWidget);
    expect(await env.docs('loans'), isEmpty);
  });

  testWidgets('knowing the rate switches to calculating the EMI', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await openLoanForm(tester);
    await enterField(tester, 'Loan name', 'Home loan');
    await enterField(tester, 'Principal amount', '100000');
    await enterField(tester, 'Number of installments', '12');
    await tapText(tester, 'I know the interest rate instead');
    expect(find.text('EMI amount'), findsNothing);
    await enterField(tester, 'Interest rate (% per year)', '12');
    await reveal(tester, find.textContaining('Calculated EMI: ₹8,884.88'));
    await tapText(tester, 'Save');
    final loan = (await env.docs('loans')).single;
    expect(loan['emiMinor'], 888488);
    expect(loan['annualRatePercent'], 12);
  });

  testWidgets('editing a loan does not ask for paid EMIs again', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await openLoanForm(tester);
    await fillBasics(tester);
    await tapText(tester, 'Save');
    expect(await env.docs('loans'), hasLength(1));
    await tapText(tester, 'Bike loan');
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    expect(find.text('EMIs already paid'), findsNothing);
    expect(find.text('First EMI date'), findsOneWidget);
  });
}
