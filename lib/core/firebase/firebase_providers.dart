import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kept/core/errors/app_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// The signed-in user. Uses `userChanges()` rather than `authStateChanges()`
/// because only the former fires when a guest account is linked to Google
/// (same uid, but `isAnonymous` and `email` change).
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).userChanges(),
);

/// The signed-in user's id. Every user-scoped provider depends on this, so
/// switching accounts tears down and rebuilds all data streams.
final uidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// `users/{uid}`. All financial data lives below this document and Firestore
/// rules restrict it to its owner.
final userDocProvider = Provider<DocumentReference<Map<String, dynamic>>?>((
  ref,
) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return null;
  return ref.watch(firestoreProvider).collection('users').doc(uid);
});

@immutable
class SyncStatus {
  const SyncStatus({this.pending = 0, this.lastSyncedAt, this.lastFailure});

  /// Writes applied locally but not yet acknowledged by the server.
  final int pending;
  final DateTime? lastSyncedAt;

  /// Most recent write the server rejected; shown once by the shell.
  final AppFailure? lastFailure;

  bool get isSynced => pending == 0;

  SyncStatus copyWith({
    int? pending,
    DateTime? lastSyncedAt,
    AppFailure? Function()? lastFailure,
  }) => SyncStatus(
    pending: pending ?? this.pending,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    lastFailure: lastFailure != null ? lastFailure() : this.lastFailure,
  );
}

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  void started() => state = state.copyWith(pending: state.pending + 1);

  void succeeded() => state = state.copyWith(
    pending: state.pending > 0 ? state.pending - 1 : 0,
    lastSyncedAt: DateTime.now(),
  );

  void failed(AppFailure failure) => state = state.copyWith(
    pending: state.pending > 0 ? state.pending - 1 : 0,
    lastFailure: () => failure,
  );

  void clearFailure() => state = state.copyWith(lastFailure: () => null);
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

/// Sends a write to Firestore without waiting for the server.
///
/// Firestore applies the write to its local cache immediately (listeners fire
/// at once, also offline) and the returned future only completes when the
/// server acknowledges. Awaiting it would block the UI whenever the device is
/// offline, so the future is tracked here instead: it drives [SyncStatus]
/// and surfaces server-side rejections.
class WriteDispatcher {
  WriteDispatcher(this._status);

  final SyncStatusNotifier _status;

  void dispatch(Future<void> write) {
    _status.started();
    write.then(
      (_) => _status.succeeded(),
      onError: (Object error) {
        final failure = AppFailure.from(error);
        debugPrint('Background write failed: $failure');
        _status.failed(failure);
      },
    );
  }
}

final writeDispatcherProvider = Provider<WriteDispatcher>(
  (ref) => WriteDispatcher(ref.read(syncStatusProvider.notifier)),
);
