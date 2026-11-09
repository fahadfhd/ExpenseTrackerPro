import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kept/core/ads/ad_config.dart';
import 'package:kept/core/ads/rewarded_ads.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/shared/widgets/ad_free_offer.dart';

/// An adaptive AdMob banner that sits inline in a scrolling screen.
///
/// It takes no space until an ad has actually loaded, and disappears again
/// if loading fails or the ad is disposed: no placeholder, no error text.
/// Under a loaded banner, a small "remove ads for 24 hours" line offers a
/// rewarded video. While the user has earned ad-free time the slot shows
/// nothing. Place it only on calm, read-only screens (dashboard, lists) —
/// never on forms or next to money-entry controls.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;
  int? _width;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  /// Drops the current banner (ads were switched off). A new one is
  /// requested when they come back.
  void _discard() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _requested = false;
    _width = null;
  }

  Future<void> _load(int width) async {
    final unitId = AdConfig.bannerUnitId(defaultTargetPlatform);
    if (unitId == null || _requested) return;
    _requested = true;
    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || size == null || !ref.read(bannersAllowedProvider)) {
        return;
      }
      final ad = BannerAd(
        adUnitId: unitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (!mounted || !identical(loaded, _ad)) return;
            setState(() => _loaded = true);
            // A banner is on screen: have the "remove ads" video ready too.
            ref.read(rewardedAdProvider.notifier).ensureLoaded();
          },
          onAdFailedToLoad: (failed, error) {
            debugPrint('Banner failed: ${error.code} ${error.message}');
            failed.dispose();
            if (mounted && identical(failed, _ad)) {
              setState(() {
                _ad = null;
                _loaded = false;
              });
            }
          },
        ),
      );
      setState(() => _ad = ad);
      await ad.load();
    } catch (e) {
      // Any SDK problem means "no banner", never a crash.
      debugPrint('Banner unavailable: $e');
      if (mounted) {
        setState(() {
          _ad?.dispose();
          _ad = null;
          _loaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bannersAllowedProvider, (_, allowed) {
      if (!allowed) setState(_discard);
    });
    if (!ref.watch(bannersAllowedProvider)) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (_width != width && width > 0) {
          _width = width;
          WidgetsBinding.instance.addPostFrameCallback((_) => _load(width));
        }
        final ad = _ad;
        if (!_loaded || ad == null) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Semantics(
                  label: context.l10n.adLabel,
                  child: SizedBox(
                    width: ad.size.width.toDouble(),
                    height: ad.size.height.toDouble(),
                    child: AdWidget(ad: ad),
                  ),
                ),
              ),
            ),
            const AdFreeOffer(),
          ],
        );
      },
    );
  }
}
