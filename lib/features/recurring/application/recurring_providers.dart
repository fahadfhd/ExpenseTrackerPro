import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/recurring/data/recurring_repository.dart';
import 'package:kept/features/recurring/domain/recurring_rule.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return RecurringRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final recurringRulesProvider = StreamProvider<List<RecurringRule>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchAll(),
);
