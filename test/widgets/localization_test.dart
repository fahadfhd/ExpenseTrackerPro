import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/l10n/app_localizations.dart';
import 'package:kept/shared/widgets/language_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;
import 'form_selection_test.dart' show seedCard;

final _en = lookupAppLocalizations(const Locale('en'));
final _ml = lookupAppLocalizations(const Locale('ml'));
const _malayalam = 'മലയാളം';

Future<void> _openAddForm(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_ml.addTransaction));
  await settle(tester);
}

void main() {
  tearDown(() => Categories.setCustom(const []));

  group('choosing the language', () {
    testWidgets('a saved Malayalam choice is used from the first frame', (
      tester,
    ) async {
      await pumpApp(tester, localeCode: 'ml');
      expect(find.text(_ml.navHome), findsWidgets);
      expect(find.text(_en.navHome), findsNothing);
      expect(
        Localizations.localeOf(tester.element(find.byType(Scaffold).first)),
        const Locale('ml'),
      );
    });

    testWidgets('Settings lists each language by its own name and switches '
        'the whole app at once', (tester) async {
      await pumpApp(tester);
      await f.openTab(tester, _en.navMore);
      await tapText(tester, _en.settingsTitle);

      await pick(tester, _en.settingsLanguage, _malayalam);
      expect(find.text(_ml.settingsTitle), findsWidgets);
      expect(find.text(_en.settingsTitle), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.locale'), 'ml');

      // Back to following the phone, which is English here.
      await pick(tester, _ml.settingsLanguage, _ml.languageSystem);
      expect(find.text(_en.settingsTitle), findsWidgets);
      expect(prefs.getString('settings.locale'), isNull);
    });

    testWidgets('the welcome screen can switch language before sign-in', (
      tester,
    ) async {
      await pumpApp(tester, signedIn: false);
      expect(find.text(_en.welcomeTitle), findsOneWidget);
      // The button names the current language in its own script.
      expect(
        find.descendant(
          of: find.byType(LanguageButton),
          matching: find.text('English'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(LanguageButton));
      await settle(tester);
      await tester.tap(find.text(_malayalam).last);
      await settle(tester);

      expect(find.text(_ml.welcomeTitle), findsOneWidget);
      expect(find.text(_en.welcomeTitle), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LanguageButton),
          matching: find.text(_malayalam),
        ),
        findsOneWidget,
      );
    });
  });

  group('screens in Malayalam', () {
    testWidgets('built-in categories are translated, money stays in Latin '
        'digits with the same grouping', (tester) async {
      final env = await pumpApp(tester, localeCode: 'ml');
      await f.seedAccount(env);
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, 1, 9);
      await f.seedTransaction(
        env,
        Transaction(
          id: 't',
          date: day,
          amountMinor: 12345678,
          type: TransactionType.expense,
          categoryId: 'food',
          accountId: 'acc1',
          createdAt: day,
          updatedAt: day,
        ),
      );
      await settle(tester);
      await f.openTab(tester, _ml.navTransactions);

      expect(find.text(_ml.catFood), findsWidgets);
      expect(find.text('Food'), findsNothing);
      expect(find.textContaining('₹1,23,456.78'), findsWidgets);
    });

    testWidgets('an expense can be added end to end', (tester) async {
      final env = await pumpApp(tester, localeCode: 'ml');
      await f.seedAccount(env);
      await settle(tester);
      await _openAddForm(tester);

      await enterField(tester, _ml.amount, '450');
      await choosePayment(tester, 'Salary');
      await chooseCategory(tester, _ml.catFood);
      await tapText(tester, _ml.save);

      final tx = (await env.docs('transactions')).single;
      expect(tx['type'], TransactionType.expense.name);
      expect(tx['categoryId'], 'food');
      expect(tx['accountId'], 'acc1');
      expect(tx['amountMinor'], 45000);
    });

    testWidgets('validation messages are shown in Malayalam', (tester) async {
      final env = await pumpApp(tester, localeCode: 'ml');
      await f.seedAccount(env);
      await settle(tester);
      await _openAddForm(tester);
      await enterField(tester, _ml.amount, '100');
      await tapText(tester, _ml.save);

      await reveal(tester, find.text(_ml.categoryRequired));
      expect(find.text(_ml.categoryRequired), findsOneWidget);
      expect(await env.docs('transactions'), isEmpty);
    });

    testWidgets('custom categories keep the name the user typed', (
      tester,
    ) async {
      final env = await pumpApp(tester, localeCode: 'ml');
      await _openAddForm(tester);
      await tapText(tester, _ml.categoryNew);
      await tester.enterText(find.byType(TextField).last, 'Pets');
      await tapText(tester, _ml.save);

      expect((await env.docs('categories')).single['name'], 'Pets');
      expect(find.text('Pets'), findsWidgets);
    });

    testWidgets('a long button label does not squeeze the next EMI amount', (
      tester,
    ) async {
      await pumpApp(tester, localeCode: 'ml');
      await f.openTab(tester, _ml.navLoans);
      await tapText(tester, _ml.addLoan);
      await enterField(tester, _ml.loanName, 'Car loan');
      await enterField(tester, _ml.principal, '100000');
      await enterField(tester, _ml.emiAmount, '8884.88');
      await enterField(tester, _ml.tenure, '12');
      await tapText(tester, _ml.save);
      await tapText(tester, 'Car loan');

      // The amount sits above the long "mark EMI paid" button; it used to be
      // squeezed down to a sliver beside it.
      final amount = find.text('₹8,884.88').first;
      expect(tester.getSize(amount).width, greaterThan(100));
      expect(
        tester.getTopLeft(find.text(_ml.markPaid)).dy,
        greaterThan(tester.getBottomLeft(amount).dy),
        reason: 'the button dropped below the amount',
      );
    });

    testWidgets('a custom name that matches the Malayalam name of a built-in '
        'category is rejected as a duplicate', (tester) async {
      final env = await pumpApp(tester, localeCode: 'ml');
      await _openAddForm(tester);
      await tapText(tester, _ml.categoryNew);
      await tester.enterText(find.byType(TextField).last, _ml.catFood);
      await tapText(tester, _ml.save);

      expect(find.text(_ml.categoryNameDuplicate), findsOneWidget);
      expect(await env.docs('categories'), isEmpty);
    });
  });

  group('text stored on reminders follows a language change', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Future<void> chooseLanguage(
      WidgetTester tester,
      AppLocalizations from,
      String option,
    ) async {
      await f.openTab(tester, from.navMore);
      await tapText(tester, from.settingsTitle);
      await pick(tester, from.settingsLanguage, option);
      await settle(tester);
    }

    Future<String> titleOf(TestEnv env, String id) async =>
        (await env.docs('reminders')).singleWhere((r) => r['id'] == id)['title']
            as String;

    testWidgets('scheduled notifications are re-worded', (tester) async {
      final env = await pumpApp(tester);
      final reminder = Reminder(
        id: 'r1',
        title: 'Rent',
        type: ReminderType.bill,
        date: today.add(const Duration(days: 3)),
        hour: 9,
        minute: 0,
        createdAt: now,
        updatedAt: now,
      );
      await env.db
          .collection('users')
          .doc(env.uid)
          .collection('reminders')
          .doc('r1')
          .set(reminder.toMap());
      await settle(tester);
      Set<String> bodies() => {
        for (final n in env.notifications.scheduled) n.body,
      };
      expect(bodies(), {notificationBody(_en, reminder, 0)});

      await chooseLanguage(tester, _en, _malayalam);
      expect(bodies(), {notificationBody(_ml, reminder, 0)});
      expect(
        bodies().single,
        isNot(notificationBody(_en, reminder, 0)),
        reason: 'the wording really is different',
      );
      // The user's own title is never translated.
      expect(env.notifications.scheduled.single.title, 'Rent');
    });

    testWidgets(
      'the Android notification channel is named in the app language',
      (tester) async {
        final env = await pumpApp(tester);
        await settle(tester);
        expect(env.notifications.channelName, _en.notificationChannelName);

        await chooseLanguage(tester, _en, _malayalam);
        expect(env.notifications.channelName, _ml.notificationChannelName);
        expect(
          env.notifications.channelDescription,
          _ml.notificationChannelDescription,
        );
      },
    );

    testWidgets('a credit card reminder is re-titled', (tester) async {
      final env = await pumpApp(tester);
      await seedCard(env);
      const name = 'Millennia ••4242';
      const id = 'creditCard_card1';
      await env.db
          .collection('users')
          .doc(env.uid)
          .collection('reminders')
          .doc(id)
          .set(
            Reminder(
              id: id,
              title: _en.reminderCardTitle(name),
              type: ReminderType.creditCardPayment,
              date: DateTime(now.year, DateTime.january, 20),
              hour: 10,
              minute: 0,
              recurrence: const Recurrence(
                frequency: RecurrenceFrequency.monthly,
              ),
              entityType: ReminderEntityType.creditCard,
              entityId: 'card1',
              offsetsMinutes: const [4320, 1440, 0],
              createdAt: now,
              updatedAt: now,
            ).toMap(),
          );
      await settle(tester);
      expect(await titleOf(env, id), _en.reminderCardTitle(name));

      await chooseLanguage(tester, _en, _malayalam);
      expect(await titleOf(env, id), _ml.reminderCardTitle(name));

      // And back again (Settings is still open).
      await pick(tester, _ml.settingsLanguage, _ml.languageSystem);
      await settle(tester);
      expect(await titleOf(env, id), _en.reminderCardTitle(name));
    });

    testWidgets('borrow and lend reminders are re-titled', (tester) async {
      final env = await pumpApp(tester);
      DebtRecord record(String id, DebtDirection direction) => DebtRecord(
        id: id,
        direction: direction,
        personName: 'Ravi',
        amountMinor: 500000,
        date: today,
        dueDate: today.add(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      );
      final userDoc = env.db.collection('users').doc(env.uid);
      for (final r in [
        record('d1', DebtDirection.borrowed),
        record('d2', DebtDirection.lent),
      ]) {
        await userDoc.collection('borrow_lend').doc(r.id).set(r.toMap());
        final borrowed = r.direction == DebtDirection.borrowed;
        final reminderId = Reminder.entityReminderId(
          ReminderEntityType.borrowLend,
          r.id,
        );
        await userDoc
            .collection('reminders')
            .doc(reminderId)
            .set(
              Reminder(
                id: reminderId,
                title: borrowed
                    ? _en.reminderBorrowedTitle('Ravi')
                    : _en.reminderLentTitle('Ravi'),
                type: borrowed ? ReminderType.borrowed : ReminderType.lent,
                date: r.dueDate!,
                hour: 9,
                minute: 0,
                entityType: ReminderEntityType.borrowLend,
                entityId: r.id,
                createdAt: now,
                updatedAt: now,
              ).toMap(),
            );
      }
      await settle(tester);

      await chooseLanguage(tester, _en, _malayalam);
      expect(
        await titleOf(env, 'borrowLend_d1'),
        _ml.reminderBorrowedTitle('Ravi'),
      );
      expect(
        await titleOf(env, 'borrowLend_d2'),
        _ml.reminderLentTitle('Ravi'),
      );
    });

    testWidgets('a loan reminder is re-titled', (tester) async {
      final env = await pumpApp(tester);
      await f.openTab(tester, _en.navLoans);
      await tapText(tester, _en.addLoan);
      await enterField(tester, _en.loanName, 'Car loan');
      await enterField(tester, _en.principal, '100000');
      await enterField(tester, _en.emiAmount, '8884.88');
      await enterField(tester, _en.tenure, '12');
      await tapText(tester, _en.save);
      final loanId = (await env.docs('loans')).single['id'] as String;
      final id = Reminder.entityReminderId(ReminderEntityType.loan, loanId);
      await settle(tester);
      expect(await titleOf(env, id), _en.reminderLoanTitle('Car loan'));

      await chooseLanguage(tester, _en, _malayalam);
      expect(await titleOf(env, id), _ml.reminderLoanTitle('Car loan'));
    });
  });
}
