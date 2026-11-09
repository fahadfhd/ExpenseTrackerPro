import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/features/categories/domain/category.dart';

import '../helpers/test_app.dart';
import 'features_test.dart' as f;

/// The background sync providers (device notifications, loan reminders, the
/// custom-category registry) must keep working whichever screen is showing.
/// Riverpod pauses a stream provider once the widgets watching it are hidden
/// (another tab, a pushed screen), and a provider that is only `read` does not
/// keep its sources running, so they have to be held open explicitly.
void main() {
  tearDown(() => Categories.setCustom(const []));

  testWidgets(
    'a loan added from the Loans tab is scheduled as a notification at once',
    (tester) async {
      final env = await pumpApp(tester);
      await f.openTab(tester, 'Loans');
      await tapText(tester, 'Add loan');
      await enterField(tester, 'Loan name', 'Car loan');
      await enterField(tester, 'Principal amount', '100000');
      await enterField(tester, 'EMI amount', '8884.88');
      await enterField(tester, 'Number of installments', '12');
      await tapText(tester, 'Save');
      await settle(tester);

      expect(await env.docs('reminders'), hasLength(1));
      expect(
        env.notifications.scheduled.where((n) => n.title.contains('Car loan')),
        isNotEmpty,
        reason: 'the reminder exists but was never handed to the device',
      );
    },
  );

  testWidgets('a reminder that changes while a screen is open on top of the '
      'app is still rescheduled', (tester) async {
    final env = await pumpApp(tester);
    // Settings covers the tabs, so every widget watching reminders is paused.
    await f.openTab(tester, 'More');
    await tapText(tester, 'Settings');
    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 5));
    await env.db
        .collection('users')
        .doc(env.uid)
        .collection('reminders')
        .doc('r1')
        .set({
          'title': 'Water bill',
          'type': 'bill',
          'scheduledDate':
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'scheduledTime': '09:00',
          'recurrence': {'frequency': 'none', 'interval': 1},
          'offsetsMinutes': [0],
          'enabled': true,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
    await settle(tester);
    expect(
      env.notifications.scheduled.where((n) => n.title == 'Water bill'),
      isNotEmpty,
    );
  });

  testWidgets('custom categories arriving while a screen is open on top of '
      'the app are known to the registry', (tester) async {
    final env = await pumpApp(tester);
    await f.openTab(tester, 'More');
    await tapText(tester, 'Settings');
    final now = DateTime.now();
    await env.db
        .collection('users')
        .doc(env.uid)
        .collection('categories')
        .doc('custom_pets')
        .set({
          'name': 'Pets',
          'kind': 'expense',
          'iconKey': 'pets',
          'colorValue': 0xFFE07A3F,
          'archived': false,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });
    await settle(tester);
    expect(Categories.byId('custom_pets').customName, 'Pets');
  });
}
