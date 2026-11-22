import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/backup/data/backup_service.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';

import 'repositories_test.dart' show SyncStatusNotifierForTest;

void main() {
  late FakeFirebaseFirestore db;
  late DocumentReference<Map<String, dynamic>> user;
  late BackupService service;

  BackupService make({int chunkChars = 200000}) => BackupService(
    userDoc: user,
    transactions: TransactionRepository(
      userDoc: user,
      writer: WriteDispatcher(SyncStatusNotifierForTest()),
    ),
    chunkChars: chunkChars,
  );

  Future<void> seed() async {
    final now = Timestamp.fromDate(DateTime(2026, 3, 1, 9));
    await user.collection('accounts').doc('a1').set({
      'name': 'Salary 💰',
      'openingBalanceMinor': 100000,
      'ledgerDeltaMinor': 0,
    });
    await user.collection('categories').doc('custom_a').set({
      'name': 'വളർത്തുമൃഗങ്ങൾ',
      'kind': 'expense',
      'subcategories': [
        {'id': 'custom_a.sub_1', 'name': 'Vet'},
      ],
    });
    for (var i = 0; i < 30; i++) {
      await user.collection('transactions').doc('t$i').set({
        'schemaVersion': 2,
        'type': 'expense',
        'amountMinor': 1000 + i,
        'date': now,
        'accountId': 'a1',
        'categoryId': 'custom_a',
        'note': 'Coffee ☕ #$i',
      });
    }
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    user = db.collection('users').doc('uid-1');
    service = make();
  });

  group('split', () {
    test('joins back to the original and never cuts an emoji', () {
      final text = List.filled(50, 'ab😀c').join();
      for (final size in [1, 2, 3, 7, 1000]) {
        final parts = BackupService.split(text, size);
        expect(parts.join(), text);
        for (final p in parts) {
          expect(p.isNotEmpty, isTrue);
          final last = p.codeUnitAt(p.length - 1);
          expect(last >= 0xD800 && last <= 0xDBFF, isFalse);
        }
      }
      expect(BackupService.split('', 10), ['']);
    });
  });

  test('back up, list and restore round-trip across many chunks', () async {
    await seed();
    service = make(chunkChars: 500);
    final count = await service.backupNow(settings: {'currencyCode': 'AED'});
    expect(count, 32);

    final header = (await user.collection('backups').get()).docs.single;
    expect(header.data()['complete'], isTrue);
    final chunkCount = header.data()['chunkCount'] as int;
    expect(chunkCount, greaterThan(5));
    expect(
      (await header.reference.collection('chunks').get()).docs,
      hasLength(chunkCount),
    );
    final status = await service.watchStatus().first;
    expect(status.documentCount, 32);

    // Lose data, then restore it.
    await user.collection('transactions').doc('t3').delete();
    await user.collection('categories').doc('custom_a').delete();
    final entries = await service.listBackups();
    expect(entries, hasLength(1));
    final result = await service.restore(entries.single);
    expect(result.restored, 32);
    expect(result.skipped, 0);
    expect(result.settings['currencyCode'], 'AED');

    final t3 = await user.collection('transactions').doc('t3').get();
    expect(t3.data()!['note'], 'Coffee ☕ #3');
    expect(t3.data()!['date'], isA<Timestamp>());
    final cat = await user.collection('categories').doc('custom_a').get();
    expect(cat.data()!['name'], 'വളർത്തുമൃഗങ്ങൾ');
    expect((cat.data()!['subcategories'] as List).single['name'], 'Vet');
    final account = await user.collection('accounts').doc('a1').get();
    expect(account.data()!['name'], 'Salary 💰');
  });

  test('incomplete backups are not offered and missing chunks fail', () async {
    await seed();
    await user.collection('backups').doc('backup-1').set({
      'createdAt': Timestamp.now(),
      'complete': false,
      'chunkCount': 1,
    });
    expect(await service.listBackups(), isEmpty);

    await service.backupNow();
    final entry = (await service.listBackups()).single;
    final chunks = await user
        .collection('backups')
        .doc(entry.id)
        .collection('chunks')
        .get();
    await chunks.docs.first.reference.delete();
    await expectLater(
      service.restore(entry),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.invalidData,
        ),
      ),
    );
  });

  test('keeps the newest five and removes abandoned uploads', () async {
    final old = DateTime.now().subtract(const Duration(days: 30));
    for (var i = 0; i < 6; i++) {
      final ref = user.collection('backups').doc('backup-old$i');
      await ref.set({
        'createdAt': Timestamp.fromDate(old.add(Duration(days: i))),
        'complete': true,
        'chunkCount': 1,
      });
      await ref.collection('chunks').doc('0').set({'data': '{}'});
    }
    await user.collection('backups').doc('backup-stuck').set({
      'createdAt': Timestamp.fromDate(old),
      'complete': false,
      'chunkCount': 1,
    });
    await user.collection('backups').doc('backup-uploading').set({
      'createdAt': Timestamp.now(),
      'complete': false,
      'chunkCount': 1,
    });

    await service.backupNow();

    final ids = (await user.collection('backups').get()).docs
        .map((d) => d.id)
        .toSet();
    expect(ids, hasLength(6));
    expect(
      ids,
      containsAll(['backup-old2', 'backup-old5', 'backup-uploading']),
    );
    expect(ids, isNot(contains('backup-old0')));
    expect(ids, isNot(contains('backup-stuck')));
    final orphan = await user
        .collection('backups')
        .doc('backup-old0')
        .collection('chunks')
        .get();
    expect(orphan.docs, isEmpty);
    expect(await service.listBackups(), hasLength(5));
  });
}
