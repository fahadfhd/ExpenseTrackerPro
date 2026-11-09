import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kept/core/ads/ad_config.dart';

/// Whether this build can show ads at all.
bool get adsSupported =>
    AdConfig.bannerUnitId(defaultTargetPlatform) != null ||
    AdConfig.rewardedUnitId(defaultTargetPlatform) != null;

/// Starts AdMob: asks for consent where the law requires it (Google's User
/// Messaging Platform shows the GDPR/UK form only to users it applies to),
/// then initializes the SDK. Returns whether ads may be requested.
///
/// Nothing is requested before consent is settled, and a failure anywhere
/// simply means "no ads"; it never affects the rest of the app.
Future<bool> startAds() async {
  if (!adsSupported) return false;
  try {
    // A finance app for adults: keep ad content mild (PG at most).
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.pg,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      ),
    );
    await _refreshConsent();
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    return true;
  } catch (e) {
    debugPrint('Ads unavailable: $e');
    return false;
  }
}

/// Updates consent info and shows the consent form when required.
Future<void> _refreshConsent() async {
  final updated = Completer();
  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () async {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      updated.complete();
    },
    (error) {
      debugPrint('Consent update failed: ${error.message}');
      updated.complete();
    },
  );
  await updated.future;
}

/// True once ads can be requested. Overridden to `false` in tests.
final adsReadyProvider = FutureProvider<bool>((ref) => startAds());

/// Whether the user must be offered a way to change their ad privacy choice
/// (required in the EEA/UK).
final adPrivacyOptionsRequiredProvider = FutureProvider<bool>((ref) async {
  if (!adsSupported) return false;
  try {
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  } catch (_) {
    return false;
  }
});

/// Opens Google's privacy options form.
Future<void> showAdPrivacyOptions() async {
  try {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Privacy form failed: ${error.message}');
    });
  } catch (e) {
    debugPrint('Privacy form failed: $e');
  }
}
