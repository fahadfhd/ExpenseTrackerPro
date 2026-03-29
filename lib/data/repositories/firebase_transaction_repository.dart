import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackerpro/core/transactions/transaction_deduplicator.dart';
import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseTransactionRepository implements TransactionRepository {
  FirebaseTransactionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<void> seedInitialTransactions() async {
    // Real signed-in users should start from backend data, not seeded demo rows.
  }

  @override
  Stream<List<TransactionItem>> watchTransactions() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _transactionsCollection(user.uid)
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => TransactionDeduplicator.deduplicate(
            snapshot.docs
                .map((doc) => TransactionItem.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  @override
  Future<void> upsertTransactions(List<TransactionItem> transactions) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || transactions.isEmpty) return;

    final collection = _transactionsCollection(user.uid);
    final existingSnapshot = await collection.get();
    final existingTransactions = existingSnapshot.docs
        .map((doc) => TransactionItem.fromMap(doc.id, doc.data()))
        .toList();

    final merged = TransactionDeduplicator.deduplicate([
      ...existingTransactions,
      ...transactions,
    ]);
    final mergedIds = merged.map((item) => item.id).toSet();

    final batch = _firestore.batch();
    for (final transaction in merged) {
      batch.set(collection.doc(transaction.id), transaction.toMap());
    }

    for (final doc in existingSnapshot.docs) {
      if (!mergedIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  @override
  Future<void> clearTransactions() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final collection = _transactionsCollection(user.uid);
    final snapshot = await collection.get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _transactionsCollection(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).collection('transactions');
  }
}
