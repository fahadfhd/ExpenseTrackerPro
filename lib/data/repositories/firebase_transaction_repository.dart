import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackerpro/data/repositories/mock_transaction_repository.dart';
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
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final collection = _transactionsCollection(user.uid);
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final transaction in MockTransactionRepository.demoTransactions) {
      final doc = collection.doc(transaction.id);
      batch.set(doc, transaction.toMap());
    }
    await batch.commit();
  }

  @override
  Stream<List<TransactionItem>> watchTransactions() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return Stream.value(MockTransactionRepository.demoTransactions);
    }

    return _transactionsCollection(user.uid)
        .orderBy('occurredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  CollectionReference<Map<String, dynamic>> _transactionsCollection(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).collection('transactions');
  }
}
