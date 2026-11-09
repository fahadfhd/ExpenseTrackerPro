import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/features/backup/domain/backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 3, 15, 10, 30);
  final txDate = Timestamp.fromDate(DateTime(2026, 3, 1, 9));

  Map<String, Map<String, Map<String, dynamic>>> sample() => {
    'accounts': {
      'a1': {
        'name': 'Salary',
        'openingBalanceMinor': 1000,
        'ledgerDeltaMinor': -50,
      },
    },
    'transactions': {
      't1': {
        'schemaVersion': 2,
        'type': 'expense',
        'amountMinor': 50,
        'date': txDate,
        'accountId': 'a1',
        'tags': ['x'],
        'nested': {'when': txDate},
      },
    },
    'reminders': {
      'r1': {
        'title': 'Gym',
        'scheduledDate': '2026-03-20',
        'offsetsMinutes': [0, 60],
      },
    },
  };

  test('round-trips documents, ids and timestamps', () {
    final json = BackupCodec.encode(
      createdAt: createdAt,
      collections: sample(),
      settings: {'currencyCode': 'INR'},
    );
    final payload = BackupCodec.decode(json);
    expect(payload.createdAt, createdAt);
    expect(payload.skipped, 0);
    expect(payload.documentCount, 3);
    expect(payload.settings['currencyCode'], 'INR');
    final t1 = payload.collections['transactions']!['t1']!;
    expect(t1['date'], txDate);
    expect((t1['nested'] as Map)['when'], txDate);
    expect(t1['tags'], ['x']);
    expect(payload.collections['accounts']!['a1']!['ledgerDeltaMinor'], -50);
  });

  test('rejects files that are not backups', () {
    expect(
      () => BackupCodec.decode('not json'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.invalidData,
        ),
      ),
    );
    expect(
      () => BackupCodec.decode(jsonEncode({'format': 'other'})),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.invalidData,
        ),
      ),
    );
  });

  test('rejects backups from a newer schema version', () {
    final json = jsonEncode({
      'format': BackupCodec.format,
      'schemaVersion': BackupCodec.schemaVersion + 1,
      'createdAt': createdAt.toIso8601String(),
      'collections': {},
    });
    expect(
      () => BackupCodec.decode(json),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.unsupportedSchema,
        ),
      ),
    );
  });

  test('skips invalid documents and forbidden credential fields', () {
    final data = sample();
    data['transactions']!['bad-amount'] = {
      'type': 'expense',
      'amountMinor': -5,
      'date': txDate,
    };
    data['transactions']!['bad-type'] = {
      'type': 'hack',
      'amountMinor': 5,
      'date': txDate,
    };
    data['credit_cards'] = {
      'c1': {'name': 'Card', 'cvv': '123'},
      'c2': {'name': 'Card 2', 'last4': '4242'},
    };
    data['accounts']!['bad id/with slash'] = {'name': 'x'};
    final payload = BackupCodec.decode(
      BackupCodec.encode(createdAt: createdAt, collections: data),
    );
    expect(payload.skipped, 4);
    expect(payload.collections['credit_cards']!.keys, ['c2']);
    expect(payload.collections['transactions']!.keys, ['t1']);
  });

  test('unknown collections are ignored', () {
    final json = jsonEncode({
      'format': BackupCodec.format,
      'schemaVersion': 1,
      'createdAt': createdAt.toIso8601String(),
      'collections': {
        'unknown': {
          'x': {'a': 1},
        },
      },
    });
    expect(BackupCodec.decode(json).collections, isEmpty);
  });
}
