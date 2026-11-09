import 'package:kept/features/accounts/domain/account.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/test_app.dart';

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await settle(tester);
}

Future<void> seedAccount(
  TestEnv env, {
  String id = 'acc1',
  String name = 'Salary',
  int opening = 1000000,
}) async {
  final now = DateTime.now();
  await env.db
      .collection('users')
      .doc(env.uid)
      .collection('accounts')
      .doc(id)
      .set(
        Account(
          id: id,
          name: name,
          type: AccountType.savings,
          openingBalanceMinor: opening,
          createdAt: now,
          updatedAt: now,
        ).toMap(),
      );
}

Future<void> seedTransaction(TestEnv env, Transaction tx) => env.db
    .collection('users')
    .doc(env.uid)
    .collection('transactions')
    .doc(tx.id)
    .set(tx.toMap(userId: env.uid));

Transaction _tx(
  String id,
  int amount,
  DateTime date, {
  String description = '',
  TransactionType type = TransactionType.expense,
  String category = 'food',
  String? accountId,
}) => Transaction(
  id: id,
  date: date,
  amountMinor: amount,
  type: type,
  categoryId: category,
  description: description,
  accountId: accountId,
  createdAt: date,
  updatedAt: date,
);

void main() {
  testWidgets('add account', (tester) async {
    final env = await pumpApp(tester);
    await openTab(tester, 'Accounts');
    await tapText(tester, 'Add account');
    await enterField(tester, 'Account name', 'HDFC Savings');
    await enterField(tester, 'Opening balance', '25,000');
    await tapText(tester, 'Save');

    final accounts = await env.docs('accounts');
    expect(accounts, hasLength(1));
    expect(accounts.single['name'], 'HDFC Savings');
    expect(accounts.single['openingBalanceMinor'], 2500000);
    expect(find.text('HDFC Savings'), findsWidgets);
  });

  testWidgets('add expense updates the account balance and dashboard', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await seedAccount(env);
    await settle(tester);

    await tester.tap(find.byTooltip('Add transaction'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '450');
    await choosePayment(tester, 'Salary');
    await chooseCategory(tester, 'Food');
    await enterField(tester, 'Description', 'Lunch');
    await tapText(tester, 'Save');

    final txs = await env.docs('transactions');
    expect(txs, hasLength(1));
    expect(txs.single['amountMinor'], 45000);
    expect(txs.single['type'], 'expense');
    expect(txs.single['accountId'], 'acc1');
    final account = (await env.docs('accounts')).single;
    expect(account['ledgerDeltaMinor'], -45000);
    expect(find.text('Lunch'), findsWidgets);
  });

  testWidgets('expense validation rejects an empty amount', (tester) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byTooltip('Add transaction'));
    await settle(tester);
    await tapText(tester, 'Save');
    expect(await env.docs('transactions'), isEmpty);
    await scrollToTop(tester);
    expect(find.text('Enter a valid amount greater than zero'), findsOneWidget);
  });

  testWidgets('add credit card: only the essentials are asked', (tester) async {
    final env = await pumpApp(tester);
    await openTab(tester, 'Accounts');
    await tapText(tester, 'Credit cards');
    await tapText(tester, 'Add card');
    // Statement day is no longer asked.
    expect(find.text('Statement day'), findsNothing);
    expect(find.text('Last 4 digits'), findsNothing, reason: 'tucked away');
    await enterField(tester, 'Card name', 'Millennia');
    await enterField(tester, 'Credit limit', '100000');
    await enterField(tester, 'Current outstanding', '25000');
    final due = await pickDate(tester, 'Payment due date');
    await tapText(tester, 'Save');

    final cards = await env.docs('credit_cards');
    expect(cards.single['creditLimitMinor'], 10000000);
    expect(cards.single['openingOutstandingMinor'], 2500000);
    expect(cards.single['dueDay'], due.day);
    // Statement day is worked out from the due day (about 20 days earlier).
    expect(
      cards.single['statementDay'],
      CreditCard.defaultStatementDay(due.day),
    );
    expect(
      cards.single.keys.any((k) => k.toLowerCase().contains('cvv')),
      isFalse,
    );
    expect(find.text('25% used'), findsOneWidget);
    // A due-date reminder is created for the card.
    final reminders = await env.docs('reminders');
    expect(reminders.single['entityType'], 'creditCard');
  });

  testWidgets('add credit card: the payment due date is required', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await openTab(tester, 'Accounts');
    await tapText(tester, 'Credit cards');
    await tapText(tester, 'Add card');
    await enterField(tester, 'Card name', 'X');
    await enterField(tester, 'Credit limit', '1000');
    await tapText(tester, 'Save');
    await reveal(tester, find.text('Choose the payment due date'));
    expect(find.text('Choose the payment due date'), findsOneWidget);
    expect(await env.docs('credit_cards'), isEmpty);
  });

  testWidgets('card last 4 digits must be exactly four digits', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Accounts');
    await tapText(tester, 'Credit cards');
    await tapText(tester, 'Add card');
    await enterField(tester, 'Card name', 'X');
    await enterField(tester, 'Credit limit', '1000');
    await pickDate(tester, 'Payment due date');
    await tapText(tester, 'More details (optional)');
    await enterField(tester, 'Last 4 digits', '12');
    await tapText(tester, 'Save');
    await reveal(tester, find.text('Enter exactly 4 digits'));
    expect(find.text('Enter exactly 4 digits'), findsOneWidget);
  });

  testWidgets('add loan: the interest rate is calculated, not asked', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await openTab(tester, 'Loans');
    await tapText(tester, 'Add loan');
    // No interest-rate field in the default flow.
    expect(find.text('Interest rate (% per year)'), findsNothing);
    await enterField(tester, 'Loan name', 'Car loan');
    await enterField(tester, 'Principal amount', '100000');
    await enterField(tester, 'EMI amount', '8884.88');
    await enterField(tester, 'Number of installments', '12');
    // ₹1,00,000 repaid by 12 × ₹8,884.88 is 12% a year.
    await reveal(tester, find.textContaining('12.00% per year'));
    expect(find.textContaining('12.00% per year'), findsOneWidget);
    await tapText(tester, 'Save');

    final loans = await env.docs('loans');
    expect(loans.single['emiMinor'], 888488);
    expect(loans.single['annualRatePercent'], closeTo(12, 0.01));
    expect(find.text('Car loan'), findsWidgets);
    await tapText(tester, 'Car loan');
    expect(find.text('0 of 12 EMIs paid'), findsWidgets);
    expect(find.text('Mark EMI paid'), findsOneWidget);
    // The rate is solved numerically (it is never a round number), so it
    // must be shown to two decimals, not as 12.000000000000002.
    await reveal(tester, find.textContaining('12.00% ·'));
    expect(find.textContaining('12.00% ·'), findsOneWidget);
  });

  testWidgets('create reminder schedules notifications', (tester) async {
    final env = await pumpApp(tester);
    await openTab(tester, 'More');
    await tapText(tester, 'Reminders');
    await tapText(tester, 'New reminder');
    await enterField(tester, 'Title', 'Gym');
    await tapText(tester, 'Daily');
    await tapText(tester, 'Save');
    await settle(tester);

    final reminders = await env.docs('reminders');
    expect(reminders.single['title'], 'Gym');
    expect(reminders.single['recurrence']['frequency'], 'daily');
    expect(env.notifications.scheduled, isNotEmpty);
    expect(env.notifications.scheduled.every((n) => n.title == 'Gym'), isTrue);
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('changing month changes the transactions shown', (tester) async {
    final env = await pumpApp(tester);
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 10);
    await seedTransaction(
      env,
      _tx(
        'cur',
        1000,
        DateTime(now.year, now.month, 1, 10),
        description: 'This month item',
      ),
    );
    await seedTransaction(
      env,
      _tx('old', 2000, lastMonth, description: 'Last month item'),
    );
    await openTab(tester, 'Transactions');
    expect(find.text('This month item'), findsOneWidget);
    expect(find.text('Last month item'), findsNothing);

    await tester.tap(find.byTooltip('Previous month').first);
    await settle(tester);
    expect(find.text('Last month item'), findsOneWidget);
    expect(find.text('This month item'), findsNothing);
    expect(find.text(DateFormat.yMMMM().format(lastMonth)), findsWidgets);
  });

  testWidgets('search filters transactions by text', (tester) async {
    final env = await pumpApp(tester);
    final day = DateTime(DateTime.now().year, DateTime.now().month, 1, 9);
    await seedTransaction(
      env,
      _tx('a', 1000, day, description: 'Swiggy dinner'),
    );
    await seedTransaction(
      env,
      _tx('b', 3000, day, description: 'Amazon order', category: 'shopping'),
    );
    await openTab(tester, 'Transactions');
    await tester.enterText(find.byType(TextField).first, 'swiggy');
    await settle(tester);
    expect(find.text('Swiggy dinner'), findsOneWidget);
    expect(find.text('Amazon order'), findsNothing);

    // Category labels are searchable too.
    await tester.enterText(find.byType(TextField).first, 'shopping');
    await settle(tester);
    expect(find.text('Amazon order'), findsOneWidget);
    expect(find.text('Swiggy dinner'), findsNothing);
  });

  testWidgets('global search groups results by type', (tester) async {
    final env = await pumpApp(tester);
    await seedAccount(env, name: 'Swiggy wallet');
    await seedTransaction(
      env,
      _tx('a', 1000, DateTime.now(), description: 'Swiggy dinner'),
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Search everything'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'swig');
    await settle(tester);
    expect(find.text('Transactions (1)'), findsOneWidget);
    expect(find.text('Accounts (1)'), findsOneWidget);
  });

  testWidgets('dashboard summarises the month with charts', (tester) async {
    final env = await pumpApp(tester);
    await seedAccount(env);
    final day = DateTime(DateTime.now().year, DateTime.now().month, 1, 9);
    await seedTransaction(
      env,
      _tx(
        'i',
        5000000,
        day,
        type: TransactionType.income,
        category: 'salary',
        accountId: 'acc1',
      ),
    );
    await seedTransaction(
      env,
      _tx('e1', 120000, day, category: 'food', accountId: 'acc1'),
    );
    await seedTransaction(
      env,
      _tx('e2', 80000, day, category: 'shopping', accountId: 'acc1'),
    );
    await settle(tester);

    expect(find.text('₹2,000'), findsWidgets); // spending hero
    expect(find.text('96% of income saved'), findsOneWidget);
    await reveal(tester, find.text('Spending by category'));
    expect(find.text('Food'), findsWidgets);
    await reveal(tester, find.text('Income vs spending'));
    await reveal(tester, find.text('Monthly spending trend'));
    await reveal(tester, find.text('Spending by account'));
  });

  testWidgets('main screens render in dark mode', (tester) async {
    await pumpApp(tester, themeMode: ThemeMode.dark);
    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
    for (final tab in ['Transactions', 'Accounts', 'Loans', 'More', 'Home']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull);
    }
  });
}
