import 'dart:async';

import 'package:kept/core/ads/rewarded_ads.dart';

/// A rewarded video that "plays" instantly (or when [gate] is released) and
/// ends with [outcome].
class FakeRewardedAd implements LoadedRewardedAd {
  FakeRewardedAd([this.outcome = RewardOutcome.earned]);

  final RewardOutcome outcome;

  /// While set, the video keeps "playing" until it completes.
  Completer<void>? gate;
  int shows = 0;
  bool disposed = false;

  @override
  Future<RewardOutcome> show() async {
    shows++;
    await gate?.future;
    return outcome;
  }

  @override
  void dispose() => disposed = true;
}

/// Hands out [FakeRewardedAd]s in order. A `null` entry is a failed request;
/// when the list runs out every request succeeds with a fresh ad that earns
/// the reward.
class FakeRewardedGateway implements RewardedAdGateway {
  FakeRewardedGateway([List<FakeRewardedAd?> results = const []])
    : _results = [...results];

  final List<FakeRewardedAd?> _results;

  /// While set, [load] waits for it, so tests can look at the loading state.
  Completer<void>? hold;
  int loadCalls = 0;

  /// Every ad this gateway handed out.
  final handedOut = <FakeRewardedAd>[];

  @override
  Future<LoadedRewardedAd?> load() async {
    loadCalls++;
    await hold?.future;
    final ad = _results.isEmpty ? FakeRewardedAd() : _results.removeAt(0);
    if (ad != null) handedOut.add(ad);
    return ad;
  }
}
