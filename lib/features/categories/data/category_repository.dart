import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/budgets/domain/budget.dart';
import 'package:kept/features/categories/domain/custom_category.dart';
import 'package:kept/features/transactions/data/transaction_repository.dart';

class CategoryRepository {
  CategoryRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       store = EntityStore(
         userDoc: userDoc,
         collection: Collections.categories,
         fromMap: CustomCategory.fromMap,
         writer: writer,
       );

  final EntityStore<CustomCategory> store;
  final TransactionRepository _transactions;

  /// A fresh id, generated on the device so it works offline.
  String newId() => '${CustomCategory.idPrefix}${store.newId()}';

  Stream<List<CustomCategory>> watchAll() => store.watchAll().map(
    (list) => list
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );

  void save(CustomCategory category) =>
      store.set(category.id, category.toMap());

  /// Whether anything still refers to [id]: transactions, a budget or a
  /// recurring rule. Such a category can be archived but not deleted,
  /// otherwise those records would lose their name and icon.
  Future<bool> isInUse(String id) async {
    if (await _transactions.hasLinked('categoryId', id)) return true;
    final userDoc = store.userDoc;
    final budget = await userDoc
        .collection(Collections.budgets)
        .doc(Budget.idFor(id))
        .get();
    if (budget.exists) return true;
    final rules = await userDoc
        .collection(Collections.recurringTransactions)
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();
    return rules.docs.isNotEmpty;
  }

  void delete(String id) => store.delete(id);
}
