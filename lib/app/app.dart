import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:expensetrackerpro/data/repositories/google_gmail_repository.dart';
import 'package:expensetrackerpro/data/repositories/mock_transaction_repository.dart';
import 'package:expensetrackerpro/data/repositories/permission_handler_sms_permission_repository.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';
import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';
import 'package:expensetrackerpro/domain/usecases/connect_gmail_readonly.dart';
import 'package:expensetrackerpro/domain/usecases/disconnect_gmail.dart';
import 'package:expensetrackerpro/domain/usecases/get_gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/usecases/get_relevant_gmail_messages.dart';
import 'package:expensetrackerpro/domain/usecases/get_sms_permission_status.dart';
import 'package:expensetrackerpro/domain/usecases/get_transactions.dart';
import 'package:expensetrackerpro/domain/usecases/open_sms_permission_settings.dart';
import 'package:expensetrackerpro/domain/usecases/request_sms_permission.dart';
import 'package:expensetrackerpro/presentation/home/expanse_tracker_home.dart';
import 'package:flutter/material.dart';

class ExpanseTrackerProApp extends StatefulWidget {
  const ExpanseTrackerProApp({
    super.key,
    this.smsPermissionRepository,
    this.gmailRepository,
  });

  final SmsPermissionRepository? smsPermissionRepository;
  final GmailRepository? gmailRepository;

  @override
  State<ExpanseTrackerProApp> createState() => _ExpanseTrackerProAppState();
}

class _ExpanseTrackerProAppState extends State<ExpanseTrackerProApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  final GetTransactions _getTransactions = GetTransactions(
    const MockTransactionRepository(),
  );
  late final SmsPermissionRepository _smsPermissionRepository =
      widget.smsPermissionRepository ??
      const PermissionHandlerSmsPermissionRepository();
  late final GmailRepository _gmailRepository =
      widget.gmailRepository ?? GoogleGmailRepository();

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
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
      home: ExpanseTrackerHome(
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
        getGmailConnectionState: GetGmailConnectionState(_gmailRepository),
        connectGmailReadOnly: ConnectGmailReadOnly(_gmailRepository),
        disconnectGmail: DisconnectGmail(_gmailRepository),
        getRelevantGmailMessages: GetRelevantGmailMessages(_gmailRepository),
      ),
    );
  }
}
