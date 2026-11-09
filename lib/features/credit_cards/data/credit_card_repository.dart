import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';

class CreditCardRepository {
  CreditCardRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       store = EntityStore(
         userDoc: userDoc,
         collection: Collections.creditCards,
         fromMap: CreditCard.fromMap,
         writer: writer,
       );

  final EntityStore<CreditCard> store;
  final TransactionRepository _transactions;

  String newId() => store.newId();

  Stream<List<CreditCard>> watchAll() => store.watchAll().map(
    (list) => list
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );

  void save(CreditCard card) {
    if (card.last4.isNotEmpty &&
        !CreditCard.last4Pattern.hasMatch(card.last4)) {
      throw ArgumentError.value(card.last4, 'last4');
    }
    store.set(card.id, card.toEditableMap(), merge: true);
  }

  /// Cards referenced by transactions or recurring rules cannot be deleted
  /// (their outstanding updates would be rejected); archive them instead.
  Future<bool> isInUse(String id) async {
    if (await _transactions.hasLinked('creditCardId', id)) return true;
    final rules = await store.userDoc
        .collection(Collections.recurringTransactions)
        .where('creditCardId', isEqualTo: id)
        .limit(1)
        .get();
    return rules.docs.isNotEmpty;
  }

  void delete(String id) => store.delete(id);
}
