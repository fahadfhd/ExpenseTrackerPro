import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/clock.dart';
import 'package:kept/features/borrow_lend/application/debt_providers.dart';
import 'package:kept/features/borrow_lend/domain/debt_record.dart';
import 'package:kept/features/credit_cards/application/card_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentReference;
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/utils/dates.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/debt_plan/domain/debt_plan.dart';
import 'package:kept/features/debt_plan/domain/debt_progress.dart';
import 'package:kept/features/debt_plan/domain/financial_profile.dart';
import 'package:kept/features/transactions/application/transaction_providers.dart';
import 'package:kept/features/loans/application/loan_providers.dart';
import 'package:kept/features/loans/domain/loan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class DebtPlanSettings {
  const DebtPlanSettings({
    this.extraMinor = 0,
    this.strategy = PayoffStrategy.avalanche,
    this.reminderEnabled = false,
  });

  final int extraMinor;
  final PayoffStrategy strategy;

  /// Opt-in: a monthly nudge saying what to pay.
  final bool reminderEnabled;

  DebtPlanSettings copyWith({
    int? extraMinor,
    PayoffStrategy? strategy,
    bool? reminderEnabled,
  }) => DebtPlanSettings(
    extraMinor: extraMinor ?? this.extraMinor,
    strategy: strategy ?? this.strategy,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
  );
}

/// The extra amount and strategy are what-if choices, so they stay on the
/// device like other preferences.
class DebtPlanSettingsController extends Notifier<DebtPlanSettings> {
  static const _extraKey = 'debtPlan.extraMinor';
  static const _strategyKey = 'debtPlan.strategy';
  static const _reminderKey = 'debtPlan.reminder';

  @override
  DebtPlanSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final name = prefs.getString(_strategyKey);
    return DebtPlanSettings(
      extraMinor: prefs.getInt(_extraKey) ?? 0,
      strategy: PayoffStrategy.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PayoffStrategy.avalanche,
      ),
      reminderEnabled: prefs.getBool(_reminderKey) ?? false,
    );
  }

  void setExtra(int minor) {
    state = state.copyWith(extraMinor: minor);
    ref.read(sharedPreferencesProvider).setInt(_extraKey, minor);
  }

  void setStrategy(PayoffStrategy strategy) {
    state = state.copyWith(strategy: strategy);
    ref.read(sharedPreferencesProvider).setString(_strategyKey, strategy.name);
  }

  void setReminder(bool enabled) {
    state = state.copyWith(reminderEnabled: enabled);
    ref.read(sharedPreferencesProvider).setBool(_reminderKey, enabled);
  }
}

final debtPlanSettingsProvider =
    NotifierProvider<DebtPlanSettingsController, DebtPlanSettings>(
      DebtPlanSettingsController.new,
    );

/// Everything currently owed: active loans, card balances and money borrowed
/// from people. Money others owe the user is not debt, so it is left out.
final payoffDebtsProvider = Provider<AsyncValue<List<PayoffDebt>>>((ref) {
  final schedules = ref.watch(loanSchedulesProvider);
  final cards = ref.watch(cardsProvider);
  final records = ref.watch(debtsProvider);
  for (final source in <AsyncValue<Object?>>[schedules, cards, records]) {
    if (source.hasError) return AsyncError(source.error!, source.stackTrace!);
  }
  if (!schedules.hasValue || !cards.hasValue || !records.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData([
    for (final s in schedules.value!.values)
      if (s.effectiveStatus == LoanStatus.active &&
          s.outstandingPrincipalMinor > 0)
        PayoffDebt.fromLoan(s),
    for (final c in cards.value!)
      if (!c.archived && c.outstandingMinor > 0) PayoffDebt.fromCard(c),
    for (final r in records.value!)
      if (r.direction == DebtDirection.borrowed && !r.isSettled)
        PayoffDebt.fromBorrowed(r),
  ]);
});

/// Null when nothing is owed.
final debtPlanProvider = Provider<AsyncValue<DebtPlan?>>((ref) {
  final settings = ref.watch(debtPlanSettingsProvider);
  final start = ref.watch(clockProvider)();
  return ref
      .watch(payoffDebtsProvider)
      .whenData(
        (debts) => debts.isEmpty
            ? null
            : DebtPlan.build(
                debts,
                strategy: settings.strategy,
                extraMinor: settings.extraMinor,
                start: start,
              ),
      );
});

/// The debt history lives in one document under `settings`, a collection the
/// security rules already allow, and is small enough to rewrite whole.
class DebtProgressStore {
  DebtProgressStore(this._doc, this._writer);

  final DocumentReference<Map<String, dynamic>> _doc;
  final WriteDispatcher _writer;

  Stream<DebtProgress> watch() =>
      _doc.snapshots().map((s) => DebtProgress.fromMap(s.data()));

  void save(DebtProgress progress) =>
      _writer.dispatch(_doc.set(progress.toMap()));
}

final debtProgressStoreProvider = Provider<DebtProgressStore?>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) return null;
  return DebtProgressStore(
    userDoc.collection('settings').doc('debt_progress'),
    ref.watch(writeDispatcherProvider),
  );
});

final debtProgressProvider = StreamProvider<DebtProgress>((ref) {
  final store = ref.watch(debtProgressStoreProvider);
  return store == null ? const Stream.empty() : store.watch();
});

/// Averages of the last three complete months plus this month so far; null
/// until the transactions have loaded.
final financialProfileProvider = Provider.autoDispose<FinancialProfile?>((ref) {
  final month = Dates.monthOf(ref.watch(clockProvider)());
  final range = DateRange.lastMonths(month, 4);
  final transactions = ref.watch(transactionsInRangeProvider(range)).value;
  if (transactions == null) return null;
  final points = monthPoints(range, transactions);
  return FinancialProfile.compute(
    completeMonths: points.take(3).map((p) => p.summary),
    thisMonth: points.last.summary,
    liquidMinor: ref
        .watch(activeAccountsProvider)
        .where((a) => a.balanceMinor > 0)
        .fold(0, (sum, a) => sum + a.balanceMinor),
  );
});
