import 'package:expensetrackerpro/app/app.dart';
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/notifications/notification_planner.dart';
import 'package:expensetrackerpro/core/notifications/notification_service.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNotificationService implements NotificationService {
  List<PlannedNotification> scheduled = const [];
  int reconcileCalls = 0;
  bool enabled = true;

  @override
  Future<void> init() async {}

  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return enabled = true;
  }

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<ReconcileResult> reconcile(List<PlannedNotification> desired) async {
    reconcileCalls++;
    scheduled = desired;
    return ReconcileResult(scheduled: desired.length, cancelled: 0, unchanged: 0);
  }
}

class TestEnv {
  TestEnv({required this.db, required this.auth, required this.notifications});

  final FakeFirebaseFirestore db;
  final MockFirebaseAuth auth;
  final FakeNotificationService notifications;

  String get uid => auth.currentUser!.uid;

  Future<List<Map<String, dynamic>>> docs(String collection) async {
    final snapshot = await db.collection('users').doc(uid).collection(collection).get();
    return [for (final d in snapshot.docs) {'id': d.id, ...d.data()}];
  }
}

/// Pumps the real app against fake Firebase services.
Future<TestEnv> pumpApp(
  WidgetTester tester, {
  bool signedIn = true,
  ThemeMode themeMode = ThemeMode.light,
  Size physicalSize = const Size(1170, 2532),
  double devicePixelRatio = 3,
}) async {
  // Phone-sized surface so layouts match real devices.
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'settings.themeMode': themeMode.name,
    'settings.autoBackup': false,
  });
  final prefs = await SharedPreferences.getInstance();
  final db = FakeFirebaseFirestore();
  // Anonymous ("guest") user: no cloud backup is attempted in tests.
  final auth = MockFirebaseAuth(
    signedIn: signedIn,
    mockUser: MockUser(uid: 'test-user', isAnonymous: true),
  );
  final notifications = FakeNotificationService();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firestoreProvider.overrideWithValue(db),
        firebaseAuthProvider.overrideWithValue(auth),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const ExpanseTrackerProApp(),
    ),
  );
  await settle(tester);
  return TestEnv(db: db, auth: auth, notifications: notifications);
}

/// Pumps frames and lets fake-Firestore streams and debounce timers run.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// The front-most page/sheet list: the last large vertical scrollable
/// (text fields contain small scrollables of their own).
Finder _mainScrollable(WidgetTester tester) {
  final candidates = find
      .byWidgetPredicate(
        (w) =>
            w is Scrollable &&
            axisDirectionToAxis(w.axisDirection) == Axis.vertical,
      )
      .evaluate()
      .where((e) {
        final box = e.renderObject;
        return box is RenderBox && box.hasSize && box.size.height > 150;
      })
      .toList();
  return find.byElementPredicate((e) => e == candidates.last);
}

/// Scrolls the front-most list until [finder] is built and visible.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  // Let focus-driven scroll animations (autofocus, enterText) finish first.
  await settle(tester);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: _mainScrollable(tester),
      maxScrolls: 30,
    );
  }
  await tester.ensureVisible(finder.last);
  await tester.pump();
}

Future<void> enterField(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextFormField, label);
  await reveal(tester, field);
  await tester.enterText(field.last, text);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await reveal(tester, finder);
  await tester.tap(finder.last);
  await settle(tester);
}

/// Opens a [PickerField] by its label and chooses [option].
Future<void> pick(WidgetTester tester, String label, String option) async {
  final field = find.widgetWithText(InputDecorator, label);
  await reveal(tester, field);
  await tester.tap(field.last);
  await settle(tester);
  final choice = find.descendant(
    of: find.byType(BottomSheet).last,
    matching: find.text(option),
  );
  await tester.tap(choice.last);
  await settle(tester);
}

/// Scrolls the front-most list back to the top.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(_mainScrollable(tester), const Offset(0, 3000));
  await settle(tester);
}
