import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/categories/domain/category.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';
import 'package:kept/features/transactions/domain/transaction.dart';

/// Borrow/lend records. When money moved through a tracked account, a linked
/// transaction (deterministic id) is written in the same batch, so the
/// account balance reflects it.
class DebtRepository {
  DebtRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       store = EntityStore(
         userDoc: userDoc,
         collection: Collections.borrowLend,
         fromMap: DebtRecord.fromMap,
         writer: writer,
       );

  final EntityStore<DebtRecord> store;
  final TransactionRepository _transactions;

  String newId() => store.newId();

  Stream<List<DebtRecord>> watchAll() => store.watchAll().map(
    (list) => list..sort((a, b) => b.date.compareTo(a.date)),
  );

  static String initialTransactionId(String recordId) => 'debt_$recordId';

  static String settlementTransactionId(String recordId, String settlementId) =>
      'debt_${recordId}_s$settlementId';

  Future<void> save(DebtRecord record) async {
    final txId = initialTransactionId(record.id);
    final previous = await _transactions.fetch(txId);
    final now = DateTime.now();
    final batch = _transactions.batch();
    if (record.accountId != null) {
      _transactions.stage(
        batch,
        Transaction(
          id: txId,
          date: record.date,
          amountMinor: record.amountMinor,
          type: record.direction == DebtDirection.borrowed
              ? TransactionType.borrowed
              : TransactionType.lent,
          categoryId: Categories.debtId,
          description: record.description,
          counterparty: record.personName,
          accountId: record.accountId,
          borrowLendId: record.id,
          createdAt: previous?.createdAt ?? now,
          updatedAt: now,
        ),
        before: previous,
      );
    } else if (previous != null) {
      _transactions.stageDelete(batch, previous);
    }
    batch.set(
      store.ref.doc(record.id),
      record
          .copyWith(transactionId: () => record.accountId == null ? null : txId)
          .toMap(),
    );
    _transactions.commit(batch);
  }

  void addSettlement(DebtRecord record, Settlement settlement) {
    final batch = _transactions.batch();
    String? txId;
    if (settlement.accountId != null) {
      txId = settlementTransactionId(record.id, settlement.id);
      final now = DateTime.now();
      _transactions.stage(
        batch,
        Transaction(
          id: txId,
          date: settlement.date,
          amountMinor: settlement.amountMinor,
          type: record.direction == DebtDirection.borrowed
              ? TransactionType.debtRepayment
              : TransactionType.debtCollection,
          categoryId: Categories.debtId,
          description: record.description,
          notes: settlement.note,
          counterparty: record.personName,
          accountId: settlement.accountId,
          borrowLendId: record.id,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    final stored = Settlement(
      id: settlement.id,
      amountMinor: settlement.amountMinor,
      date: settlement.date,
      note: settlement.note,
      accountId: settlement.accountId,
      transactionId: txId,
    );
    batch.set(
      store.ref.doc(record.id),
      record
          .copyWith(
            settlements: [...record.settlements, stored],
            updatedAt: DateTime.now(),
          )
          .toMap(),
    );
    _transactions.commit(batch);
  }

  Future<void> removeSettlement(
    DebtRecord record,
    Settlement settlement,
  ) async {
    final batch = _transactions.batch();
    if (settlement.transactionId != null) {
      final tx = await _transactions.fetch(settlement.transactionId!);
      if (tx != null) _transactions.stageDelete(batch, tx);
    }
    batch.set(
      store.ref.doc(record.id),
      record
          .copyWith(
            settlements: record.settlements
                .where((s) => s.id != settlement.id)
                .toList(),
            updatedAt: DateTime.now(),
          )
          .toMap(),
    );
    _transactions.commit(batch);
  }

  Future<void> delete(DebtRecord record) async {
    final batch = _transactions.batch();
    final linked = [
      initialTransactionId(record.id),
      ...record.settlements.map((s) => s.transactionId).whereType<String>(),
    ];
    for (final id in linked) {
      final tx = await _transactions.fetch(id);
      if (tx != null) _transactions.stageDelete(batch, tx);
    }
    batch.delete(store.ref.doc(record.id));
    _transactions.commit(batch);
  }
}
