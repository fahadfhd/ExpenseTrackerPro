import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kept/core/ads/ad_config.dart';
import 'package:kept/core/ads/ad_free.dart';
import 'package:kept/core/ads/ad_service.dart';
import 'package:kept/core/utils/clock.dart';

/// What happened when a rewarded video was shown.
enum RewardOutcome {
  /// The user watched enough to earn the reward.
  earned,

  /// The user closed the video before the end: no reward.
  closedEarly,

  /// The video could not be shown.
  failed,
}

/// A loaded rewarded video, good for one showing.
abstract class LoadedRewardedAd {
  Future<RewardOutcome> show();

  void dispose();
}

/// Loads rewarded videos. A seam over the AdMob SDK so the flow can be
/// tested without a device.
abstract class RewardedAdGateway {
  /// A video ready to show, or null when none could be loaded.
  Future<LoadedRewardedAd?> load();
}

class AdMobRewardedGateway implements RewardedAdGateway {
  const AdMobRewardedGateway();

  static const _loadTimeout = Duration(seconds: 30);

  @override
  Future<LoadedRewardedAd?> load() {
    final unitId = AdConfig.rewardedUnitId(defaultTargetPlatform);
    if (unitId == null) return Future.value();
    final done = Completer<LoadedRewardedAd?>();
    final timeout = Timer(_loadTimeout, () {
      if (!done.isCompleted) done.complete();
    });
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (done.isCompleted) {
            ad.dispose(); // arrived after we gave up
          } else {
            done.complete(_AdMobRewardedAd(ad));
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed: ${error.code} ${error.message}');
          if (!done.isCompleted) done.complete();
        },
      ),
    ).catchError((Object e) {
      debugPrint('Rewarded ad unavailable: $e');
      if (!done.isCompleted) done.complete();
    });
    return done.future.whenComplete(timeout.cancel);
  }
}

class _AdMobRewardedAd implements LoadedRewardedAd {
  _AdMobRewardedAd(this._ad);

  /// Far longer than any video plus its end card.
  static const _showTimeout = Duration(minutes: 5);

  final RewardedAd _ad;

  @override
  Future<RewardOutcome> show() {
    final done = Completer<RewardOutcome>();
    var earned = false;
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        if (!done.isCompleted) {
          done.complete(
            earned ? RewardOutcome.earned : RewardOutcome.closedEarly,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad not shown: ${error.code} ${error.message}');
        if (!done.isCompleted) done.complete(RewardOutcome.failed);
      },
    );
    _ad.show(onUserEarnedReward: (_, _) => earned = true).catchError((
      Object e,
    ) {
      debugPrint('Rewarded ad not shown: $e');
      if (!done.isCompleted) done.complete(RewardOutcome.failed);
    });
    // Safety net: if the SDK never reports the video closing, don't leave the
    // offer stuck on "showing" for the rest of the session.
    return done.future.timeout(
      _showTimeout,
      onTimeout: () => earned ? RewardOutcome.earned : RewardOutcome.failed,
    );
  }

  @override
  void dispose() => _ad.dispose();
}

final rewardedAdGatewayProvider = Provider<RewardedAdGateway>(
  (ref) => const AdMobRewardedGateway(),
);

/// Where the rewarded video is at.
enum RewardedStatus {
  /// Not on offer: ads are unavailable here or already switched off.
  off,

  /// On offer, but nothing requested yet.
  idle,
  loading,

  /// A video is loaded and can be shown.
  ready,
  showing,

  /// The last request found no video; may be retried.
  failed,
}

/// Loads one rewarded video at a time and plays it when the user asks.
///
/// Loading is on demand ([ensureLoaded]): the banner that sits above the
/// offer and the Settings screen ask for it, so a session that never shows
/// either never requests a video. Earning the reward switches ads off for
/// [adFreeDuration].
class RewardedAdController extends Notifier<RewardedStatus> {
  /// Google's rewarded ads expire after an hour; replace them before that.
  static const _adLifetime = Duration(minutes: 50);

  /// After a failed request, automatic retries wait this long.
  static const _retryAfter = Duration(seconds: 30);

  LoadedRewardedAd? _ad;
  Timer? _stale;
  DateTime? _failedAt;
  int _generation = 0;

  @override
  RewardedStatus build() {
    final eligible =
        (ref.watch(adsReadyProvider).value ?? false) &&
        !ref.watch(adFreeActiveProvider) &&
        AdConfig.rewardedUnitId(defaultTargetPlatform) != null;
    ref.onDispose(_reset);
    return eligible ? RewardedStatus.idle : RewardedStatus.off;
  }

  void _reset() {
    _generation++; // a request still in flight is discarded when it returns
    _stale?.cancel();
    _stale = null;
    _ad?.dispose();
    _ad = null;
  }

  /// Starts loading a video if none is loaded or loading.
  void ensureLoaded() {
    switch (state) {
      case RewardedStatus.idle:
        _load();
      case RewardedStatus.failed:
        final failedAt = _failedAt;
        if (failedAt == null ||
            ref.read(clockProvider)().difference(failedAt) >= _retryAfter) {
          _load();
        }
      case RewardedStatus.off ||
          RewardedStatus.loading ||
          RewardedStatus.ready ||
          RewardedStatus.showing:
        break;
    }
  }

  /// Asks again right away (the user pressed "try again").
  void retry() {
    if (state == RewardedStatus.failed) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    state = RewardedStatus.loading;
    LoadedRewardedAd? ad;
    try {
      ad = await ref.read(rewardedAdGatewayProvider).load();
    } catch (e) {
      debugPrint('Rewarded ad request failed: $e');
    }
    if (generation != _generation) {
      ad?.dispose(); // ads were switched off while it loaded
      return;
    }
    if (ad == null) {
      _failedAt = ref.read(clockProvider)();
      state = RewardedStatus.failed;
      return;
    }
    _ad = ad;
    _stale?.cancel();
    _stale = Timer(_adLifetime, _replaceStale);
    state = RewardedStatus.ready;
  }

  void _replaceStale() {
    if (state != RewardedStatus.ready) return;
    _ad?.dispose();
    _ad = null;
    _load();
  }

  /// Plays the loaded video. Call only when the user asked for it.
  Future<RewardOutcome> watch() async {
    final ad = _ad;
    if (state != RewardedStatus.ready || ad == null) {
      return RewardOutcome.failed;
    }
    _ad = null;
    _stale?.cancel();
    state = RewardedStatus.showing;
    final outcome = await ad.show();
    ad.dispose();
    if (outcome == RewardOutcome.earned) {
      // Switches ads off, which rebuilds this controller as `off`.
      await ref.read(adFreeUntilProvider.notifier).grant();
    } else {
      state = RewardedStatus.idle;
      _load(); // have the next one ready
    }
    return outcome;
  }
}

final rewardedAdProvider =
    NotifierProvider<RewardedAdController, RewardedStatus>(
      RewardedAdController.new,
    );

/// Whether banners may be shown: ads are ready and not switched off.
final bannersAllowedProvider = Provider<bool>(
  (ref) =>
      (ref.watch(adsReadyProvider).value ?? false) &&
      !ref.watch(adFreeActiveProvider),
);
