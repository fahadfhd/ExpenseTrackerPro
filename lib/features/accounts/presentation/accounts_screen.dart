import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/routing/app_routes.dart';
import 'package:expensetrackerpro/features/accounts/application/account_providers.dart';
import 'package:expensetrackerpro/features/accounts/domain/account.dart';
import 'package:expensetrackerpro/features/credit_cards/application/card_providers.dart';
import 'package:expensetrackerpro/features/credit_cards/domain/credit_card.dart';
import 'package:expensetrackerpro/shared/widgets/money_text.dart';
import 'package:expensetrackerpro/shared/widgets/section_card.dart';
import 'package:expensetrackerpro/shared/widgets/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

IconData accountIcon(AccountType type) => switch (type) {
  AccountType.savings => Icons.savings_rounded,
  AccountType.current => Icons.account_balance_rounded,
  AccountType.cash => Icons.payments_rounded,
  AccountType.wallet => Icons.account_balance_wallet_rounded,
  AccountType.other => Icons.folder_rounded,
};

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [Tab(text: l10n.accountsTab), Tab(text: l10n.cardsTab)],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts-fab',
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tabs,
          builder: (_, _) => Text(_tabs.index == 0 ? l10n.addAccount : l10n.addCard),
        ),
        onPressed: () => _tabs.index == 0
            ? AppRoutes.newAccount(context)
            : AppRoutes.newCard(context),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_AccountsTab(), _CardsTab()],
      ),
    );
  }
}

class _AccountsTab extends ConsumerStatefulWidget {
  const _AccountsTab();

  @override
  ConsumerState<_AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends ConsumerState<_AccountsTab> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider);
    final worth = ref.watch(netWorthProvider);
    return AsyncView<List<Account>>(
      value: accounts,
      onRetry: () => ref.invalidate(accountsProvider),
      data: (list) {
        final active = list.where((a) => !a.archived).toList();
        final archived = list.where((a) => a.archived).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            SectionCard(
              title: l10n.netWorth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyText(
                    worth.netMinor,
                    tone: worth.netMinor < 0 ? MoneyTone.negative : MoneyTone.neutral,
                    signed: worth.netMinor < 0,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _LabeledAmount(l10n.assets, worth.assetsMinor)),
                      Expanded(child: _LabeledAmount(l10n.cardDebt, worth.cardDebtMinor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (active.isEmpty)
              EmptyState(icon: Icons.account_balance_rounded, message: l10n.accountsEmpty),
            for (final a in active) _AccountTile(a),
            if (archived.isNotEmpty)
              TextButton.icon(
                icon: Icon(_showArchived ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                label: Text(l10n.showArchived('${archived.length}')),
                onPressed: () => setState(() => _showArchived = !_showArchived),
              ),
            if (_showArchived) for (final a in archived) _AccountTile(a),
          ],
        );
      },
    );
  }
}

class _LabeledAmount extends StatelessWidget {
  const _LabeledAmount(this.label, this.amountMinor);
  final String label;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        MoneyText(amountMinor, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile(this.account);
  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final negative = account.balanceMinor < 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => AppRoutes.account(context, account.id),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(accountIcon(account.type), color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            if (account.bankName.isNotEmpty) account.bankName,
            l10n.accountType(account.type),
            if (account.archived) l10n.archived,
          ].join(' · '),
        ),
        trailing: MoneyText(
          account.balanceMinor,
          tone: negative ? MoneyTone.negative : MoneyTone.neutral,
          signed: negative,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CardsTab extends ConsumerWidget {
  const _CardsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cards = ref.watch(cardsProvider);
    final statuses = ref.watch(cardStatusesProvider);
    return AsyncView<List<CreditCard>>(
      value: cards,
      onRetry: () => ref.invalidate(cardsProvider),
      data: (list) {
        final visible = list.where((c) => !c.archived).toList();
        if (visible.isEmpty) {
          return EmptyState(icon: Icons.credit_card_rounded, message: l10n.cardsEmpty);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            for (final card in visible)
              CardSummaryTile(card: card, status: statuses[card.id]),
          ],
        );
      },
    );
  }
}

class CardSummaryTile extends StatelessWidget {
  const CardSummaryTile({super.key, required this.card, this.status});

  final CreditCard card;
  final CardStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final percent = (card.utilization * 100).round();
    final locale = Localizations.localeOf(context).toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppRoutes.card(context, card.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      card.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (card.bankName.isNotEmpty)
                    Text(card.bankName, style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _LabeledAmount(l10n.outstanding, card.outstandingMinor)),
                  Expanded(child: _LabeledAmount(l10n.available, card.availableMinor)),
                  Expanded(child: _LabeledAmount(l10n.creditLimit, card.creditLimitMinor)),
                ],
              ),
              const SizedBox(height: 12),
              ProgressMeter(
                ratio: card.utilization,
                semanticsLabel: l10n.utilization,
                warnAt: 0.3,
                alertAt: 0.75,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(l10n.utilizationValue('$percent'), style: theme.textTheme.labelMedium),
                  const Spacer(),
                  if (status != null && status!.totalDueMinor > 0)
                    Text(
                      '${l10n.totalDue}: ${DateFormat.MMMd(locale).format(status!.dueDate)}',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
