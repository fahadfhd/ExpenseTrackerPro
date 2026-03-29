import 'package:expensetrackerpro/core/transactions/email_due_parser.dart';
import 'package:expensetrackerpro/core/transactions/email_transaction_parser.dart';
import 'package:expensetrackerpro/core/transactions/transaction_filters.dart';
import 'package:expensetrackerpro/domain/entities/due_item.dart';
import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/entities/sms_permission_state.dart';
import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/usecases/connect_gmail_readonly.dart';
import 'package:expensetrackerpro/domain/usecases/disconnect_gmail.dart';
import 'package:expensetrackerpro/domain/usecases/get_gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/usecases/get_relevant_gmail_messages.dart';
import 'package:expensetrackerpro/domain/usecases/get_sms_permission_status.dart';
import 'package:expensetrackerpro/domain/usecases/get_transactions.dart';
import 'package:expensetrackerpro/domain/usecases/open_sms_permission_settings.dart';
import 'package:expensetrackerpro/domain/usecases/request_sms_permission.dart';
import 'package:expensetrackerpro/domain/usecases/upsert_transactions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExpanseTrackerHome extends StatefulWidget {
  const ExpanseTrackerHome({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.getTransactions,
    required this.getSmsPermissionStatus,
    required this.requestSmsPermission,
    required this.openSmsPermissionSettings,
    required this.upsertTransactions,
    required this.clearTransactions,
    required this.getGmailConnectionState,
    required this.connectGmailReadOnly,
    required this.disconnectGmail,
    required this.getRelevantGmailMessages,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final GetTransactions getTransactions;
  final GetSmsPermissionStatus getSmsPermissionStatus;
  final RequestSmsPermission requestSmsPermission;
  final OpenSmsPermissionSettings openSmsPermissionSettings;
  final UpsertTransactions upsertTransactions;
  final Future<void> Function() clearTransactions;
  final GetGmailConnectionState getGmailConnectionState;
  final ConnectGmailReadOnly connectGmailReadOnly;
  final DisconnectGmail disconnectGmail;
  final GetRelevantGmailMessages getRelevantGmailMessages;

  @override
  State<ExpanseTrackerHome> createState() => _ExpanseTrackerHomeState();
}

class _ExpanseTrackerHomeState extends State<ExpanseTrackerHome> {
  int _currentIndex = 0;
  SmsPermissionState _smsPermissionState = SmsPermissionState.denied();
  GmailConnectionState _gmailConnectionState = GmailConnectionState.signedOut();
  List<EmailMessageItem> _gmailMessages = const [];
  List<DueItem> _dueItems = const [];
  TransactionDateFilter _selectedDateFilter = TransactionDateFilter.all;
  bool _filterUpiOnly = false;
  bool _filterCardsOnly = false;
  bool _filterDebitOnly = false;
  bool _isLoadingPermission = true;
  bool _isUpdatingPermission = false;
  bool _isLoadingGmail = true;
  bool _isConnectingGmail = false;
  bool _isSyncingGmail = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
    _loadGmailState();
  }

  Future<void> _loadPermissionStatus() async {
    final state = await widget.getSmsPermissionStatus();
    if (!mounted) return;

    setState(() {
      _smsPermissionState = state;
      _isLoadingPermission = false;
    });
  }

  Future<void> _loadGmailState() async {
    final state = await widget.getGmailConnectionState();
    if (!mounted) return;

    setState(() {
      _gmailConnectionState = state;
      _isLoadingGmail = false;
    });
  }

  Future<void> _handleSmsPermissionAction() async {
    if (_isUpdatingPermission) return;

    setState(() {
      _isUpdatingPermission = true;
    });

    if (_smsPermissionState.needsSettings) {
      await widget.openSmsPermissionSettings();
      await _loadPermissionStatus();
    } else {
      final state = await widget.requestSmsPermission();
      if (!mounted) return;

      setState(() {
        _smsPermissionState = state;
      });
    }

    if (!mounted) return;
    setState(() {
      _isUpdatingPermission = false;
    });
  }

  Future<void> _handleGmailConnectionAction() async {
    if (_isConnectingGmail) return;

    setState(() {
      _isConnectingGmail = true;
    });

    if (_gmailConnectionState.isConnected) {
      await widget.disconnectGmail();
      await _loadGmailState();
      if (!mounted) return;
      setState(() {
        _gmailMessages = const [];
      });
    } else {
      final state = await widget.connectGmailReadOnly();
      if (!mounted) return;

      setState(() {
        _gmailConnectionState = state;
      });
    }

    if (!mounted) return;
    setState(() {
      _isConnectingGmail = false;
    });
  }

  Future<void> _syncGmailMessages() async {
    if (_isSyncingGmail || !_gmailConnectionState.isConnected) return;

    setState(() {
      _isSyncingGmail = true;
    });

    final messages = await widget.getRelevantGmailMessages();
    final parsedTransactions = EmailTransactionParser.parse(messages);
    final dueItems = EmailDueParser.parse(messages);
    await widget.upsertTransactions(parsedTransactions);
    if (!mounted) return;

    setState(() {
      _gmailMessages = messages;
      _dueItems = dueItems;
      _isSyncingGmail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? const [
                    Color(0xFF12212A),
                    Color(0xFF091116),
                    Color(0xFF060B0F),
                  ]
                : const [
                    Color(0xFFE9F6EF),
                    Color(0xFFF4F7F2),
                    Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ExpanseTrackerPro',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _headerSubtitle(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Clear data',
                      onPressed: () async {
                        await widget.clearTransactions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transactions wiped out!'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Toggle theme',
                      onPressed: widget.onToggleTheme,
                      icon: Icon(
                        widget.themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<TransactionItem>>(
                  stream: widget.getTransactions(),
                  initialData: const [],
                  builder: (context, snapshot) {
                    final transactions = snapshot.data ?? const [];
                    final filteredTransactions = TransactionFilters.apply(
                      transactions: transactions,
                      dateFilter: _selectedDateFilter,
                      upiOnly: _filterUpiOnly,
                      cardsOnly: _filterCardsOnly,
                      debitOnly: _filterDebitOnly,
                    );
                    final pages = [
                      _DashboardView(
                        transactions: transactions,
                        onViewTransactions: () =>
                            setState(() => _currentIndex = 1),
                        smsPermissionState: _smsPermissionState,
                        isLoadingPermission: _isLoadingPermission,
                        isUpdatingPermission: _isUpdatingPermission,
                        onSmsPermissionPressed: _handleSmsPermissionAction,
                        gmailConnectionState: _gmailConnectionState,
                        gmailMessages: _gmailMessages,
                        dueItems: _dueItems,
                        isLoadingGmail: _isLoadingGmail,
                        isConnectingGmail: _isConnectingGmail,
                        isSyncingGmail: _isSyncingGmail,
                        onGmailConnectionPressed: _handleGmailConnectionAction,
                        onSyncGmailPressed: _syncGmailMessages,
                      ),
                      _TransactionsView(
                        transactions: filteredTransactions,
                        selectedDateFilter: _selectedDateFilter,
                        filterUpiOnly: _filterUpiOnly,
                        filterCardsOnly: _filterCardsOnly,
                        filterDebitOnly: _filterDebitOnly,
                        onDateFilterChanged: (filter) {
                          setState(() {
                            _selectedDateFilter = filter;
                          });
                        },
                        onUpiFilterChanged: (value) {
                          setState(() {
                            _filterUpiOnly = value;
                          });
                        },
                        onCardsFilterChanged: (value) {
                          setState(() {
                            _filterCardsOnly = value;
                          });
                        },
                        onDebitFilterChanged: (value) {
                          setState(() {
                            _filterDebitOnly = value;
                          });
                        },
                      ),
                      const _MonetizationView(),
                    ];

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(
                          '${_currentIndex}_${transactions.length}',
                        ),
                        child: pages[_currentIndex],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.workspace_premium_outlined),
                  selectedIcon: Icon(Icons.workspace_premium_rounded),
                  label: 'Monetize',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _headerSubtitle() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    switch (_currentIndex) {
      case 1:
        return isAndroid
            ? 'Review transactions imported from SMS and Gmail.'
            : 'Review transactions imported from Gmail.';
      case 2:
        return 'Ad-friendly revenue layers that still feel premium.';
      default:
        return isAndroid
            ? 'Import spending from SMS and Gmail in one clean tracker.'
            : 'Import spending from Gmail in one clean tracker.';
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.transactions,
    required this.onViewTransactions,
    required this.smsPermissionState,
    required this.isLoadingPermission,
    required this.isUpdatingPermission,
    required this.onSmsPermissionPressed,
    required this.gmailConnectionState,
    required this.gmailMessages,
    required this.dueItems,
    required this.isLoadingGmail,
    required this.isConnectingGmail,
    required this.isSyncingGmail,
    required this.onGmailConnectionPressed,
    required this.onSyncGmailPressed,
  });

  final List<TransactionItem> transactions;
  final VoidCallback onViewTransactions;
  final SmsPermissionState smsPermissionState;
  final bool isLoadingPermission;
  final bool isUpdatingPermission;
  final VoidCallback onSmsPermissionPressed;
  final GmailConnectionState gmailConnectionState;
  final List<EmailMessageItem> gmailMessages;
  final List<DueItem> dueItems;
  final bool isLoadingGmail;
  final bool isConnectingGmail;
  final bool isSyncingGmail;
  final VoidCallback onGmailConnectionPressed;
  final VoidCallback onSyncGmailPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final now = DateTime.now();
    final monthlySpend = transactions
        .where(
          (transaction) =>
              !transaction.isCredit &&
              transaction.occurredAt.year == now.year &&
              transaction.occurredAt.month == now.month,
        )
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final categorizedCount = transactions
        .where((transaction) => transaction.category != 'Uncategorized')
        .length;
    final categorizedPercent = transactions.isEmpty
        ? 0
        : ((categorizedCount / transactions.length) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _HeroCard(transactions: transactions),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'This month',
                value: transactions.isEmpty ? 'No data' : '₹$monthlySpend',
                delta: transactions.isEmpty
                    ? 'Scan transactions'
                    : '${transactions.where((item) => !item.isCredit).length} spends',
                icon: Icons.calendar_month_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MetricCard(
                label: 'Auto-categorized',
                value: transactions.isEmpty ? '--' : '$categorizedPercent%',
                delta: transactions.isEmpty
                    ? 'Waiting for imports'
                    : '${transactions.length} records',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
        ),
        if (isAndroid) ...[
          const SizedBox(height: 18),
          _SmsPermissionCard(
            state: smsPermissionState,
            isLoading: isLoadingPermission,
            isUpdating: isUpdatingPermission,
            onPressed: onSmsPermissionPressed,
          ),
        ],
        const SizedBox(height: 18),
        _GmailAccessCard(
          state: gmailConnectionState,
          messages: gmailMessages,
          isLoading: isLoadingGmail,
          isConnecting: isConnectingGmail,
          isSyncing: isSyncingGmail,
          onConnectPressed: onGmailConnectionPressed,
          onSyncPressed: onSyncGmailPressed,
        ),
        if (dueItems.isNotEmpty) ...[
          const SizedBox(height: 18),
          _DueItemsCard(dueItems: dueItems),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onViewTransactions,
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (isAndroid)
                      const _ActionChip(
                        icon: Icons.sms_rounded,
                        label: 'Read SMS',
                      ),
                    const _ActionChip(
                      icon: Icons.mark_email_read_rounded,
                      label: 'Read Gmail',
                    ),
                    const _ActionChip(
                      icon: Icons.category_rounded,
                      label: 'Tune categories',
                    ),
                    const _ActionChip(
                      icon: Icons.shield_outlined,
                      label: 'Privacy policy',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Recent transactions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          _EmptyTransactionsCard(isAndroid: isAndroid)
        else
          ...transactions.take(3).map(_TransactionTile.new),
      ],
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard({required this.isAndroid});

  final bool isAndroid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No transactions yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isAndroid
                  ? 'Connect Gmail and allow SMS access to start importing real transactions.'
                  : 'Connect Gmail to start importing real transactions.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueItemsCard extends StatelessWidget {
  const _DueItemsCard({required this.dueItems});

  final List<DueItem> dueItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming card dues',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...dueItems.take(3).map((due) {
              final dueDate =
                  '${due.dueDate.day.toString().padLeft(2, '0')}/${due.dueDate.month.toString().padLeft(2, '0')}/${due.dueDate.year}';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD96C3F).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: Color(0xFFD96C3F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            due.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due on $dueDate',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${due.amount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD96C3F),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GmailAccessCard extends StatelessWidget {
  const _GmailAccessCard({
    required this.state,
    required this.messages,
    required this.isLoading,
    required this.isConnecting,
    required this.isSyncing,
    required this.onConnectPressed,
    required this.onSyncPressed,
  });

  final GmailConnectionState state;
  final List<EmailMessageItem> messages;
  final bool isLoading;
  final bool isConnecting;
  final bool isSyncing;
  final VoidCallback onConnectPressed;
  final VoidCallback onSyncPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = state.isConnected
        ? const Color(0xFF1B8A5A)
        : state.isUnsupported
        ? const Color(0xFF5687FF)
        : const Color(0xFFDAA447);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.mail_rounded, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gmail Read-Only',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              state.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (state.email != null) ...[
              const SizedBox(height: 10),
              Text(
                state.email!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: state.isUnsupported || isLoading || isConnecting
                      ? null
                      : onConnectPressed,
                  icon: isConnecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          state.isConnected
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                        ),
                  label: Text(
                    state.isConnected ? 'Disconnect' : 'Connect Gmail',
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: state.isConnected && !isSyncing
                      ? onSyncPressed
                      : null,
                  icon: isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: const Text('Scan finance emails'),
                ),
              ],
            ),
            if (messages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent Gmail matches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...messages.take(3).map(_EmailPreviewTile.new),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmailPreviewTile extends StatelessWidget {
  const _EmailPreviewTile(this.message);

  final EmailMessageItem message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.subject,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.sender,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.dateLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsPermissionCard extends StatelessWidget {
  const _SmsPermissionCard({
    required this.state,
    required this.isLoading,
    required this.isUpdating,
    required this.onPressed,
  });

  final SmsPermissionState state;
  final bool isLoading;
  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentForState(state.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.markunread_rounded, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMS Permission',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              state.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: state.isUnsupported || isLoading || isUpdating
                      ? null
                      : onPressed,
                  icon: isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          state.needsSettings
                              ? Icons.settings_rounded
                              : state.isGranted
                              ? Icons.check_circle_rounded
                              : Icons.lock_open_rounded,
                        ),
                  label: Text(_buttonLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _buttonLabel {
    if (state.isUnsupported) return 'Android only';
    if (state.isGranted) return 'Enabled';
    if (state.needsSettings) return 'Open settings';
    return 'Allow SMS access';
  }

  Color _accentForState(SmsPermissionStatusType status) {
    switch (status) {
      case SmsPermissionStatusType.granted:
        return const Color(0xFF1B8A5A);
      case SmsPermissionStatusType.permanentlyDenied:
        return const Color(0xFFD96C3F);
      case SmsPermissionStatusType.unsupported:
        return const Color(0xFF5687FF);
      case SmsPermissionStatusType.denied:
        return const Color(0xFFDAA447);
    }
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView({
    required this.transactions,
    required this.selectedDateFilter,
    required this.filterUpiOnly,
    required this.filterCardsOnly,
    required this.filterDebitOnly,
    required this.onDateFilterChanged,
    required this.onUpiFilterChanged,
    required this.onCardsFilterChanged,
    required this.onDebitFilterChanged,
  });

  final List<TransactionItem> transactions;
  final TransactionDateFilter selectedDateFilter;
  final bool filterUpiOnly;
  final bool filterCardsOnly;
  final bool filterDebitOnly;
  final ValueChanged<TransactionDateFilter> onDateFilterChanged;
  final ValueChanged<bool> onUpiFilterChanged;
  final ValueChanged<bool> onCardsFilterChanged;
  final ValueChanged<bool> onDebitFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FilterChip(
                              label: 'Today',
                              isSelected:
                                  selectedDateFilter ==
                                  TransactionDateFilter.today,
                              onTap: () => onDateFilterChanged(
                                selectedDateFilter ==
                                        TransactionDateFilter.today
                                    ? TransactionDateFilter.all
                                    : TransactionDateFilter.today,
                              ),
                            ),
                            _FilterChip(
                              label: 'This month',
                              isSelected:
                                  selectedDateFilter ==
                                  TransactionDateFilter.thisMonth,
                              onTap: () => onDateFilterChanged(
                                selectedDateFilter ==
                                        TransactionDateFilter.thisMonth
                                    ? TransactionDateFilter.all
                                    : TransactionDateFilter.thisMonth,
                              ),
                            ),
                            _FilterChip(
                              label: 'UPI',
                              isSelected: filterUpiOnly,
                              onTap: () => onUpiFilterChanged(!filterUpiOnly),
                            ),
                            _FilterChip(
                              label: 'Cards',
                              isSelected: filterCardsOnly,
                              onTap: () =>
                                  onCardsFilterChanged(!filterCardsOnly),
                            ),
                            _FilterChip(
                              label: 'Debit only',
                              isSelected: filterDebitOnly,
                              onTap: () =>
                                  onDebitFilterChanged(!filterDebitOnly),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          transactions.isEmpty
                              ? 'No transactions match the selected filters.'
                              : '${transactions.length} transaction${transactions.length == 1 ? '' : 's'} shown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (transactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Try clearing one or two filters, or import more data from Gmail/SMS.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (transactions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) =>
                  _TransactionTile(transactions[index]),
            ),
          ),
      ],
    );
  }
}

class _MonetizationView extends StatelessWidget {
  const _MonetizationView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Strategy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Keep the core tracker free, then monetize trust with subtle ads and a clean premium upgrade.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                const _RevenueTile(
                  title: 'Banner ads',
                  subtitle:
                      'Place on transaction list footer only, never above the summary cards.',
                  accent: Color(0xFF3AA58A),
                ),
                const SizedBox(height: 12),
                const _RevenueTile(
                  title: 'Premium plan',
                  subtitle:
                      'Offer ₹99 to remove ads, unlock exports, and enable bank-wise filtering.',
                  accent: Color(0xFFDAA447),
                ),
                const SizedBox(height: 12),
                const _RevenueTile(
                  title: 'Smart upsell',
                  subtitle:
                      'Show upgrade prompts after value moments like monthly summaries or export attempts.',
                  accent: Color(0xFF5687FF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.transactions});

  final List<TransactionItem> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = transactions
        .where((transaction) => !transaction.isCredit)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7C66), Color(0xFF18A17E), Color(0xFF0B5F5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'MVP Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Total spent',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹$totalSpent',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track finance signals from SMS first, then extend to Gmail read-only access.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delta,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(this.transaction);

  final TransactionItem transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = transaction.isCredit
        ? const Color(0xFF1B8A5A)
        : const Color(0xFFD96C3F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              transaction.isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: tone,
            ),
          ),
          title: Text(
            transaction.merchant,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.source),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CategoryPill(label: transaction.category),
                    Text(
                      transaction.dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: Text(
            '${transaction.isCredit ? '+' : '-'}₹${transaction.amount}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RevenueTile extends StatelessWidget {
  const _RevenueTile({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
