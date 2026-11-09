import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/features/backup/domain/backup_codec.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BackupEntry {
  const BackupEntry({required this.path, required this.createdAt});
  final String path;
  final DateTime createdAt;
}

class BackupStatus {
  const BackupStatus({
    this.lastBackupAt,
    this.lastRestoreAt,
    this.documentCount,
  });
  final DateTime? lastBackupAt;
  final DateTime? lastRestoreAt;
  final int? documentCount;
}

class RestoreResult {
  const RestoreResult({required this.restored, required this.skipped});
  final int restored;
  final int skipped;
}

/// Point-in-time backups of all user data to Firebase Storage
/// (`users/{uid}/backups/backup-<millis>.json`), complementing Firestore's
/// live sync with restorable snapshots.
class BackupService {
  BackupService({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required FirebaseStorage storage,
    required TransactionRepository transactions,
  }) : _userDoc = userDoc,
       _storage = storage,
       _transactions = transactions;

  final DocumentReference<Map<String, dynamic>> _userDoc;
  final FirebaseStorage _storage;
  final TransactionRepository _transactions;

  static const keepBackups = 5;
  static const autoBackupInterval = Duration(days: 7);
  static const _maxBytes = 50 * 1024 * 1024;
  static const _timeout = Duration(seconds: 60);

  Reference get _folder => _storage.ref('users/${_userDoc.id}/backups');

  DocumentReference<Map<String, dynamic>> get _statusDoc =>
      _userDoc.collection(Collections.settings).doc('backup');

  Stream<BackupStatus> watchStatus() => _statusDoc.snapshots().map((s) {
    final data = s.data() ?? const {};
    return BackupStatus(
      lastBackupAt: Codec.date(data['lastBackupAt']),
      lastRestoreAt: Codec.date(data['lastRestoreAt']),
      documentCount: Codec.intOrNull(data['documentCount']),
    );
  });

  Future<int> backupNow({Map<String, dynamic> settings = const {}}) async {
    final collections = <String, Map<String, Map<String, dynamic>>>{};
    for (final name in Collections.backedUp) {
      final snapshot = await _userDoc
          .collection(name)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      collections[name] = {for (final d in snapshot.docs) d.id: d.data()};
    }
    final now = DateTime.now();
    final json = BackupCodec.encode(
      createdAt: now,
      collections: collections,
      settings: settings,
    );
    final ref = _folder.child('backup-${now.millisecondsSinceEpoch}.json');
    await ref
        .putData(
          Uint8List.fromList(utf8.encode(json)),
          SettableMetadata(contentType: 'application/json'),
        )
        .timeout(_timeout);
    final count = collections.values.fold<int>(0, (s, c) => s + c.length);
    await _statusDoc.set({
      'lastBackupAt': Timestamp.fromDate(now),
      'lastBackupPath': ref.fullPath,
      'documentCount': count,
      'schemaVersion': BackupCodec.schemaVersion,
    }, SetOptions(merge: true));
    await _prune();
    return count;
  }

  Future<List<BackupEntry>> listBackups() async {
    final result = await _folder.listAll().timeout(_timeout);
    final entries = <BackupEntry>[];
    for (final item in result.items) {
      final match = RegExp(r'backup-(\d+)\.json$').firstMatch(item.name);
      if (match == null) continue;
      entries.add(
        BackupEntry(
          path: item.fullPath,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            int.parse(match.group(1)!),
          ),
        ),
      );
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> _prune() async {
    final entries = await listBackups();
    for (final old in entries.skip(keepBackups)) {
      await _storage.ref(old.path).delete();
    }
  }

  /// Validates and restores [entry]: documents are written under their
  /// original ids (no duplicates), then balances are recomputed from the
  /// restored history. Reminders stream back in and are rescheduled by the
  /// notification sync.
  Future<RestoreResult> restore(BackupEntry entry) async {
    final bytes = await _storage
        .ref(entry.path)
        .getData(_maxBytes)
        .timeout(_timeout);
    if (bytes == null) throw const AppFailure(FailureKind.notFound);
    final payload = BackupCodec.decode(utf8.decode(bytes));

    var batch = _userDoc.firestore.batch();
    var pending = 0;
    var restored = 0;
    for (final name in Collections.backedUp) {
      final docs = payload.collections[name];
      if (docs == null) continue;
      for (final doc in docs.entries) {
        batch.set(_userDoc.collection(name).doc(doc.key), doc.value);
        restored++;
        if (++pending == 400) {
          await batch.commit().timeout(_timeout);
          batch = _userDoc.firestore.batch();
          pending = 0;
        }
      }
    }
    if (pending > 0) await batch.commit().timeout(_timeout);

    // Restored balances may not match records kept from after the backup.
    await _transactions.recalculateBalances();
    // Older backups may contain schema-1 transactions.
    await _transactions.migrateLegacyDocuments();

    await _statusDoc.set({
      'lastRestoreAt': Timestamp.fromDate(DateTime.now()),
      'lastRestorePath': entry.path,
    }, SetOptions(merge: true));
    return RestoreResult(restored: restored, skipped: payload.skipped);
  }
}
