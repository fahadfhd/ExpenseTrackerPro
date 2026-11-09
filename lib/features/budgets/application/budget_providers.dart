import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/budgets/data/budget_repository.dart';
import 'package:kept/features/budgets/domain/budget.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return BudgetRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
  );
});

final budgetsProvider = StreamProvider<List<Budget>>(
  (ref) => ref.watch(budgetRepositoryProvider).watchAll(),
);

/// Budget usage for [month], from the same monthly summary the dashboard
/// uses so the numbers always agree.
final budgetUsageProvider = Provider.autoDispose
    .family<AsyncValue<List<BudgetUsage>>, DateTime>((ref, month) {
      final budgets = ref.watch(budgetsProvider);
      final summary = ref.watch(monthlySummaryProvider(month));
      if (budgets.hasError) {
        return AsyncError(budgets.error!, budgets.stackTrace!);
      }
      if (!budgets.hasValue) return const AsyncLoading();
      return summary.whenData((s) => BudgetCalculator.usage(budgets.value!, s));
    });
