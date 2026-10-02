import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/features/accounts/data/account_repository.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) throw StateError('Requires a signed-in user');
  return AccountRepository(
    userDoc: userDoc,
    writer: ref.watch(writeDispatcherProvider),
    transactions: ref.watch(transactionRepositoryProvider),
  );
});

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Accounts that can be picked for new transactions.
final activeAccountsProvider = Provider<List<Account>>(
  (ref) => (ref.watch(accountsProvider).value ?? const [])
      .where((a) => !a.archived)
      .toList(),
);

final accountsByIdProvider = Provider<Map<String, Account>>(
  (ref) => {for (final a in ref.watch(accountsProvider).value ?? []) a.id: a},
);

class NetWorth {
  const NetWorth({required this.assetsMinor, required this.cardDebtMinor});

  /// Sum of account balances.
  final int assetsMinor;

  /// Sum of positive card outstanding.
  final int cardDebtMinor;

  int get netMinor => assetsMinor - cardDebtMinor;
}

/// Balances come straight from each account's stored ledger delta; nothing
/// is recomputed in widgets.
final netWorthProvider = Provider<NetWorth>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? const [];
  final cards = ref.watch(cardsProvider).value ?? const [];
  return NetWorth(
    assetsMinor: accounts.fold(0, (s, a) => s + a.balanceMinor),
    cardDebtMinor: cards.fold(
      0,
      (s, c) => s + (c.outstandingMinor > 0 ? c.outstandingMinor : 0),
    ),
  );
});

/// [id] if that account still exists (archived included), otherwise null,
/// so forms never preselect a deleted account. While accounts are still
/// loading the id is kept rather than guessed away.
String? existingAccountId(WidgetRef ref, String? id) {
  if (id == null) return null;
  final accounts = ref.read(accountsProvider);
  if (!accounts.hasValue) return id;
  return accounts.requireValue.any((a) => a.id == id) ? id : null;
}
