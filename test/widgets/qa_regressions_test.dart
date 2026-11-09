// Regression tests for the bugs found in the QA pass. Each test is named
// after the defect it guards against.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;

import 'package:kept/app/app_providers.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/notifications/notification_planner.dart';
import 'package:kept/core/utils/recurrence.dart';
import 'package:kept/features/accounts/data/account_repository.dart';
import 'package:kept/features/credit_cards/data/credit_card_repository.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/loans/domain/emi_engine.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/recurring/data/recurring_repository.dart';
import 'package:kept/features/recurring/domain/recurring_rule.dart';
import 'package:kept/features/reminders/domain/reminder.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/repositories_test.dart' show SyncStatusNotifierForTest;
import '../helpers/test_app.dart';
import 'features_test.dart' as f;

/// Real Firebase fires only `userChanges` (not `authStateChanges`) when a
/// guest account is linked to Google; this fake reproduces exactly that.
class _LinkingAuth extends MockFirebaseAuth {
  _LinkingAuth() : super(signedIn: false);
  final controller = StreamController<User?>.broadcast();
  @override
  Stream<User?> userChanges() => controller.stream;
  @override
  Stream<User?> authStateChanges() => const Stream.empty();
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

Loan _loan({int installments = 3, DateTime? firstDue, bool reminder = true}) {
  final now = DateTime.now();
  return Loan(
    id: 'loan1',
    name: 'Bike loan',
    principalMinor: 3000000,
    annualRatePercent: 12,
    installments: installments,
    frequency: EmiFrequency.monthly,
    emiMinor: EmiEngine.emi(
      principalMinor: 3000000,
      periodicRate: EmiEngine.periodicRate(12, EmiFrequency.monthly),
      installments: installments,
    ),
    firstDueDate: firstDue ?? DateTime(now.year, now.month + 1, 10),
    reminderEnabled: reminder,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('#1 notification permission', () {
    testWidgets('is requested once when a card creates a due-date reminder', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      expect(env.notifications.permissionRequests, 0);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Accounts'),
        ),
      );
      await settle(tester);
      await tapText(tester, 'Credit cards');
      await tapText(tester, 'Add card');
      await enterField(tester, 'Card name', 'Millennia');
      await enterField(tester, 'Credit limit', '100000');
      await pickDate(tester, 'Payment due date');
      await tapText(tester, 'Save');
      await settle(tester);
      expect(env.notifications.permissionRequests, 1);
      expect(env.notifications.scheduled, isNotEmpty);

      // Not asked again on later reminder changes.
      await tapText(tester, 'Millennia');
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await enterField(tester, 'Card name', 'Millennia Plus');
      await tapText(tester, 'Save');
      await settle(tester);
      expect(env.notifications.permissionRequests, 1);
    });

    testWidgets('is not requested when there are no reminders', (tester) async {
      final env = await pumpApp(tester);
      await settle(tester);
      expect(env.notifications.permissionRequests, 0);
    });
  });

  group('#2 deleted account/card references', () {
    late FakeFirebaseFirestore db;
    late TransactionRepository txRepo;
    late SyncStatusNotifierForTest status;
    DocumentReference<Map<String, dynamic>> user() =>
        db.collection('users').doc('u');

    setUp(() {
      db = FakeFirebaseFirestore();
      status = SyncStatusNotifierForTest();
      txRepo = TransactionRepository(
        userDoc: user(),
        writer: WriteDispatcher(status),
      );
    });

    test(
      'an account used by a loan, debt, recurring rule or card cannot be deleted',
      () async {
        final accounts = AccountRepository(
          userDoc: user(),
          writer: WriteDispatcher(status),
          transactions: txRepo,
        );
        expect(await accounts.isInUse('a'), isFalse);
        for (final (collection, field) in [
          ('loans', 'accountId'),
          ('borrow_lend', 'accountId'),
          ('recurring_transactions', 'toAccountId'),
          ('credit_cards', 'linkedAccountId'),
        ]) {
          await user().collection(collection).doc('ref').set({field: 'a'});
          expect(
            await accounts.isInUse('a'),
            isTrue,
            reason: '$collection.$field',
          );
          await user().collection(collection).doc('ref').delete();
        }
      },
    );

    test('a card used by a recurring rule cannot be deleted', () async {
      final cards = CreditCardRepository(
        userDoc: user(),
        writer: WriteDispatcher(status),
        transactions: txRepo,
      );
      await user().collection('recurring_transactions').doc('r').set({
        'creditCardId': 'c',
      });
      expect(await cards.isInUse('c'), isTrue);
    });

    test('recurring generation skips a rule whose account is gone', () async {
      final now = DateTime(2026, 3, 15);
      final recurring = RecurringRepository(
        userDoc: user(),
        writer: WriteDispatcher(status),
        transactions: txRepo,
      );
      recurring.save(
        RecurringRule(
          id: 'rent',
          title: 'Rent',
          type: TransactionType.expense,
          amountMinor: 1000,
          categoryId: 'housing',
          accountId: 'deleted',
          startDate: DateTime(2026, 3, 1),
          recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _settle();
      expect(await recurring.generateDue(now), 0);
      await _settle();
      expect(status.state.lastFailure, isNull);
      expect((await user().collection('transactions').get()).docs, isEmpty);
      final rule =
          (await user().collection('recurring_transactions').doc('rent').get())
              .data()!;
      expect(
        rule['lastGeneratedDate'],
        isNull,
        reason: 'rule must not advance',
      );
    });
  });

  test(
    '#3 auth state follows userChanges, so linking a guest updates the UI',
    () async {
      final auth = _LinkingAuth();
      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(authStateProvider, (_, _) {});
      addTearDown(sub.close);
      auth.controller.add(MockUser(uid: 'u', isAnonymous: true));
      await _settle();
      expect(container.read(authStateProvider).value!.isAnonymous, isTrue);
      // Linking keeps the uid but the user is no longer a guest.
      auth.controller.add(MockUser(uid: 'u', email: 'me@example.com'));
      await _settle();
      expect(container.read(authStateProvider).value!.isAnonymous, isFalse);
      expect(container.read(authStateProvider).value!.email, 'me@example.com');
    },
  );

  testWidgets(
    '#4 card edit labels the starting outstanding and shows the live one',
    (tester) async {
      final env = await pumpApp(tester);
      final now = DateTime.now();
      await env.db
          .collection('users')
          .doc(env.uid)
          .collection('credit_cards')
          .doc('c')
          .set({
            ...CreditCard(
              id: 'c',
              name: 'Regalia',
              creditLimitMinor: 10000000,
              openingOutstandingMinor: 2500000,
              statementDay: 1,
              dueDay: 20,
              createdAt: now,
              updatedAt: now,
            ).toMap(),
            'ledgerDeltaMinor': 500000,
          });
      await settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Accounts'),
        ),
      );
      await settle(tester);
      await tapText(tester, 'Credit cards');
      await tapText(tester, 'Regalia');
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      expect(find.text('Current outstanding'), findsNothing);
      await reveal(tester, find.text('Outstanding when added'));
      expect(find.textContaining('₹30,000'), findsOneWidget);
    },
  );

  group('#5 loan reminders follow the schedule', () {
    Future<List<Map<String, dynamic>>> loanReminders(TestEnv env) async =>
        (await env.docs(
          'reminders',
        )).where((r) => r['entityType'] == 'loan').toList();

    testWidgets('an active loan gets a reminder at the next unpaid EMI', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      final loan = _loan();
      await env.db
          .collection('users')
          .doc(env.uid)
          .collection('loans')
          .doc(loan.id)
          .set(loan.toMap());
      await settle(tester);
      final reminders = await loanReminders(env);
      expect(reminders, hasLength(1));
      expect(reminders.single['scheduledDate'], isNot(isEmpty));
    });

    testWidgets('a fully paid loan has its reminder removed', (tester) async {
      final env = await pumpApp(tester);
      final loan = _loan();
      final userDoc = env.db.collection('users').doc(env.uid);
      await userDoc.collection('loans').doc(loan.id).set(loan.toMap());
      await settle(tester);
      expect(await loanReminders(env), hasLength(1));
      for (var k = 1; k <= loan.installments; k++) {
        final id = LoanEvent.installmentEventId(loan.id, k);
        await userDoc
            .collection('loan_payments')
            .doc(id)
            .set(
              LoanEvent(
                id: id,
                loanId: loan.id,
                kind: LoanEventKind.emiPaid,
                installmentNumber: k,
                amountMinor: loan.emiMinor,
                date: DateTime.now(),
                createdAt: DateTime.now(),
              ).toMap(),
            );
      }
      await settle(tester);
      expect(await loanReminders(env), isEmpty);
    });

    testWidgets('a deleted loan leaves no orphan reminder', (tester) async {
      final env = await pumpApp(tester);
      final loan = _loan();
      final userDoc = env.db.collection('users').doc(env.uid);
      await userDoc.collection('loans').doc(loan.id).set(loan.toMap());
      await settle(tester);
      expect(await loanReminders(env), hasLength(1));
      await userDoc.collection('loans').doc(loan.id).delete();
      await settle(tester);
      expect(await loanReminders(env), isEmpty);
    });
  });

  test('#6 a frequent reminder cannot crowd out a rare one', () {
    final now = DateTime(2026, 3, 1, 8);
    Reminder r(String id, DateTime date, Recurrence rec, List<int> offsets) =>
        Reminder(
          id: id,
          title: id,
          type: ReminderType.custom,
          date: date,
          hour: 9,
          minute: 0,
          recurrence: rec,
          offsetsMinutes: offsets,
          createdAt: now,
          updatedAt: now,
        );
    final plan = NotificationPlanner.plan(
      [
        r('gym', now, const Recurrence(frequency: RecurrenceFrequency.daily), [
          0,
          60,
        ]),
        r('emi', DateTime(2026, 4, 10), Recurrence.none, [3 * 1440, 0]),
        // Beyond the 60-day window, but its next occurrence is still reserved.
        r('insurance', DateTime(2026, 9, 1), Recurrence.none, [0]),
      ],
      now: now,
      bodyFor: (_, _) => '',
    );
    expect(plan, hasLength(NotificationPlanner.maxPending));
    expect(plan.where((p) => p.reminderId == 'emi'), hasLength(2));
    expect(plan.where((p) => p.reminderId == 'insurance'), hasLength(1));
    // Still sorted by fire time.
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].fireAt.isBefore(plan[i - 1].fireAt), isFalse);
    }
  });

  test('#8 per-user UI state resets when the user changes', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'first'),
    );
    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(dashboardScopeProvider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    container
        .read(dashboardScopeProvider.notifier)
        .set(const DashboardScope(accountId: 'first-users-account'));
    container.read(transactionFilterProvider.notifier).setText('rent');
    await auth.signOut();
    await _settle();
    expect(container.read(dashboardScopeProvider).isAll, isTrue);
    expect(container.read(transactionFilterProvider).text, isEmpty);
  });

  testWidgets('#9 recurring entries are recorded when the app resumes', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await f.seedAccount(env);
    final now = DateTime.now();
    final rule = RecurringRule(
      id: 'netflix',
      title: 'Netflix',
      type: TransactionType.expense,
      amountMinor: 64900,
      categoryId: 'entertainment',
      accountId: 'acc1',
      startDate: DateTime(now.year, now.month, now.day),
      recurrence: const Recurrence(frequency: RecurrenceFrequency.monthly),
      createdAt: now,
      updatedAt: now,
    );
    // Added after launch-time generation already ran.
    await env.db
        .collection('users')
        .doc(env.uid)
        .collection('recurring_transactions')
        .doc(rule.id)
        .set(rule.toMap());
    await settle(tester);
    expect(await env.docs('transactions'), isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    final txs = await env.docs('transactions');
    expect(
      txs.single['id'],
      RecurringRule.occurrenceTransactionId(rule.id, rule.startDate),
    );
    // Running again (another resume) never duplicates.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    );
    await container.read(startupTasksProvider).catchUpRecurring();
    await settle(tester);
    expect(await env.docs('transactions'), hasLength(1));
  });

  test('#10 legacy records keep a category that matches their type', () {
    final debit = Transaction.fromMap('d', {
      'merchant': 'Salary advance repayment',
      'amount': 100,
      'category': 'Income',
      'isCredit': false,
      'occurredAt': '2026-03-01T10:00:00',
    });
    expect(debit.type, TransactionType.expense);
    expect(debit.categoryId, 'other');
    final credit = Transaction.fromMap('c', {
      'merchant': 'Swiggy refund',
      'amount': 100,
      'category': 'Food',
      'isCredit': true,
      'occurredAt': '2026-03-01T10:00:00',
    });
    expect(credit.type, TransactionType.income);
    expect(credit.categoryId, 'other_income');
    // Both are valid again, so imports and edits no longer fail.
    final repo = TransactionRepository(
      userDoc: FakeFirebaseFirestore().collection('users').doc('u'),
      writer: WriteDispatcher(SyncStatusNotifierForTest()),
    );
    expect(() => repo.saveAll([debit, credit]), returnsNormally);
  });
}
