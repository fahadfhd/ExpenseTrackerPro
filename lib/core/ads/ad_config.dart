import 'package:flutter/foundation.dart';

/// AdMob configuration.
///
/// Debug and profile builds always use Google's official **test** ad units,
/// so developing never risks an invalid-traffic strike on your account.
/// Release builds use the production unit ids below; while those are empty,
/// release builds show no ads at all.
///
/// To go live:
///  1. In AdMob, add the app for `com.fahadt.kept` (Android and iOS) and
///     create, per platform, one *Banner* ad unit and one *Rewarded* ad unit
///     (the rewarded one powers "watch a video, no ads for 24 hours").
///  2. Paste the four unit ids below (format `ca-app-pub-…/…`). While the
///     rewarded ids are empty, release builds simply don't offer the video.
///  3. Replace the test **App IDs** (format `ca-app-pub-…~…`) in
///     `android/app/src/main/AndroidManifest.xml`
///     (`com.google.android.gms.ads.APPLICATION_ID`) and
///     `ios/Runner/Info.plist` (`GADApplicationIdentifier`).
abstract final class AdConfig {
  // --- Production ids: fill these in -------------------------------------
  static const prodBannerAndroid = 'ca-app-pub-9837060319597631/8641328726';
  static const prodBannerIos = 'ca-app-pub-9837060319597631/9398956758';
  static const prodRewardedAndroid = '';
  static const prodRewardedIos = '';

  // --- Google's published test ids (never earn revenue, always safe) -----
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  /// Banner unit id for this platform and build, or null when ads should not
  /// be shown (unsupported platform, or release build without real ids).
  static String? bannerUnitId(TargetPlatform platform) => _unitId(
    platform,
    testAndroid: _testBannerAndroid,
    testIos: _testBannerIos,
    prodAndroid: prodBannerAndroid,
    prodIos: prodBannerIos,
  );

  /// Rewarded-video unit id, with the same rules as [bannerUnitId].
  static String? rewardedUnitId(TargetPlatform platform) => _unitId(
    platform,
    testAndroid: _testRewardedAndroid,
    testIos: _testRewardedIos,
    prodAndroid: prodRewardedAndroid,
    prodIos: prodRewardedIos,
  );

  static String? _unitId(
    TargetPlatform platform, {
    required String testAndroid,
    required String testIos,
    required String prodAndroid,
    required String prodIos,
  }) {
    final android = platform == TargetPlatform.android;
    final ios = platform == TargetPlatform.iOS;
    if (kIsWeb || (!android && !ios)) return null;
    if (!kReleaseMode) return android ? testAndroid : testIos;
    final id = android ? prodAndroid : prodIos;
    return id.isEmpty ? null : id;
  }
}
