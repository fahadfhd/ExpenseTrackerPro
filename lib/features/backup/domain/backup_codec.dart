import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/features/transactions/domain/transaction.dart';

/// Decoded backup: `collection -> docId -> data`.
class BackupPayload {
  const BackupPayload({
    required this.createdAt,
    required this.collections,
    required this.skipped,
    this.settings = const {},
  });

  final DateTime createdAt;
  final Map<String, Map<String, Map<String, dynamic>>> collections;
  final Map<String, dynamic> settings;

  /// Documents dropped by validation.
  final int skipped;

  int get documentCount =>
      collections.values.fold(0, (sum, docs) => sum + docs.length);
}

/// Versioned, self-describing JSON backup format.
///
/// * `format` identifies the file; `schemaVersion` the envelope layout.
///   Bump [schemaVersion] when the envelope changes and keep decoding older
///   versions here.
/// * Firestore timestamps are encoded as `{"__ts": millisSinceEpoch}`.
/// * Document ids are preserved, so restoring the same backup twice
///   overwrites instead of duplicating.
abstract final class BackupCodec {
  static const format = 'expensetrackerpro-backup';
  static const schemaVersion = 1;
  static final _idPattern = RegExp(r'^[A-Za-z0-9_\-]{1,160}$');

  static String encode({
    required DateTime createdAt,
    required Map<String, Map<String, Map<String, dynamic>>> collections,
    Map<String, dynamic> settings = const {},
  }) => jsonEncode({
    'format': format,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'dataSchema': {'transactions': Transaction.schemaVersion},
    'settings': _encodeValue(settings),
    'collections': {
      for (final entry in collections.entries)
        entry.key: {
          for (final doc in entry.value.entries)
            doc.key: _encodeValue(doc.value),
        },
    },
  });

  static Object? _encodeValue(Object? value) => switch (value) {
    Timestamp t => {'__ts': t.millisecondsSinceEpoch},
    DateTime d => {'__ts': d.millisecondsSinceEpoch},
    Map m => {for (final e in m.entries) '${e.key}': _encodeValue(e.value)},
    List l => [for (final v in l) _encodeValue(v)],
    _ => value,
  };

  static Object? _decodeValue(Object? value) {
    if (value is Map) {
      if (value.length == 1 && value['__ts'] is int) {
        return Timestamp.fromMillisecondsSinceEpoch(value['__ts'] as int);
      }
      return <String, dynamic>{
        for (final e in value.entries) '${e.key}': _decodeValue(e.value),
      };
    }
    if (value is List) return [for (final v in value) _decodeValue(v)];
    return value;
  }

  /// Parses and validates a backup. Throws [AppFailure] with
  /// [FailureKind.invalidData] for malformed files and
  /// [FailureKind.unsupportedSchema] for files from a newer app version.
  /// Individual invalid documents are skipped and counted.
  static BackupPayload decode(String source) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } on FormatException catch (e) {
      throw AppFailure(FailureKind.invalidData, debugDetail: e.message);
    }
    if (root is! Map || root['format'] != format) {
      throw const AppFailure(FailureKind.invalidData, debugDetail: 'format');
    }
    final version = root['schemaVersion'];
    if (version is! int || version < 1) {
      throw const AppFailure(FailureKind.invalidData, debugDetail: 'version');
    }
    if (version > schemaVersion) {
      throw AppFailure(FailureKind.unsupportedSchema, debugDetail: 'v$version');
    }
    final createdAt = DateTime.tryParse('${root['createdAt']}');
    final rawCollections = root['collections'];
    if (createdAt == null || rawCollections is! Map) {
      throw const AppFailure(FailureKind.invalidData, debugDetail: 'envelope');
    }

    var skipped = 0;
    final collections = <String, Map<String, Map<String, dynamic>>>{};
    for (final name in Collections.backedUp) {
      final docs = rawCollections[name];
      if (docs == null) continue;
      if (docs is! Map) {
        throw AppFailure(FailureKind.invalidData, debugDetail: name);
      }
      final valid = <String, Map<String, dynamic>>{};
      for (final entry in docs.entries) {
        final id = '${entry.key}';
        final data = _decodeValue(entry.value);
        if (!_idPattern.hasMatch(id) ||
            data is! Map<String, dynamic> ||
            !_isValidDocument(name, data)) {
          skipped++;
          continue;
        }
        valid[id] = data;
      }
      collections[name] = valid;
    }
    final settings = _decodeValue(root['settings']);
    return BackupPayload(
      createdAt: createdAt.toLocal(),
      collections: collections,
      settings: settings is Map<String, dynamic> ? settings : const {},
      skipped: skipped,
    );
  }

  static bool _isValidDocument(String collection, Map<String, dynamic> data) {
    bool isInt(String key) => data[key] is int;
    bool isString(String key) => data[key] is String;
    switch (collection) {
      case Collections.transactions:
        if (Transaction.isLegacy(data)) return data['amount'] is num;
        final type = data['type'];
        return isInt('amountMinor') &&
            (data['amountMinor'] as int) > 0 &&
            data['date'] is Timestamp &&
            TransactionType.values.any((t) => t.name == type);
      case Collections.accounts:
      case Collections.creditCards:
        return isString('name') &&
            // Credentials must never round-trip through backups.
            !data.keys.any(_forbiddenField);
      case Collections.loans:
        return isString('name') &&
            isInt('principalMinor') &&
            isInt('installments');
      case Collections.loanPayments:
      case Collections.fuelLogs:
        return isString(
          collection == Collections.fuelLogs ? 'vehicleId' : 'loanId',
        );
      case Collections.borrowLend:
        return isString('personName') && isInt('amountMinor');
      case Collections.categories:
        return isString('name') && data['name'].toString().trim().isNotEmpty;
      case Collections.reminders:
        return isString('title') && isString('scheduledDate');
      default:
        return true;
    }
  }

  static const _forbiddenKeys = {
    'cvv',
    'cvc',
    'pin',
    'otp',
    'password',
    'cardnumber',
    'fullcardnumber',
  };

  static bool _forbiddenField(String key) =>
      _forbiddenKeys.contains(key.toLowerCase());
}
