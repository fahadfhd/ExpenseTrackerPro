import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/utils/haptics.dart';
import 'package:kept/features/accounts/application/account_providers.dart';
import 'package:kept/features/accounts/domain/account.dart';
import 'package:kept/features/credit_cards/domain/credit_card.dart';

/// Where money moved: a bank/cash account, a credit card, or explicitly
/// nowhere tracked ("cash"). A null value in a form means "not chosen yet".
sealed class PaymentSource {
  const PaymentSource();

  String? get accountId => null;

  String? get cardId => null;
}

class AccountSource extends PaymentSource {
  const AccountSource(this.id);
  final String id;

  @override
  String get accountId => id;

  @override
  bool operator ==(Object other) => other is AccountSource && other.id == id;

  @override
  int get hashCode => Object.hash('account', id);
}

class CardSource extends PaymentSource {
  const CardSource(this.id);
  final String id;

  @override
  String get cardId => id;

  @override
  bool operator ==(Object other) => other is CardSource && other.id == id;

  @override
  int get hashCode => Object.hash('card', id);
}

/// Money not tracked in any account (physical cash, someone else's card).
class CashSource extends PaymentSource {
  const CashSource();

  @override
  bool operator ==(Object other) => other is CashSource;

  @override
  int get hashCode => 7;
}

IconData accountTypeIcon(AccountType type) => switch (type) {
  AccountType.savings => Icons.savings_rounded,
  AccountType.current => Icons.account_balance_rounded,
  AccountType.cash => Icons.payments_rounded,
  AccountType.wallet => Icons.account_balance_wallet_rounded,
  AccountType.other => Icons.folder_rounded,
};

enum _Kind { account, card, cash }

_Kind? _kindOf(PaymentSource? source) => switch (source) {
  AccountSource() => _Kind.account,
  CardSource() => _Kind.card,
  CashSource() => _Kind.cash,
  null => null,
};

/// "Which bank or card?", in two small steps so the form stays calm: first
/// only the *kinds* of payment on offer (bank account, credit card, cash),
/// then, once one is picked, just that kind's list with each live balance or
/// available credit. Picking cash selects it straight away. Tapping the
/// selected kind or the selected option again clears it, so a mistaken
/// choice is never stuck. When a form offers only one kind, its list is
/// shown at once.
///
/// The same widget is used in every form that moves money (transactions,
/// loan payments, borrow/lend, fuel, recurring…), so choosing a payment
/// source looks and works the same everywhere.
class PaymentSourceField extends ConsumerStatefulWidget {
  const PaymentSourceField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.accounts = const [],
    this.cards = const [],
    this.allowCash = true,
    this.cashLabel,
    this.errorText,
  });

  final String label;
  final PaymentSource? value;
  final ValueChanged<PaymentSource?> onChanged;

  /// Offered accounts; callers pass active ones (plus an archived one that
  /// is already selected).
  final List<Account> accounts;
  final List<CreditCard> cards;

  /// Offer the explicit untracked-cash option.
  final bool allowCash;

  /// Name of the cash option where "Cash" does not fit (e.g. "Don't record").
  final String? cashLabel;
  final String? errorText;

  @override
  ConsumerState<PaymentSourceField> createState() => _PaymentSourceFieldState();
}

class _PaymentSourceFieldState extends ConsumerState<PaymentSourceField> {
  /// The kind whose list is open (chosen by the user or by the value).
  late _Kind? _picked = _kindOf(widget.value);

  @override
  void didUpdateWidget(PaymentSourceField old) {
    super.didUpdateWidget(old);
    // A value set from outside (a preselected account) opens its list.
    final kind = _kindOf(widget.value);
    if (kind != null) _picked = kind;
  }

  List<_Kind> get _kinds => [
    if (widget.accounts.isNotEmpty) _Kind.account,
    if (widget.cards.isNotEmpty) _Kind.card,
    if (widget.allowCash) _Kind.cash,
  ];

  /// The kind shown: the only one on offer, else the one picked.
  _Kind? get _shown {
    final kinds = _kinds;
    if (kinds.length == 1) return kinds.first;
    return kinds.contains(_picked) ? _picked : null;
  }

  void _pick(_Kind kind) {
    Haptics.selection();
    final current = _kindOf(widget.value);
    if (_shown == kind) {
      // Tapping the open kind closes it and clears a choice made in it.
      setState(() => _picked = null);
      if (current == kind) widget.onChanged(null);
      return;
    }
    setState(() => _picked = kind);
    if (kind == _Kind.cash) {
      widget.onChanged(const CashSource());
    } else if (current != kind) {
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final value = widget.value;
    final kinds = _kinds;
    final shown = _shown;

    void toggle(PaymentSource source) {
      Haptics.selection();
      widget.onChanged(value == source ? null : source);
    }

    // One compact chip per account or card: the choice stays short however
    // many there are.
    Widget chipFor({
      required PaymentSource source,
      required IconData icon,
      required String title,
    }) {
      final selected = value == source;
      return Semantics(
        button: true,
        selected: selected,
        label: title,
        excludeSemantics: true,
        child: ChoiceChip(
          avatar: Icon(icon, size: 18),
          label: Text(title),
          showCheckmark: false,
          selected: selected,
          onSelected: (_) => toggle(source),
        ),
      );
    }

    String kindLabel(_Kind kind) => switch (kind) {
      _Kind.account => l10n.paymentTypeAccount,
      _Kind.card => l10n.creditCard,
      _Kind.cash => widget.cashLabel ?? l10n.paymentTypeCash,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            widget.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (kinds.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in kinds)
                  ChoiceChip(
                    label: Text(kindLabel(kind)),
                    showCheckmark: false,
                    selected: shown == kind,
                    onSelected: (_) => _pick(kind),
                  ),
              ],
            ),
          ),
        if (shown == _Kind.account || shown == _Kind.card)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shown == _Kind.account)
                for (final a in widget.accounts)
                  chipFor(
                    source: AccountSource(a.id),
                    icon: accountTypeIcon(a.type),
                    title: a.displayName,
                  ),
              if (shown == _Kind.card)
                for (final c in widget.cards)
                  chipFor(
                    source: CardSource(c.id),
                    icon: Icons.credit_card_rounded,
                    title: c.displayName,
                  ),
            ],
          ),
        if (shown == _Kind.cash)
          Text(
            l10n.paymentCashHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (widget.errorText != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                widget.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Initial [PaymentSource] for a form that stores a nullable account id.
///
/// [accountId] is dropped if that account no longer exists. A missing id on
/// an existing record ([known] true) means it was paid in untracked cash;
/// for a new record it means "not chosen yet", so the user is asked.
PaymentSource? paymentFor(
  WidgetRef ref,
  String? accountId, {
  required bool known,
}) {
  final id = existingAccountId(ref, accountId);
  if (id != null) return AccountSource(id);
  return known ? const CashSource() : null;
}
