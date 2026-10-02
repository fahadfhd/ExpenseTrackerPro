import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:expensetrackerpro/core/firebase/collections.dart';
import 'package:expensetrackerpro/core/firebase/entity_store.dart';
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/recurring/domain/recurring_rule.dart';
import 'package:expensetrackerpro/features/transactions/data/transaction_repository.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:flutter/foundation.dart';

class RecurringRepository {
  RecurringRepository({
    required DocumentReference<Map<String, dynamic>> userDoc,
    required WriteDispatcher writer,
    required TransactionRepository transactions,
  }) : _transactions = transactions,
       store = EntityStore(
         userDoc: userDoc,
         collection: Collections.recurringTransactions,
         fromMap: RecurringRule.fromMap,
         writer: writer,
       );

  final EntityStore<RecurringRule> store;
  final TransactionRepository _transactions;

  String newId() => store.newId();

  Stream<List<RecurringRule>> watchAll() => store.watchAll().map(
    (list) => list..sort((a, b) => a.title.compareTo(b.title)),
  );

  void save(RecurringRule rule) => store.set(rule.id, rule.toMap());

  /// Deletes the rule. Transactions it already generated stay: they are real
  /// history.
  void delete(String id) => store.delete(id);

  /// Creates transactions for every occurrence due up to [now] and advances
  /// each rule's `lastGeneratedDate` in the same batch.
  ///
  /// Duplicate-safe: transaction ids are deterministic per rule and day, and
  /// occurrences whose transaction already exists (e.g. generated on another
  /// device) are skipped so balances are not incremented twice.
  Future<int> generateDue(DateTime now) async {
    final rules = await store.fetchAll();
    var created = 0;
    for (final rule in rules) {
      final due = rule.dueOccurrences(now);
      if (due.isEmpty) continue;
      // A rule pointing at a deleted account or card would have its whole
      // batch rejected by the server on every launch; skip it instead.
      if (!await _referencesExist(rule)) {
        debugPrint('Recurring rule ${rule.id} skipped: account/card missing');
        continue;
      }
      final batch = _transactions.batch();
      var staged = 0;
      for (final occurrence in due) {
        final tx = rule.transactionFor(occurrence, now);
        if (await _transactions.fetch(tx.id) != null) continue;
        try {
          _transactions.stage(batch, tx);
          staged++;
        } on TransactionValidationException catch (e) {
          // A rule whose account/card was removed cannot produce valid
          // transactions; skip it rather than block the others.
          debugPrint('Recurring rule ${rule.id} invalid: ${e.issues}');
        }
      }
      batch.update(store.ref.doc(rule.id), {
        'lastGeneratedDate': Timestamp.fromDate(Dates.dayOf(due.last)),
      });
      _transactions.commit(batch);
      created += staged;
    }
    return created;
  }

  Future<bool> _referencesExist(RecurringRule rule) async {
    final userDoc = store.userDoc;
    final refs = [
      if (rule.type != TransactionType.creditCardExpense && rule.accountId != null)
        userDoc.collection(Collections.accounts).doc(rule.accountId),
      if (rule.type == TransactionType.transfer && rule.toAccountId != null)
        userDoc.collection(Collections.accounts).doc(rule.toAccountId),
      if (rule.type == TransactionType.creditCardExpense && rule.creditCardId != null)
        userDoc.collection(Collections.creditCards).doc(rule.creditCardId),
    ];
    for (final ref in refs) {
      try {
        final doc = await ref.get().timeout(const Duration(seconds: 5));
        if (!doc.exists) return false;
      } catch (_) {
        // Offline and not cached: unknown. Generate anyway; the write is
        // retried and only fails if the document really is gone.
      }
    }
    return true;
  }
}
