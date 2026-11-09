import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/ads/ad_free.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/ads/ad_service.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late SharedPreferences prefs;

  Future<ProviderContainer> start([
    Map<String, Object> stored = const {},
  ]) async {
    now = DateTime(2026, 10, 5, 12);
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    return _container(prefs, () => now);
  }

  test('ads are on until a video has been watched', () async {
    final c = await start();
    expect(c.read(adFreeUntilProvider), isNull);
    expect(c.read(adFreeActiveProvider), isFalse);
  });

  test('a reward switches ads off for 24 hours and is remembered', () async {
    final c = await start();
    await c.read(adFreeUntilProvider.notifier).grant();

    expect(c.read(adFreeActiveProvider), isTrue);
    expect(c.read(adFreeUntilProvider), now.add(const Duration(hours: 24)));

    // A new session (new container, same storage) still has ads off.
    final restarted = _container(prefs, () => now);
    expect(restarted.read(adFreeActiveProvider), isTrue);
    expect(
      restarted.read(adFreeUntilProvider),
      now.add(const Duration(hours: 24)),
    );
  });

  test('ads come back once the 24 hours have passed', () async {
    final c = await start();
    await c.read(adFreeUntilProvider.notifier).grant();

    now = now.add(const Duration(hours: 23, minutes: 59));
    c.read(adFreeUntilProvider.notifier).refresh();
    expect(c.read(adFreeActiveProvider), isTrue, reason: 'one minute left');

    now = now.add(const Duration(minutes: 2));
    c.read(adFreeUntilProvider.notifier).refresh();
    expect(c.read(adFreeActiveProvider), isFalse);
    expect(prefs.getInt('ads.adFreeUntil'), isNull, reason: 'forgotten');
  });

  test('an expired value left in storage does not switch ads off', () async {
    final c = await start({
      'ads.adFreeUntil': DateTime(
        2026,
        10,
        5,
        11,
      ).millisecondsSinceEpoch, // an hour ago
    });
    expect(c.read(adFreeActiveProvider), isFalse);
    expect(prefs.getInt('ads.adFreeUntil'), isNull);
  });

  test('a stored time further ahead than one reward is cut back', () async {
    // Moving the phone's clock back would otherwise stretch the reward.
    final c = await start({
      'ads.adFreeUntil': DateTime(2026, 12, 25).millisecondsSinceEpoch,
    });
    expect(c.read(adFreeUntilProvider), now.add(const Duration(hours: 24)));
  });

  test('watching again after expiry gives a fresh 24 hours', () async {
    final c = await start();
    final controller = c.read(adFreeUntilProvider.notifier);
    await controller.grant();
    now = now.add(const Duration(days: 2));
    controller.refresh();
    await controller.grant();
    expect(c.read(adFreeUntilProvider), now.add(const Duration(hours: 24)));
  });

  group('banners', () {
    test('are allowed only when ads are ready and not switched off', () async {
      final c = await start();
      await c.read(adsReadyProvider.future);
      expect(c.read(bannersAllowedProvider), isTrue);

      await c.read(adFreeUntilProvider.notifier).grant();
      expect(c.read(bannersAllowedProvider), isFalse);
    });

    test('are not allowed while ads are not ready', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          adsReadyProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(c.dispose);
      await c.read(adsReadyProvider.future);
      expect(c.read(bannersAllowedProvider), isFalse);
    });
  });

  testWidgets('the timer ends the ad-free time by itself', (tester) async {
    final c = await start();
    await c.read(adFreeUntilProvider.notifier).grant();
    expect(c.read(adFreeActiveProvider), isTrue);

    // Time passes for the timer (the clock only matters for refresh()).
    await tester.pump(const Duration(hours: 24, seconds: 1));
    expect(c.read(adFreeActiveProvider), isFalse);
  });
}

ProviderContainer _container(SharedPreferences prefs, DateTime Function() now) {
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(now),
      adsReadyProvider.overrideWith((ref) => true),
    ],
  );
  addTearDown(c.dispose);
  return c;
}
