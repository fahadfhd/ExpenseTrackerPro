import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kept/core/firebase/collections.dart';
import 'package:kept/core/firebase/entity_store.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/budgets/domain/budget.dart';

class BudgetRepository {
  BudgetRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
  }) : store = EntityStore(
         userDoc: userDoc,
         collection: Collections.budgets,
         fromMap: Budget.fromMap,
         writer: writer,
       );

  final EntityStore<Budget> store;

  Stream<List<Budget>> watchAll() => store.watchAll();

  /// Budget ids derive from the category, so saving a second budget for the
  /// same category replaces the first.
  void save(Budget budget) {
    assert(budget.id == Budget.idFor(budget.categoryId));
    store.set(budget.id, budget.toMap());
  }

  void delete(String id) => store.delete(id);
}
