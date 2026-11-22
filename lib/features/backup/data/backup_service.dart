import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/firestore_codec.dart';
import 'package:kept/features/backup/domain/backup_codec.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class BackupEntry {
  const BackupEntry({required this.id, required this.createdAt});

  /// Document id under `users/{uid}/backups`.
  final String id;
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
  const RestoreResult({
    required this.restored,
    required this.skipped,
    this.settings = const {},
  });
  final int restored;
  final int skipped;

  /// The app settings saved with the backup (theme, currency, language…).
  /// They live only on the device, so the caller applies them.
  final Map<String, dynamic> settings;
}

/// Point-in-time backups of all user data, complementing Firestore's live
/// sync with restorable snapshots.
///
/// Each backup is a header document `users/{uid}/backups/{id}` plus the
/// encoded JSON split over `chunks/{index}` (a Firestore document holds at
/// most 1 MiB). The header is marked `complete` only after every chunk is
/// written, so an interrupted backup is never offered for restore and is
/// cleaned up later.
class BackupService {
  BackupService({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required TransactionRepository transactions,
    this.chunkChars = 200000,
  }) : _userDoc = userDoc,
       _transactions = transactions;

  final DocumentReference<Map<String, dynamic>> _userDoc;
  final TransactionRepository _transactions;

  /// Characters per chunk. At most 4 UTF-8 bytes per character pair keeps a
  /// chunk well under Firestore's 1 MiB document limit.
  final int chunkChars;

  static const keepBackups = 5;
  static const autoBackupInterval = Duration(days: 7);
  static const _timeout = Duration(seconds: 60);

  /// Incomplete backups younger than this may still be uploading from
  /// another device, so pruning leaves them alone.
  static const _staleAfter = Duration(hours: 1);

  CollectionReference<Map<String, dynamic>> get _backups =>
      _userDoc.collection(Collections.backups);

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

  /// Splits [text] into pieces of at most [size] characters without cutting
  /// a surrogate pair (half an emoji would not be valid UTF-8).
  static List<String> split(String text, int size) {
    final parts = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = start + size;
      if (end >= text.length) {
        end = text.length;
      } else if (_isHighSurrogate(text.codeUnitAt(end - 1))) {
        // Keep the pair together: before it, or with it when it alone
        // fills the chunk.
        end = end - 1 > start ? end - 1 : end + 1;
      }
      parts.add(text.substring(start, end));
      start = end;
    }
    return parts.isEmpty ? [''] : parts;
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  Future<int> backupNow({Map<String, dynamic> settings = const {}}) async {
    final collections = <String, Map<String, Map<String, dynamic>>>{};
    for (final name in Collections.backedUp) {
      final snapshot = await _userDoc
          .collection(name)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout, onTimeout: _networkFailure);
      collections[name] = {for (final d in snapshot.docs) d.id: d.data()};
    }
    final now = DateTime.now();
    final json = BackupCodec.encode(
      createdAt: now,
      collections: collections,
      settings: settings,
    );
    final count = collections.values.fold<int>(0, (s, c) => s + c.length);
    final chunks = split(json, chunkChars);
    final header = _backups.doc('backup-${now.millisecondsSinceEpoch}');

    await header
        .set({
          'createdAt': Timestamp.fromDate(now),
          'complete': false,
          'chunkCount': chunks.length,
          'documentCount': count,
          'schemaVersion': BackupCodec.schemaVersion,
        })
        .timeout(_timeout, onTimeout: _networkFailure);
    for (var i = 0; i < chunks.length; i++) {
      await header
          .collection(_chunks)
          .doc('$i')
          .set({'data': chunks[i]})
          .timeout(_timeout, onTimeout: _networkFailure);
    }
    await header
        .update({'complete': true})
        .timeout(_timeout, onTimeout: _networkFailure);

    await _statusDoc.set({
      'lastBackupAt': Timestamp.fromDate(now),
      'lastBackupId': header.id,
      'documentCount': count,
      'schemaVersion': BackupCodec.schemaVersion,
    }, SetOptions(merge: true));
    // The backup is safe at this point; failing to remove old ones must not
    // report it as failed. The next backup retries the cleanup.
    try {
      await _prune();
    } catch (e) {
      debugPrint('Pruning old backups failed: $e');
    }
    return count;
  }

  static const _chunks = 'chunks';

  static Never _networkFailure() => throw const AppFailure(FailureKind.network);

  /// Complete backups, newest first.
  Future<List<BackupEntry>> listBackups() async {
    final snapshot = await _backups.get().timeout(
      _timeout,
      onTimeout: _networkFailure,
    );
    final entries = [
      for (final d in snapshot.docs)
        if (d.data()['complete'] == true)
          if (Codec.date(d.data()['createdAt']) case final createdAt?)
            BackupEntry(id: d.id, createdAt: createdAt),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Keeps the newest [keepBackups] complete backups and removes the rest,
  /// plus interrupted ones that are clearly abandoned.
  Future<void> _prune() async {
    final snapshot = await _backups.get();
    final complete = <({String id, DateTime at})>[];
    final doomed = <String>[];
    final now = DateTime.now();
    for (final d in snapshot.docs) {
      final at = Codec.date(d.data()['createdAt']) ?? DateTime(0);
      if (d.data()['complete'] == true) {
        complete.add((id: d.id, at: at));
      } else if (now.difference(at) > _staleAfter) {
        doomed.add(d.id);
      }
    }
    complete.sort((a, b) => b.at.compareTo(a.at));
    doomed.addAll(complete.skip(keepBackups).map((e) => e.id));
    for (final id in doomed) {
      await _delete(id);
    }
  }

  Future<void> _delete(String id) async {
    final header = _backups.doc(id);
    final chunks = await header.collection(_chunks).get();
    final batch = _userDoc.firestore.batch();
    for (final c in chunks.docs) {
      batch.delete(c.reference);
    }
    batch.delete(header);
    await batch.commit();
  }

  Future<String> _read(BackupEntry entry) async {
    final header = _backups.doc(entry.id);
    final head = await header.get().timeout(
      _timeout,
      onTimeout: _networkFailure,
    );
    final data = head.data();
    if (data == null || data['complete'] != true) {
      throw const AppFailure(FailureKind.notFound);
    }
    final expected = Codec.integer(data['chunkCount']);
    final snapshot = await header
        .collection(_chunks)
        .get()
        .timeout(_timeout, onTimeout: _networkFailure);
    final parts = <int, String>{
      for (final d in snapshot.docs)
        if (int.tryParse(d.id) case final i?) i: Codec.string(d.data()['data']),
    };
    if (parts.length != expected ||
        List.generate(expected, (i) => i).any((i) => !parts.containsKey(i))) {
      throw const AppFailure(
        FailureKind.invalidData,
        debugDetail: 'missing chunks',
      );
    }
    return [for (var i = 0; i < expected; i++) parts[i]!].join();
  }

  /// Validates and restores [entry]: documents are written under their
  /// original ids (no duplicates), then balances are recomputed from the
  /// restored history. Reminders stream back in and are rescheduled by the
  /// notification sync. The saved app settings are returned for the caller
  /// to apply.
  Future<RestoreResult> restore(BackupEntry entry) async {
    final payload = BackupCodec.decode(await _read(entry));
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
      'lastRestoreId': entry.id,
    }, SetOptions(merge: true));
    return RestoreResult(
      restored: restored,
      skipped: payload.skipped,
      settings: payload.settings,
    );
  }
}
