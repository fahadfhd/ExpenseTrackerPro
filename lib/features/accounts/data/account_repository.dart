import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/accounts/domain/account.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';

class AccountRepository {
  AccountRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       store = EntityStore(
         userDoc: userDoc,
         collection: Collections.accounts,
         fromMap: Account.fromMap,
         writer: writer,
       );

  final EntityStore<Account> store;
  final TransactionRepository _transactions;

  String newId() => store.newId();

  Stream<List<Account>> watchAll() => store.watchAll().map(
    (list) => list
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );

  /// Merges editable fields only; the ledger delta is owned by
  /// [TransactionRepository] and is never overwritten here.
  void save(Account account) =>
      store.set(account.id, account.toEditableMap(), merge: true);

  /// Accounts referenced anywhere cannot be deleted: later writes that
  /// adjust their balance (an EMI paid from it, a recurring entry, a
  /// settlement) would be rejected by the server and silently rolled back.
  /// They can be archived instead.
  Future<bool> isInUse(String id) async {
    if (await _transactions.hasLinked('accountId', id) ||
        await _transactions.hasLinked('toAccountId', id)) {
      return true;
    }
    final userDoc = store.userDoc;
    for (final (collection, field) in const [
      (Collections.loans, 'accountId'),
      (Collections.borrowLend, 'accountId'),
      (Collections.recurringTransactions, 'accountId'),
      (Collections.recurringTransactions, 'toAccountId'),
      (Collections.creditCards, 'linkedAccountId'),
    ]) {
      final snapshot = await userDoc
          .collection(collection)
          .where(field, isEqualTo: id)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return true;
    }
    return false;
  }

  void delete(String id) => store.delete(id);
}
