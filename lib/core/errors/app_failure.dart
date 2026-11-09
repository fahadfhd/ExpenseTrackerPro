import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

enum FailureKind {
  network,
  permissionDenied,
  unauthenticated,

  /// The sign-in method (e.g. guest/anonymous) is disabled for this
  /// Firebase project. Retrying cannot help.
  signInMethodDisabled,
  notFound,
  invalidData,
  unsupportedSchema,
  notificationScheduling,
  unknown,
}

/// A failure that is safe to show to users: it carries a [kind] that the UI
/// maps to a localized message. [debugDetail] is for logs only and must never
/// be rendered.
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.debugDetail});

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is FirebaseException) {
      final kind = switch (error.code) {
        'permission-denied' => FailureKind.permissionDenied,
        'unauthenticated' => FailureKind.unauthenticated,
        'operation-not-allowed' ||
        'admin-restricted-operation' => FailureKind.signInMethodDisabled,
        'not-found' || 'object-not-found' => FailureKind.notFound,
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' ||
        'retry-limit-exceeded' => FailureKind.network,
        _ => FailureKind.unknown,
      };
      return AppFailure(kind, debugDetail: '${error.plugin}/${error.code}');
    }
    if (error is TimeoutException) {
      return AppFailure(
        FailureKind.network,
        debugDetail: error.runtimeType.toString(),
      );
    }
    if (error is FormatException) {
      return AppFailure(FailureKind.invalidData, debugDetail: error.message);
    }
    return AppFailure(
      FailureKind.unknown,
      debugDetail: error.runtimeType.toString(),
    );
  }

  final FailureKind kind;
  final String? debugDetail;

  @override
  String toString() =>
      'AppFailure($kind${debugDetail == null ? '' : ', $debugDetail'})';
}
