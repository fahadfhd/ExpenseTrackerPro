import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/credit_cards/data/credit_card_repository.dart';
import 'package:expensetrackerpro/features/credit_cards/domain/credit_card.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/ledger_effects.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditCardRepositoryProvider = Provider<CreditCardRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return CreditCardRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final cardsProvider = StreamProvider<List<CreditCard>>(
  (ref) => ref.watch(creditCardRepositoryProvider).watchAll(),
);

final activeCardsProvider = Provider<List<CreditCard>>(
  (ref) => (ref.watch(cardsProvider).value ?? const [])
      .where((c) => !c.archived)
      .toList(),
);

final cardsByIdProvider = Provider<Map<String, CreditCard>>(
  (ref) => {for (final c in ref.watch(cardsProvider).value ?? []) c.id: c},
);

/// Statement status of every card, from one query covering the longest
/// open billing period (at most about a month of transactions).
final cardStatusesProvider = Provider.autoDispose<Map<String, CardStatus>>((
  ref,
) {
  final cards = ref.watch(activeCardsProvider);
  if (cards.isEmpty) return const {};
  final now = DateTime.now();
  final starts = cards.map(
    (c) => c.lastStatementDate(now).add(const Duration(days: 1)),
  );
  final earliest = starts.reduce((a, b) => a.isBefore(b) ? a : b);
  final range = DateRange(earliest, Dates.dayOf(now).add(const Duration(days: 1)));
  final transactions =
      ref.watch(transactionsInRangeProvider(range)).value ?? const [];

  return {
    for (final card in cards)
      card.id: () {
        final since = card.lastStatementDate(now).add(const Duration(days: 1));
        var charges = 0, payments = 0;
        for (final tx in transactions) {
          if (tx.creditCardId != card.id || tx.date.isBefore(since)) continue;
          final delta = LedgerEffects.of(tx).cards[card.id] ?? 0;
          if (delta > 0) {
            charges += delta;
          } else {
            payments -= delta;
          }
        }
        return CardStatus.compute(
          card: card,
          now: now,
          chargesSince: charges,
          paymentsSince: payments,
        );
      }(),
  };
});
