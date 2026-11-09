import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/ads/ad_free.dart';
import 'package:kept/core/ads/ad_service.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_rewarded_ads.dart';

/// Lets queued futures (a fake load, a provider rebuild) finish.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late DateTime now;
  late FakeRewardedGateway gateway;
  late ProviderContainer container;

  RewardedStatus status() => container.read(rewardedAdProvider);
  RewardedAdController controller() =>
      container.read(rewardedAdProvider.notifier);

  /// Starts a container with ads ready (unless [adsReady] is false).
  Future<void> start({
    FakeRewardedGateway? fake,
    bool adsReady = true,
    Map<String, Object> stored = const {},
    // How to let queued futures finish (a widget test pumps instead).
    Future<void> Function()? flush,
    // A widget test must dispose the container itself, before its own
    // check for timers that are still pending.
    bool disposeAtTearDown = true,
  }) async {
    now = DateTime(2026, 10, 5, 12);
    gateway = fake ?? FakeRewardedGateway();
    SharedPreferences.setMockInitialValues(stored);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        clockProvider.overrideWithValue(() => now),
        adsReadyProvider.overrideWith((ref) => adsReady),
        rewardedAdGatewayProvider.overrideWithValue(gateway),
      ],
    );
    if (disposeAtTearDown) addTearDown(container.dispose);
    // Keep the controller alive like the app does while a screen shows it.
    container.listen(rewardedAdProvider, (_, _) {});
    await container.read(adsReadyProvider.future);
    await (flush ?? settle)();
  }

  group('eligibility', () {
    test('there is no offer while ads are not ready', () async {
      await start(adsReady: false);
      expect(status(), RewardedStatus.off);
      controller().ensureLoaded();
      await settle();
      expect(status(), RewardedStatus.off);
      expect(gateway.loadCalls, 0);
    });

    test('there is no offer while ads are switched off', () async {
      await start(
        stored: {
          'ads.adFreeUntil': DateTime(2026, 10, 6, 1).millisecondsSinceEpoch,
        },
      );
      expect(status(), RewardedStatus.off);
    });

    test('a video is requested only when something asks for it', () async {
      await start();
      expect(status(), RewardedStatus.idle);
      expect(gateway.loadCalls, 0, reason: 'nothing needs it yet');
    });
  });

  group('loading', () {
    test('ensureLoaded fetches one video and keeps it', () async {
      await start();
      controller().ensureLoaded();
      expect(status(), RewardedStatus.loading);
      await settle();
      expect(status(), RewardedStatus.ready);

      controller().ensureLoaded();
      controller().ensureLoaded();
      await settle();
      expect(gateway.loadCalls, 1, reason: 'no second request while ready');
    });

    test('while a video loads, asking again does not start another', () async {
      final fake = FakeRewardedGateway()..hold = Completer();
      await start(fake: fake);
      controller().ensureLoaded();
      controller().ensureLoaded();
      expect(fake.loadCalls, 1);
      fake.hold!.complete();
      await settle();
      expect(status(), RewardedStatus.ready);
    });

    test(
      'a failed request is retried only after a pause, or on demand',
      () async {
        await start(fake: FakeRewardedGateway([null, FakeRewardedAd()]));
        controller().ensureLoaded();
        await settle();
        expect(status(), RewardedStatus.failed);

        controller().ensureLoaded();
        await settle();
        expect(gateway.loadCalls, 1, reason: 'too soon to ask again');

        now = now.add(const Duration(seconds: 31));
        controller().ensureLoaded();
        await settle();
        expect(gateway.loadCalls, 2);
        expect(status(), RewardedStatus.ready);
      },
    );

    test('retry asks again immediately', () async {
      await start(fake: FakeRewardedGateway([null]));
      controller().ensureLoaded();
      await settle();
      expect(status(), RewardedStatus.failed);

      controller().retry();
      await settle();
      expect(status(), RewardedStatus.ready);
    });

    test(
      'a video that arrives after ads were switched off is dropped',
      () async {
        final fake = FakeRewardedGateway()..hold = Completer();
        await start(fake: fake);
        controller().ensureLoaded();

        await container.read(adFreeUntilProvider.notifier).grant();
        fake.hold!.complete();
        await settle();

        expect(status(), RewardedStatus.off);
        expect(fake.handedOut.single.disposed, isTrue);
      },
    );

    test('a loaded video is thrown away when ads get switched off', () async {
      await start();
      controller().ensureLoaded();
      await settle();
      final ad = gateway.handedOut.single;

      await container.read(adFreeUntilProvider.notifier).grant();
      await settle();
      expect(status(), RewardedStatus.off);
      expect(ad.disposed, isTrue);
    });
  });

  group('watching', () {
    Future<void> ready([FakeRewardedGateway? fake]) async {
      await start(fake: fake);
      controller().ensureLoaded();
      await settle();
      expect(status(), RewardedStatus.ready);
    }

    test('finishing the video earns 24 hours without ads', () async {
      await ready();
      final ad = gateway.handedOut.single;

      final outcome = await controller().watch();
      await settle();

      expect(outcome, RewardOutcome.earned);
      expect(ad.shows, 1);
      expect(ad.disposed, isTrue);
      expect(
        container.read(adFreeUntilProvider),
        now.add(const Duration(hours: 24)),
      );
      expect(status(), RewardedStatus.off);
    });

    test('the video is showing while it plays', () async {
      final ad = FakeRewardedAd()..gate = Completer();
      await ready(FakeRewardedGateway([ad]));

      final playing = controller().watch();
      expect(status(), RewardedStatus.showing);
      ad.gate!.complete();
      await playing;
    });

    test('closing it early earns nothing and readies the next one', () async {
      await ready(
        FakeRewardedGateway([FakeRewardedAd(RewardOutcome.closedEarly)]),
      );

      final outcome = await controller().watch();
      await settle();

      expect(outcome, RewardOutcome.closedEarly);
      expect(container.read(adFreeUntilProvider), isNull);
      expect(status(), RewardedStatus.ready, reason: 'a new video is loaded');
      expect(gateway.loadCalls, 2);
    });

    test('a video that cannot be shown earns nothing', () async {
      await ready(FakeRewardedGateway([FakeRewardedAd(RewardOutcome.failed)]));
      expect(await controller().watch(), RewardOutcome.failed);
      expect(container.read(adFreeUntilProvider), isNull);
    });

    test('watch does nothing when no video is ready', () async {
      await start();
      expect(await controller().watch(), RewardOutcome.failed);
      expect(gateway.loadCalls, 0);
    });
  });

  testWidgets('a video loaded for nearly an hour is replaced', (tester) async {
    await start(flush: () => tester.pump(), disposeAtTearDown: false);
    controller().ensureLoaded();
    await tester.pump();
    final first = gateway.handedOut.single;

    await tester.pump(const Duration(minutes: 51));
    await tester.pump();
    expect(first.disposed, isTrue);
    expect(gateway.handedOut, hasLength(2));
    expect(status(), RewardedStatus.ready);
    container.dispose(); // cancels the new video's own expiry timer
  });
}
