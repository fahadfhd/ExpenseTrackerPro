import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/transactions/domain/ledger_effects.dart';
import 'package:kept/features/transactions/domain/transaction.dart';
import 'package:kept/features/transactions/domain/transaction_validator.dart';

class TransactionValidationException implements Exception {
  const TransactionValidationException(this.issues);
  final List<TransactionIssue> issues;
}

/// Reads and writes transactions and keeps account/card ledger deltas in
/// step with them. Every write stages the transaction document and the
/// matching `FieldValue.increment`s in one batch, so they commit (or fail)
/// together, offline included.
class TransactionRepository {
  TransactionRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
  }) : _userDoc = userDoc,
       _writer = writer,
       store = EntityStore(
         userDoc: userDoc,
         collection: Collections.transactions,
         fromMap: Transaction.fromMap,
         writer: writer,
       );

  final DocumentReference<Map<String, dynamic>> _userDoc;
  final WriteDispatcher _writer;
  final EntityStore<Transaction> store;

  /// Firestore batches allow 500 operations; each transaction needs up to 3.
  static const _batchTransactions = 150;

  String newId() => store.newId();

  Stream<List<Transaction>> watchRange(DateRange range) => store.watchQuery(
    (c) => c
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThan: Timestamp.fromDate(range.end))
        .orderBy('date', descending: true),
  );

  Future<List<Transaction>> fetchRange(DateRange range) async {
    final snapshot = await store.ref
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThan: Timestamp.fromDate(range.end))
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((d) => Transaction.fromMap(d.id, d.data()))
        .toList();
  }

  /// Latest transactions linked to an entity through [field] (accountId,
  /// creditCardId, loanId…). Needs the composite indexes in
  /// `firestore.indexes.json`.
  Stream<List<Transaction>> watchLinked(
    String field,
    String id, {
    int limit = 50,
  }) => store.watchQuery(
    (c) => c
        .where(field, isEqualTo: id)
        .orderBy('date', descending: true)
        .limit(limit),
  );

  Future<bool> hasLinked(String field, String id) async {
    final snapshot = await store.ref.where(field, isEqualTo: id).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Reads one transaction, preferring the server but falling back to the
  /// local cache when offline. Returns null when it is not known locally.
  Future<Transaction?> fetch(String id) async {
    final ref = store.ref.doc(id);
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await ref.get().timeout(const Duration(seconds: 5));
    } catch (_) {
      try {
        doc = await ref.get(const GetOptions(source: Source.cache));
      } catch (_) {
        return null;
      }
    }
    return doc.exists ? Transaction.fromMap(doc.id, doc.data()!) : null;
  }

  /// Validates and stages [after] (replacing [before] when editing) in
  /// [batch]. Callers that combine a transaction with other writes (loan
  /// payments, settlements, fuel logs) use this and commit themselves.
  void stage(WriteBatch batch, Transaction after, {Transaction? before}) {
    final issues = TransactionValidator.validate(after);
    if (issues.isNotEmpty) throw TransactionValidationException(issues);
    batch.set(store.ref.doc(after.id), after.toMap(userId: _userDoc.id));
    _stageDelta(batch, LedgerEffects.change(before, after));
  }

  void stageDelete(WriteBatch batch, Transaction tx) {
    batch.delete(store.ref.doc(tx.id));
    _stageDelta(batch, LedgerEffects.change(tx, null));
  }

  void _stageDelta(WriteBatch batch, LedgerDelta delta) {
    delta.accounts.forEach((id, value) {
      batch.update(_userDoc.collection(Collections.accounts).doc(id), {
        'ledgerDeltaMinor': FieldValue.increment(value),
      });
    });
    delta.cards.forEach((id, value) {
      batch.update(_userDoc.collection(Collections.creditCards).doc(id), {
        'ledgerDeltaMinor': FieldValue.increment(value),
      });
    });
  }

  WriteBatch batch() => _userDoc.firestore.batch();

  void commit(WriteBatch batch) => _writer.dispatch(batch.commit());

  /// Creates or updates one transaction. Throws
  /// [TransactionValidationException] synchronously for invalid input.
  void save(Transaction after, {Transaction? before}) {
    final b = batch();
    stage(b, after, before: before);
    commit(b);
  }

  void delete(Transaction tx) {
    final b = batch();
    stageDelete(b, tx);
    commit(b);
  }

  /// Writes many new transactions (recurring generation, imports, restore
  /// of single records) in chunks. Ids must be deterministic for idempotency.
  void saveAll(List<Transaction> transactions) {
    for (var i = 0; i < transactions.length; i += _batchTransactions) {
      final b = batch();
      for (final tx in transactions.skip(i).take(_batchTransactions)) {
        stage(b, tx);
      }
      commit(b);
    }
  }

  /// Recomputes every account and card ledger delta from the full history.
  /// Repairs drift (e.g. the same recurring occurrence generated on two
  /// offline devices). Requires a network round trip, so it is awaited.
  Future<void> recalculateBalances() async {
    final snapshot = await store.ref.get();
    final all = snapshot.docs.map((d) => Transaction.fromMap(d.id, d.data()));
    final totals = LedgerEffects.total(all);
    final accounts = await _userDoc.collection(Collections.accounts).get();
    final cards = await _userDoc.collection(Collections.creditCards).get();

    final b = batch();
    for (final doc in accounts.docs) {
      b.update(doc.reference, {
        'ledgerDeltaMinor': totals.accounts[doc.id] ?? 0,
      });
    }
    for (final doc in cards.docs) {
      b.update(doc.reference, {'ledgerDeltaMinor': totals.cards[doc.id] ?? 0});
    }
    await b.commit().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw const AppFailure(FailureKind.network),
    );
  }

  /// Rewrites documents stored by app versions before schema 2. Returns the
  /// number migrated. Safe to run repeatedly.
  Future<int> migrateLegacyDocuments() async {
    final snapshot = await store.ref.get();
    final legacy = snapshot.docs.where((d) => Transaction.isLegacy(d.data()));
    var count = 0;
    var b = batch();
    var pending = 0;
    for (final doc in legacy) {
      final migrated = Transaction.fromMap(doc.id, doc.data());
      b.set(doc.reference, migrated.toMap(userId: _userDoc.id));
      count++;
      if (++pending == 400) {
        commit(b);
        b = batch();
        pending = 0;
      }
    }
    if (pending > 0) commit(b);
    return count;
  }
}
