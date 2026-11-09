import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/ads/ad_service.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/l10n/app_localizations.dart';
import 'package:kept/shared/widgets/ad_free_offer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_rewarded_ads.dart';
import '../helpers/test_app.dart';
import 'features_test.dart' as f;

final _en = lookupAppLocalizations(const Locale('en'));
final _ml = lookupAppLocalizations(const Locale('ml'));

const _prefKey = 'ads.adFreeUntil';

Future<void> _openSettings(WidgetTester tester, AppLocalizations l10n) async {
  await f.openTab(tester, l10n.navMore);
  await tapText(tester, l10n.settingsTitle);
}

/// The button (filled, outlined, text…) that carries [label].
Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.bySubtype<ButtonStyleButton>(),
);

bool _enabled(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(_button(label)).onPressed != null;

void main() {
  group('Settings → Ads', () {
    testWidgets('is not there when this build has no ads', (tester) async {
      await pumpApp(tester);
      await _openSettings(tester, _en);
      expect(find.text(_en.settingsAds), findsNothing);
      expect(find.text(_en.adFreeTitle), findsNothing);
    });

    testWidgets('a watched video switches ads off for 24 hours', (
      tester,
    ) async {
      final gateway = FakeRewardedGateway();
      await pumpApp(tester, adsReady: true, rewardedGateway: gateway);
      await _openSettings(tester, _en);
      await reveal(tester, find.text(_en.adFreeTitle));

      expect(find.text(_en.settingsAds), findsOneWidget);
      expect(find.text(_en.adFreeHelp), findsOneWidget);
      expect(_enabled(tester, _en.adFreeWatch), isTrue);

      await tester.tap(_button(_en.adFreeWatch));
      await settle(tester);

      expect(gateway.handedOut.single.shows, 1);
      expect(find.text(_en.adFreeThanks), findsOneWidget, reason: 'snack bar');
      await reveal(tester, find.textContaining('Ads are off until'));
      expect(find.textContaining('Ads are off until'), findsOneWidget);
      expect(find.text(_en.adFreeWatch), findsNothing, reason: 'no 2nd offer');
      expect(
        (await SharedPreferences.getInstance()).getInt(_prefKey),
        isNotNull,
      );
    });

    testWidgets('closing the video early earns nothing and says why', (
      tester,
    ) async {
      final gateway = FakeRewardedGateway([
        FakeRewardedAd(RewardOutcome.closedEarly),
      ]);
      await pumpApp(tester, adsReady: true, rewardedGateway: gateway);
      await _openSettings(tester, _en);
      await reveal(tester, find.text(_en.adFreeTitle));

      await tester.tap(_button(_en.adFreeWatch));
      await settle(tester);

      expect(find.text(_en.adFreeNotCompleted), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getInt(_prefKey), isNull);
      // Still on offer, with the next video already loading or loaded.
      expect(gateway.loadCalls, 2);
      await reveal(tester, find.text(_en.adFreeWatch));
      expect(_enabled(tester, _en.adFreeWatch), isTrue);
    });

    testWidgets('no video available: says so and can try again', (
      tester,
    ) async {
      final gateway = FakeRewardedGateway([null]);
      await pumpApp(tester, adsReady: true, rewardedGateway: gateway);
      await _openSettings(tester, _en);
      await reveal(tester, find.text(_en.adFreeTitle));

      expect(find.text(_en.adFreeUnavailable), findsOneWidget);
      expect(find.text(_en.adFreeWatch), findsNothing);

      await tester.tap(_button(_en.retry));
      await settle(tester);

      expect(find.text(_en.adFreeUnavailable), findsNothing);
      expect(find.text(_en.adFreeHelp), findsOneWidget);
      expect(_enabled(tester, _en.adFreeWatch), isTrue);
    });

    testWidgets('the button waits until a video has loaded', (tester) async {
      final gateway = FakeRewardedGateway()..hold = Completer();
      await pumpApp(tester, adsReady: true, rewardedGateway: gateway);
      await _openSettings(tester, _en);
      await reveal(tester, find.text(_en.adFreeTitle));

      expect(find.text(_en.adFreeLoading), findsOneWidget);
      expect(_enabled(tester, _en.adFreeWatch), isFalse);

      gateway.hold!.complete();
      await settle(tester);
      expect(find.text(_en.adFreeLoading), findsNothing);
      expect(_enabled(tester, _en.adFreeWatch), isTrue);
    });

    testWidgets('shows how long ads are off, then offers a video again', (
      tester,
    ) async {
      final start = DateTime(2026, 10, 5, 12);
      await pumpApp(
        tester,
        adsReady: true,
        rewardedGateway: FakeRewardedGateway(),
        clock: () => start,
        extraPrefs: {
          _prefKey: DateTime(2026, 10, 5, 15).millisecondsSinceEpoch,
        },
      );
      await _openSettings(tester, _en);
      await reveal(tester, find.textContaining('Ads are off until'));
      expect(find.textContaining('Oct 5, 3:00'), findsOneWidget);
      expect(find.text(_en.adFreeWatch), findsNothing);

      // Three hours pass: ads are back and the video is offered again.
      await tester.pump(const Duration(hours: 3, minutes: 1));
      await settle(tester);
      expect(find.textContaining('Ads are off until'), findsNothing);
      await reveal(tester, find.text(_en.adFreeWatch));
      expect(_enabled(tester, _en.adFreeWatch), isTrue);
    });

    testWidgets('is in Malayalam too', (tester) async {
      await pumpApp(
        tester,
        adsReady: true,
        rewardedGateway: FakeRewardedGateway(),
        localeCode: 'ml',
      );
      await _openSettings(tester, _ml);
      await reveal(tester, find.text(_ml.adFreeTitle));

      expect(find.text(_ml.settingsAds), findsOneWidget);
      expect(find.text(_ml.adFreeHelp), findsOneWidget);
      expect(_enabled(tester, _ml.adFreeWatch), isTrue);

      await tester.tap(_button(_ml.adFreeWatch));
      await settle(tester);
      expect(find.text(_ml.adFreeThanks), findsOneWidget);
    });
  });

  // Layout: the new section must fit a very narrow phone, and large text, in
  // both languages (any overflow is reported as a test failure). The two
  // extremes are checked separately, as in layout_test.dart.
  for (final locale in ['en', 'ml']) {
    for (final (name, textScale, size, ratio) in [
      ('2x text', 2.0, const Size(1170, 2532), 3.0),
      ('a 320 dp phone', 1.0, const Size(640, 1136), 2.0),
    ]) {
      testWidgets('Settings → Ads fits $name ($locale)', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final l10n = locale == 'ml' ? _ml : _en;
        await pumpApp(
          tester,
          adsReady: true,
          rewardedGateway: FakeRewardedGateway(),
          localeCode: locale,
          physicalSize: size,
          devicePixelRatio: ratio,
        );
        await _openSettings(tester, l10n);
        await reveal(tester, find.text(l10n.adFreeTitle));
        expect(_enabled(tester, l10n.adFreeWatch), isTrue);
      });
    }
  }

  group('the offer under a banner', () {
    Future<void> pumpOffer(
      WidgetTester tester,
      FakeRewardedGateway gateway,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            adsReadyProvider.overrideWith((ref) => true),
            rewardedAdGatewayProvider.overrideWithValue(gateway),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    TextButton(
                      onPressed: ref
                          .read(rewardedAdProvider.notifier)
                          .ensureLoaded,
                      child: const Text('banner loaded'),
                    ),
                    const AdFreeOffer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('appears only once a video is ready, and plays on tap', (
      tester,
    ) async {
      final gateway = FakeRewardedGateway();
      await pumpOffer(tester, gateway);
      expect(
        find.text(_en.adFreeShort),
        findsNothing,
        reason: 'nothing loaded',
      );

      await tester.tap(find.text('banner loaded'));
      await settle(tester);
      expect(find.text(_en.adFreeShort), findsOneWidget);

      await tester.tap(find.text(_en.adFreeShort));
      await settle(tester);
      expect(gateway.handedOut.single.shows, 1);
      expect(find.text(_en.adFreeThanks), findsOneWidget);
      expect(find.text(_en.adFreeShort), findsNothing, reason: 'ads are off');
    });

    testWidgets('stays hidden when no video can be loaded', (tester) async {
      await pumpOffer(tester, FakeRewardedGateway([null]));
      await tester.tap(find.text('banner loaded'));
      await settle(tester);
      expect(find.text(_en.adFreeShort), findsNothing);
    });
  });
}
