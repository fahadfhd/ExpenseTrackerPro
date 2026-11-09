import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/ads/ad_config.dart';

void main() {
  group('AdConfig.bannerUnitId (non-release builds)', () {
    test('uses Google test units on Android and iOS', () {
      expect(
        AdConfig.bannerUnitId(TargetPlatform.android),
        'ca-app-pub-3940256099942544/6300978111',
      );
      expect(
        AdConfig.bannerUnitId(TargetPlatform.iOS),
        'ca-app-pub-3940256099942544/2934735716',
      );
    });

    test('never returns a production id outside release builds', () {
      // Developing must not touch real inventory.
      for (final p in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(
          AdConfig.bannerUnitId(p),
          startsWith('ca-app-pub-3940256099942544/'),
        );
      }
    });

    test('shows no ads on desktop platforms', () {
      for (final p in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(AdConfig.bannerUnitId(p), isNull);
      }
    });
  });

  group('AdConfig.rewardedUnitId (non-release builds)', () {
    test('uses Google test units on Android and iOS', () {
      expect(
        AdConfig.rewardedUnitId(TargetPlatform.android),
        'ca-app-pub-3940256099942544/5224354917',
      );
      expect(
        AdConfig.rewardedUnitId(TargetPlatform.iOS),
        'ca-app-pub-3940256099942544/1712485313',
      );
    });

    test('shows no video on desktop platforms', () {
      for (final p in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(AdConfig.rewardedUnitId(p), isNull);
      }
    });

    test('production rewarded ids are empty or real unit ids', () {
      // Empty means "no video offer in release", never a broken request.
      for (final id in [
        AdConfig.prodRewardedAndroid,
        AdConfig.prodRewardedIos,
      ]) {
        expect(id.isEmpty || id.contains('/'), isTrue);
      }
    });
  });

  test('production ids ship empty until the owner fills them in', () {
    // In release builds an empty id means "no ads", never a broken request.
    expect(
      AdConfig.prodBannerAndroid.isEmpty ||
          AdConfig.prodBannerAndroid.contains('/'),
      isTrue,
    );
    expect(
      AdConfig.prodBannerIos.isEmpty || AdConfig.prodBannerIos.contains('/'),
      isTrue,
    );
  });
}
