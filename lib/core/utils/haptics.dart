import 'package:flutter/services.dart';

/// Light haptic feedback for selections and saves. Failures (platforms or
/// test environments without a haptic engine) are ignored.
abstract final class Haptics {
  static void selection() => _run(HapticFeedback.selectionClick);

  static void success() => _run(HapticFeedback.lightImpact);

  static void _run(Future<void> Function() feedback) {
    feedback().catchError((Object _) {});
  }
}
