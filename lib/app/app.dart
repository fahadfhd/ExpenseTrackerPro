import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:expensetrackerpro/data/repositories/firebase_transaction_repository.dart';
import 'package:expensetrackerpro/data/repositories/firebase_user_profile_repository.dart';
import 'package:expensetrackerpro/data/repositories/google_gmail_repository.dart';
import 'package:expensetrackerpro/data/repositories/permission_handler_sms_permission_repository.dart';
import 'package:expensetrackerpro/data/repositories/shared_preferences_app_launch_repository.dart';
import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/repositories/app_launch_repository.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';
import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';
import 'package:expensetrackerpro/domain/repositories/user_profile_repository.dart';
import 'package:expensetrackerpro/domain/usecases/connect_gmail_readonly.dart';
import 'package:expensetrackerpro/domain/usecases/disconnect_gmail.dart';
import 'package:expensetrackerpro/domain/usecases/get_entry_flow_status.dart';
import 'package:expensetrackerpro/domain/usecases/get_gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/usecases/get_relevant_gmail_messages.dart';
import 'package:expensetrackerpro/domain/usecases/get_sms_permission_status.dart';
import 'package:expensetrackerpro/domain/usecases/get_transactions.dart';
import 'package:expensetrackerpro/domain/usecases/open_sms_permission_settings.dart';
import 'package:expensetrackerpro/domain/usecases/request_sms_permission.dart';
import 'package:expensetrackerpro/domain/usecases/set_entry_flow_status.dart';
import 'package:expensetrackerpro/domain/usecases/sync_current_user_profile.dart';
import 'package:expensetrackerpro/presentation/auth/google_login_screen.dart';
import 'package:expensetrackerpro/presentation/home/expanse_tracker_home.dart';
import 'package:expensetrackerpro/presentation/splash/splash_screen.dart';
import 'package:flutter/material.dart';

enum _AppStage { splash, login, home }

class ExpanseTrackerProApp extends StatefulWidget {
  const ExpanseTrackerProApp({
    super.key,
    this.smsPermissionRepository,
    this.gmailRepository,
    this.transactionRepository,
    this.userProfileRepository,
    this.appLaunchRepository,
  });

  final SmsPermissionRepository? smsPermissionRepository;
  final GmailRepository? gmailRepository;
  final TransactionRepository? transactionRepository;
  final UserProfileRepository? userProfileRepository;
  final AppLaunchRepository? appLaunchRepository;

  @override
  State<ExpanseTrackerProApp> createState() => _ExpanseTrackerProAppState();
}

class _ExpanseTrackerProAppState extends State<ExpanseTrackerProApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  _AppStage _stage = _AppStage.splash;
  GmailConnectionState _gmailConnectionState = GmailConnectionState.signedOut();
  late final SmsPermissionRepository _smsPermissionRepository =
      widget.smsPermissionRepository ??
      const PermissionHandlerSmsPermissionRepository();
  late final GmailRepository _gmailRepository =
      widget.gmailRepository ?? GoogleGmailRepository();
  late final TransactionRepository _transactionRepository =
      widget.transactionRepository ?? FirebaseTransactionRepository();
  late final UserProfileRepository _userProfileRepository =
      widget.userProfileRepository ?? FirebaseUserProfileRepository();
  late final AppLaunchRepository _appLaunchRepository =
      widget.appLaunchRepository ?? SharedPreferencesAppLaunchRepository();
  late final GetTransactions _getTransactions = GetTransactions(
    _transactionRepository,
  );
  late final GetGmailConnectionState _getGmailConnectionState =
      GetGmailConnectionState(_gmailRepository);
  late final ConnectGmailReadOnly _connectGmailReadOnly = ConnectGmailReadOnly(
    _gmailRepository,
  );
  late final SyncCurrentUserProfile _syncCurrentUserProfile =
      SyncCurrentUserProfile(_userProfileRepository);
  late final GetEntryFlowStatus _getEntryFlowStatus = GetEntryFlowStatus(
    _appLaunchRepository,
  );
  late final SetEntryFlowStatus _setEntryFlowStatus = SetEntryFlowStatus(
    _appLaunchRepository,
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final connectionState = await _getGmailConnectionState();
    final hasCompletedEntryFlow = await _getEntryFlowStatus();
    await _transactionRepository.seedInitialTransactions();
    await _syncProfile(connectionState: connectionState);
    if (!mounted) return;

    setState(() {
      _gmailConnectionState = connectionState;
      _stage = connectionState.isConnected || hasCompletedEntryFlow
          ? _AppStage.home
          : _AppStage.login;
    });
  }

  Future<void> _syncProfile({GmailConnectionState? connectionState}) {
    return _syncCurrentUserProfile(
      gmailConnected: (connectionState ?? _gmailConnectionState).isConnected,
      themeMode: _themeMode,
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    _syncProfile();
  }

  Future<void> _handleGoogleLogin() async {
    final connectionState = await _connectGmailReadOnly();
    await _transactionRepository.seedInitialTransactions();
    await _setEntryFlowStatus(true);
    await _syncProfile(connectionState: connectionState);
    if (!mounted) return;

    setState(() {
      _gmailConnectionState = connectionState;
      if (connectionState.isConnected) {
        _stage = _AppStage.home;
      }
    });
  }

  Future<void> _continueWithoutGoogle() async {
    await _transactionRepository.seedInitialTransactions();
    await _setEntryFlowStatus(true);
    if (!mounted) return;

    setState(() {
      _stage = _AppStage.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpanseTrackerPro',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      home: switch (_stage) {
        _AppStage.splash => SplashScreen(themeMode: _themeMode),
        _AppStage.login => GoogleLoginScreen(
          themeMode: _themeMode,
          connectionState: _gmailConnectionState,
          onToggleTheme: _toggleTheme,
          onGoogleLogin: _handleGoogleLogin,
          onContinueWithoutGoogle: _continueWithoutGoogle,
        ),
        _AppStage.home => ExpanseTrackerHome(
          themeMode: _themeMode,
          onToggleTheme: _toggleTheme,
          getTransactions: _getTransactions,
          getSmsPermissionStatus: GetSmsPermissionStatus(
            _smsPermissionRepository,
          ),
          requestSmsPermission: RequestSmsPermission(_smsPermissionRepository),
          openSmsPermissionSettings: OpenSmsPermissionSettings(
            _smsPermissionRepository,
          ),
          getGmailConnectionState: _getGmailConnectionState,
          connectGmailReadOnly: _connectGmailReadOnly,
          disconnectGmail: DisconnectGmail(_gmailRepository),
          getRelevantGmailMessages: GetRelevantGmailMessages(_gmailRepository),
        ),
      },
    );
  }
}
