import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/features/loans/data/loan_repository.dart';
import 'package:kept/features/loans/domain/amortization.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return LoanRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final loansProvider = StreamProvider<List<Loan>>(
  (ref) => ref.watch(loanRepositoryProvider).watchAll(),
);

final loanEventsProvider = StreamProvider<List<LoanEvent>>(
  (ref) => ref.watch(loanRepositoryProvider).watchAllEvents(),
);

/// One schedule per loan, rebuilt only when loans or their events change.
final loanSchedulesProvider = Provider<AsyncValue<Map<String, LoanSchedule>>>((
  ref,
) {
  final loans = ref.watch(loansProvider);
  final events = ref.watch(loanEventsProvider);
  if (loans.hasError) return AsyncError(loans.error!, loans.stackTrace!);
  if (events.hasError) return AsyncError(events.error!, events.stackTrace!);
  if (!loans.hasValue || !events.hasValue) return const AsyncLoading();
  final byLoan = <String, List<LoanEvent>>{};
  for (final e in events.value!) {
    byLoan.putIfAbsent(e.loanId, () => []).add(e);
  }
  final today = DateTime.now();
  return AsyncData({
    for (final loan in loans.value!)
      loan.id: LoanSchedule.build(
        loan,
        byLoan[loan.id] ?? const [],
        today: today,
      ),
  });
});

class LoansOverview {
  const LoansOverview({
    required this.outstandingMinor,
    required this.monthlyEmiMinor,
    required this.activeCount,
    required this.overdueCount,
  });

  final int outstandingMinor;

  /// EMIs of active loans normalised to a month.
  final int monthlyEmiMinor;
  final int activeCount;
  final int overdueCount;
}

final loansOverviewProvider = Provider<LoansOverview>((ref) {
  final schedules = ref.watch(loanSchedulesProvider).value?.values ?? const [];
  var outstanding = 0, monthly = 0, active = 0, overdue = 0;
  for (final s in schedules) {
    if (s.effectiveStatus != LoanStatus.active) continue;
    active++;
    outstanding += s.outstandingPrincipalMinor;
    monthly += (s.currentEmiMinor / s.loan.frequency.monthsPerPeriod).round();
    overdue += s.overdueCount;
  }
  return LoansOverview(
    outstandingMinor: outstanding,
    monthlyEmiMinor: monthly,
    activeCount: active,
    overdueCount: overdue,
  );
});
