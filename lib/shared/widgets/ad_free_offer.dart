import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/utils/haptics.dart';

/// Plays the rewarded video the user asked for and tells them what happened.
///
/// Only call this from a button the user pressed: a rewarded video must never
/// start on its own.
Future<void> watchAdFreeVideo(BuildContext context, WidgetRef ref) async {
  // Taken before the video: the widget that started it may be gone by the
  // time it ends (earning the reward removes the banner it sat under).
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final outcome = await ref.read(rewardedAdProvider.notifier).watch();
  if (outcome == RewardOutcome.earned) Haptics.success();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          RewardOutcome.earned => l10n.adFreeThanks,
          RewardOutcome.closedEarly => l10n.adFreeNotCompleted,
          RewardOutcome.failed => l10n.adFreeUnavailable,
        }),
      ),
    );
}

/// A discreet line under a banner: "Remove ads for 24 hours". It only appears
/// once a video is loaded and ready to play, so it is never a dead button.
class AdFreeOffer extends ConsumerWidget {
  const AdFreeOffer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(rewardedAdProvider) != RewardedStatus.ready) {
      return const SizedBox.shrink();
    }
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
        label: Text(context.l10n.adFreeShort),
        onPressed: () => watchAdFreeVideo(context, ref),
      ),
    );
  }
}
