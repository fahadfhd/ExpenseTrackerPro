import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kept/core/ads/ad_free.dart';
import 'package:kept/core/ads/ad_service.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/shared/widgets/ad_free_offer.dart';

/// Settings → Ads: the "watch a video, no ads for 24 hours" offer and, where
/// the law requires it, the ad privacy options. Shows nothing at all when
/// this build has no ads.
class AdsSection extends ConsumerStatefulWidget {
  const AdsSection({super.key, required this.header});

  /// The Settings screen's section header, so this looks like the rest.
  final Widget Function(String text) header;

  @override
  ConsumerState<AdsSection> createState() => _AdsSectionState();
}

class _AdsSectionState extends ConsumerState<AdsSection> {
  @override
  void initState() {
    super.initState();
    // Someone opening this screen is looking at the offer: have a video ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(rewardedAdProvider.notifier).ensureLoaded();
    });
  }

  /// "Oct 5, 3:00 PM": the day, then the time (intl would join them with a
  /// bare space).
  String _when(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context).toString();
    return '${DateFormat.MMMd(locale).format(time)}, '
        '${DateFormat.jm(locale).format(time)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Whenever the offer needs a video and has none (ad-free time just ended,
    // ads just became ready), ask for one. Deferred: this fires while
    // providers are being updated, which is no moment to write to one.
    ref.listen(rewardedAdProvider, (_, next) {
      if (next != RewardedStatus.idle) return;
      Future.microtask(() {
        if (mounted) ref.read(rewardedAdProvider.notifier).ensureLoaded();
      });
    });
    final status = ref.watch(rewardedAdProvider);
    final until = ref.watch(adFreeUntilProvider);
    final privacy = ref.watch(adPrivacyOptionsRequiredProvider).value ?? false;
    final offered = status != RewardedStatus.off || until != null;
    if (!offered && !privacy) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header(l10n.settingsAds),
        if (until != null)
          ListTile(
            leading: const Icon(Icons.check_circle_outline_rounded),
            title: Text(l10n.adFreeActive(_when(context, until))),
          )
        else if (offered) ...[
          ListTile(
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: Text(l10n.adFreeTitle),
            subtitle: Text(switch (status) {
              RewardedStatus.loading => l10n.adFreeLoading,
              RewardedStatus.failed => l10n.adFreeUnavailable,
              _ => l10n.adFreeHelp,
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: status == RewardedStatus.failed
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                    onPressed: ref.read(rewardedAdProvider.notifier).retry,
                  )
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.adFreeWatch),
                    onPressed: status == RewardedStatus.ready
                        ? () => watchAdFreeVideo(context, ref)
                        : null,
                  ),
          ),
        ],
        if (privacy)
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.adPrivacyOptions),
            subtitle: Text(l10n.adPrivacyOptionsHelp),
            onTap: showAdPrivacyOptions,
          ),
      ],
    );
  }
}
