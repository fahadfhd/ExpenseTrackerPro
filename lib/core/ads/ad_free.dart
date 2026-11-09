import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How long one rewarded video keeps ads off.
const adFreeDuration = Duration(hours: 24);

/// Until when ads are switched off, or null when they are on.
///
/// Earned by watching a rewarded video. The expiry lives on this device only
/// (deliberately not in the settings, so it is never backed up or restored
/// onto another phone) and ads return by themselves when it passes.
class AdFreeController extends Notifier<DateTime?> {
  static const _key = 'ads.adFreeUntil';

  Timer? _expiry;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  DateTime get _now => ref.read(clockProvider)();

  @override
  DateTime? build() {
    ref.onDispose(() => _expiry?.cancel());
    final millis = _prefs.getInt(_key);
    if (millis == null) return null;
    final now = _now;
    var until = DateTime.fromMillisecondsSinceEpoch(millis);
    // One reward never gives more than one period. A stored time further
    // ahead than that means the phone's clock was moved (or the value is
    // damaged), so it is not honoured.
    final latest = now.add(adFreeDuration);
    if (until.isAfter(latest)) until = latest;
    if (!until.isAfter(now)) {
      _prefs.remove(_key);
      return null;
    }
    _arm(until);
    return until;
  }

  /// Switches ads off for [adFreeDuration], counted from now.
  Future<void> grant() async {
    final until = _now.add(adFreeDuration);
    state = until;
    _arm(until);
    await _prefs.setInt(_key, until.millisecondsSinceEpoch);
  }

  /// Re-checks the clock. A timer does not run while the app is suspended,
  /// so this is called when the app comes back to the foreground.
  void refresh() {
    final until = state;
    if (until != null && !until.isAfter(_now)) _expire();
  }

  void _arm(DateTime until) {
    _expiry?.cancel();
    _expiry = Timer(until.difference(_now), _expire);
  }

  void _expire() {
    _expiry?.cancel();
    _prefs.remove(_key);
    state = null;
  }
}

final adFreeUntilProvider = NotifierProvider<AdFreeController, DateTime?>(
  AdFreeController.new,
);

/// Whether ads are switched off right now.
final adFreeActiveProvider = Provider<bool>(
  (ref) => ref.watch(adFreeUntilProvider) != null,
);
