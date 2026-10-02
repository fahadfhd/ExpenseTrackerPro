import 'package:expensetrackerpro/core/transactions/email_transaction_parser.dart';
import 'package:expensetrackerpro/core/transactions/transaction_deduplicator.dart';
import 'package:expensetrackerpro/data/repositories/google_gmail_repository.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gmailRepositoryProvider = Provider<GmailRepository>(
  (ref) => GoogleGmailRepository(),
);

/// Imports bank/card emails through the existing (feature-flagged) Gmail
/// parser. Parsed items use deterministic ids and the legacy item shape is
/// converted by `Transaction.fromMap`, so re-importing never duplicates.
/// Imported entries are not linked to accounts, so balances are unaffected
/// until the user assigns them.
class GmailImport {
  GmailImport(this._ref);

  final Ref _ref;

  Future<int> run() async {
    final gmail = _ref.read(gmailRepositoryProvider);
    final state = await gmail.connectReadOnly();
    if (!state.isConnected) return 0;
    final messages = await gmail.getRelevantMessages();
    final items = TransactionDeduplicator.deduplicate(
      EmailTransactionParser.parse(messages),
    );
    final transactions = [
      for (final item in items) Transaction.fromMap(item.id, item.toMap()),
    ];
    _ref.read(transactionRepositoryProvider).saveAll(transactions);
    return transactions.length;
  }
}

final gmailImportProvider = Provider<GmailImport>(GmailImport.new);
