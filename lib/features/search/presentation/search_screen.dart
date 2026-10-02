import 'dart:async';

import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/routing/app_routes.dart';
import 'package:expensetrackerpro/core/utils/dates.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/borrow_lend/application/debt_providers.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/loans/application/loan_providers.dart';
import 'package:expensetrackerpro/features/reminders/application/reminder_providers.dart';
import 'package:expensetrackerpro/features/reminders/presentation/reminders_screen.dart';
import 'package:expensetrackerpro/features/transactions/application/transaction_providers.dart';
import 'package:expensetrackerpro/features/transactions/domain/transaction_query.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_detail_sheet.dart';
import 'package:expensetrackerpro/features/transactions/presentation/transaction_tile.dart';
import 'package:expensetrackerpro/features/vehicles/application/vehicle_providers.dart';
import 'package:expensetrackerpro/features/vehicles/presentation/vehicles_screen.dart';
import 'package:expensetrackerpro/shared/widgets/dialogs.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Months of transactions included in global search.
const _searchMonths = 12;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  bool _match(Iterable<String> fields) {
    final haystack = fields.join(' ').toLowerCase();
    return _query.toLowerCase().split(RegExp(r'\s+')).every(haystack.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = _query.length >= 2;
    final range = DateRange(
      DateTime(DateTime.now().year, DateTime.now().month - _searchMonths + 1),
      Dates.dayOf(DateTime.now()).add(const Duration(days: 366)),
    );
    final transactions = active
        ? ref.watch(transactionsInRangeProvider(range))
        : const AsyncValue<List<Never>>.data([]);
    final searchText = ref.watch(transactionSearchTextProvider);

    final sections = <(String, List<Widget>)>[];
    if (active) {
      final txHits = TransactionQuery.apply(
        transactions.value ?? const [],
        TransactionFilter(text: _query),
        searchText: searchText,
      ).take(50).toList();
      sections.add((l10n.searchGroupTransactions, [
        for (final tx in txHits)
          TransactionTile(tx, showDate: true, onTap: () => TransactionDetailSheet.show(context, tx)),
      ]));

      final accounts = ref.watch(accountsProvider).value ?? const [];
      sections.add((l10n.searchGroupAccounts, [
        for (final a in accounts.where((a) => _match([a.name, a.bankName, a.notes, l10n.accountType(a.type)])))
          ListTile(
            leading: const Icon(Icons.account_balance_rounded),
            title: Text(a.name),
            subtitle: Text(a.bankName),
            onTap: () => AppRoutes.account(context, a.id),
          ),
      ]));

      final cards = ref.watch(cardsProvider).value ?? const [];
      sections.add((l10n.searchGroupCards, [
        for (final c in cards.where((c) => _match([c.name, c.bankName, c.last4, c.notes])))
          ListTile(
            leading: const Icon(Icons.credit_card_rounded),
            title: Text(c.displayName),
            subtitle: Text(c.bankName),
            onTap: () => AppRoutes.card(context, c.id),
          ),
      ]));

      final loans = ref.watch(loansProvider).value ?? const [];
      sections.add((l10n.searchGroupLoans, [
        for (final loan in loans.where((x) => _match([x.name, x.lender, x.notes])))
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: Text(loan.name),
            subtitle: Text(loan.lender),
            onTap: () => AppRoutes.loan(context, loan.id),
          ),
      ]));

      final debts = ref.watch(debtsProvider).value ?? const [];
      sections.add((l10n.searchGroupDebts, [
        for (final d in debts.where((d) => _match([d.personName, d.description, d.notes, l10n.debtDirection(d.direction)])))
          ListTile(
            leading: const Icon(Icons.handshake_rounded),
            title: Text(d.personName),
            subtitle: Text(l10n.debtDirection(d.direction)),
            onTap: () => AppRoutes.debt(context, d.id),
          ),
      ]));

      final reminders = ref.watch(remindersProvider).value ?? const [];
      sections.add((l10n.searchGroupReminders, [
        for (final r in reminders.where((r) => _match([r.title, r.description, l10n.reminderType(r.type)])))
          ListTile(
            leading: Icon(reminderIcon(r.type)),
            title: Text(r.title),
            subtitle: Text(l10n.recurrence(r.recurrence)),
            onTap: () => pushPage(context, ReminderFormScreen(initial: r)),
          ),
      ]));

      final vehicles = ref.watch(vehiclesProvider).value ?? const [];
      sections.add((l10n.searchGroupVehicles, [
        for (final v in vehicles.where((v) => _match([v.name, v.registrationNickname, v.notes, l10n.fuelType(v.fuelType)])))
          ListTile(
            leading: const Icon(Icons.directions_car_rounded),
            title: Text(v.name),
            subtitle: Text(v.registrationNickname),
            onTap: () => pushPage(context, VehicleDetailScreen(vehicleId: v.id)),
          ),
      ]));
    }
    final nonEmpty = sections.where((s) => s.$2.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
      body: !active
          ? EmptyState(icon: Icons.search_rounded, message: l10n.searchStart)
          : transactions.isLoading && nonEmpty.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: SkeletonList())
          : nonEmpty.isEmpty
          ? EmptyState(icon: Icons.search_off_rounded, message: l10n.searchNoResults(_query))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                Text(l10n.searchScopeNote, style: theme.textTheme.bodySmall),
                for (final (title, items) in nonEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Semantics(
                      header: true,
                      child: Text(
                        '$title (${items.length})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  ...items,
                ],
              ],
            ),
    );
  }
}
