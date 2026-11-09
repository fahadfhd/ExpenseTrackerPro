import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/borrow_lend/data/debt_repository.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return DebtRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final debtsProvider = StreamProvider<List<DebtRecord>>(
  (ref) => ref.watch(debtRepositoryProvider).watchAll(),
);

final debtSummaryProvider = Provider<DebtSummary>(
  (ref) => DebtSummary.compute(
    ref.watch(debtsProvider).value ?? const [],
    DateTime.now(),
  ),
);
