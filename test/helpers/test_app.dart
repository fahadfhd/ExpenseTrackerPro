import 'package:kept/app/app.dart';
import 'package:kept/core/ads/ad_service.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/notifications/notification_planner.dart';
import 'package:kept/core/notifications/notification_service.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/features/reminders/application/reminder_providers.dart';
import 'package:kept/shared/widgets/payment_source_field.dart';
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

  String? channelName;
  String? channelDescription;

  @override
  Future<void> setChannelText({
    required String name,
    required String description,
  }) async {
    channelName = name;
    channelDescription = description;
  }

  @override
  Future<ReconcileResult> reconcile(List<PlannedNotification> desired) async {
    reconcileCalls++;
    scheduled = desired;
    return ReconcileResult(
      scheduled: desired.length,
      cancelled: 0,
      unchanged: 0,
    );
  }
}

class TestEnv {
  TestEnv({required this.db, required this.auth, required this.notifications});

  final FakeFirebaseFirestore db;
  final MockFirebaseAuth auth;
  final FakeNotificationService notifications;

  String get uid => auth.currentUser!.uid;

  Future<List<Map<String, dynamic>>> docs(String collection) async {
    final snapshot = await db
        .collection('users')
        .doc(uid)
        .collection(collection)
        .get();
    return [
      for (final d in snapshot.docs) {'id': d.id, ...d.data()},
    ];
  }
}

/// Pumps the real app against fake Firebase services.
Future<TestEnv> pumpApp(
  WidgetTester tester, {
  bool signedIn = true,
  ThemeMode themeMode = ThemeMode.light,
  Size physicalSize = const Size(1170, 2532),
  double devicePixelRatio = 3,
  MockFirebaseAuth? auth,
  String? localeCode,
  // Ads are off under test unless a test asks for them.
  bool adsReady = false,
  RewardedAdGateway? rewardedGateway,
  DateTime Function()? clock,
  Map<String, Object> extraPrefs = const {},
}) async {
  // Phone-sized surface so layouts match real devices.
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'settings.themeMode': themeMode.name,
    'settings.autoBackup': false,
    // Null follows the device language, which is English under test.
    'settings.locale': ?localeCode,
    ...extraPrefs,
  });
  final prefs = await SharedPreferences.getInstance();
  final db = FakeFirebaseFirestore();
  // Anonymous ("guest") user: no cloud backup is attempted in tests.
  auth ??= MockFirebaseAuth(
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
        // The AdMob SDK needs a real device; tests run without ads, or with
        // a fake rewarded-video gateway.
        adsReadyProvider.overrideWith((ref) => adsReady),
        adPrivacyOptionsRequiredProvider.overrideWith((ref) => false),
        if (rewardedGateway != null)
          rewardedAdGatewayProvider.overrideWithValue(rewardedGateway),
        if (clock != null) clockProvider.overrideWithValue(clock),
      ],
      child: const KeptApp(),
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
    // The target may be above the current position (lazy lists don't build
    // off-screen rows): start from the top, then scroll down to it.
    await tester.drag(_mainScrollable(tester), const Offset(0, 4000));
    await tester.pump();
  }
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

/// Taps a payment option (account, card or cash) by its title in the open
/// form. The field shows one kind of payment at a time, so the matching kind
/// is opened first.
Future<void> choosePayment(WidgetTester tester, String title) async {
  final field = find.byType(PaymentSourceField).first;
  Finder tile() => find.descendant(of: field, matching: find.text(title));
  await reveal(tester, field);
  final l10n = tester.element(field).l10n;
  for (final (label, isCash) in [
    (l10n.paymentTypeAccount, false),
    (l10n.creditCard, false),
    (l10n.paymentTypeCash, true),
    (l10n.dontRecord, true),
  ]) {
    if (tile().evaluate().isNotEmpty) break;
    final chip = find.descendant(
      of: field,
      matching: find.widgetWithText(ChoiceChip, label),
    );
    if (chip.evaluate().isEmpty) continue;
    await reveal(tester, chip);
    await tester.tap(chip.first, warnIfMissed: false);
    await settle(tester);
    // Cash is selected by its own chip.
    if (isCash) return;
  }
  await reveal(tester, tile());
  await tester.tap(tile().first, warnIfMissed: false);
  await settle(tester);
}

/// Taps a category chip by its label in the open form.
Future<void> chooseCategory(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(ChoiceChip, label);
  if (chip.evaluate().isEmpty) {
    // Only the first categories are shown until "More" is tapped.
    final more = find.widgetWithText(ActionChip, 'More');
    await reveal(tester, more);
    await tester.tap(more.last, warnIfMissed: false);
    await settle(tester);
  }
  await reveal(tester, chip);
  await tester.tap(chip.first, warnIfMissed: false);
  await settle(tester);
}

/// Opens the date field with [label] and accepts the picker's default date
/// (today), returning that date.
Future<DateTime> pickDate(WidgetTester tester, String label) async {
  final field = find.widgetWithText(InputDecorator, label);
  await reveal(tester, field);
  await tester.tap(field.last);
  await settle(tester);
  await tester.tap(find.text('OK'));
  await settle(tester);
  return DateTime.now();
}

/// Shows the rarer entry kinds (card bill, refund, repay a borrow) in the
/// open add form.
Future<void> showMoreTypes(WidgetTester tester) async {
  final more = find.widgetWithText(ActionChip, 'More');
  if (more.evaluate().isEmpty) return;
  await tester.tap(more.first, warnIfMissed: false);
  await settle(tester);
}
