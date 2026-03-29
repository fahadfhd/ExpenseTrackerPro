import 'package:expensetrackerpro/app/app.dart';
import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/entities/sms_permission_state.dart';
import 'package:expensetrackerpro/domain/entities/transaction_item.dart';
import 'package:expensetrackerpro/domain/repositories/app_launch_repository.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';
import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';
import 'package:expensetrackerpro/domain/repositories/transaction_repository.dart';
import 'package:expensetrackerpro/domain/repositories/user_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows splash, login, then app dashboard flows', (
    WidgetTester tester,
  ) async {
    final smsRepository = _FakeSmsPermissionRepository();
    final gmailRepository = _FakeGmailRepository();
    final transactionRepository = _FakeTransactionRepository();
    final userProfileRepository = _FakeUserProfileRepository();
    final appLaunchRepository = _FakeAppLaunchRepository();

    await tester.pumpWidget(
      ExpanseTrackerProApp(
        smsPermissionRepository: smsRepository,
        gmailRepository: gmailRepository,
        transactionRepository: transactionRepository,
        userProfileRepository: userProfileRepository,
        appLaunchRepository: appLaunchRepository,
      ),
    );

    expect(find.text('ExpanseTrackerPro'), findsOneWidget);
    expect(find.text('Welcome to ExpanseTrackerPro'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to ExpanseTrackerPro'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Total spent'), findsOneWidget);
    expect(appLaunchRepository.hasCompleted, isTrue);
  });

  testWidgets('skips login when entry flow was already completed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ExpanseTrackerProApp(
        smsPermissionRepository: _FakeSmsPermissionRepository(),
        gmailRepository: _FakeGmailRepository(),
        transactionRepository: _FakeTransactionRepository(),
        userProfileRepository: _FakeUserProfileRepository(),
        appLaunchRepository: _FakeAppLaunchRepository(initialValue: true),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Total spent'), findsOneWidget);
    expect(find.text('Welcome to ExpanseTrackerPro'), findsNothing);
  });
}

class _FakeSmsPermissionRepository implements SmsPermissionRepository {
  SmsPermissionState _state = SmsPermissionState.denied();

  @override
  Future<SmsPermissionState> getStatus() async => _state;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<SmsPermissionState> requestPermission() async {
    _state = SmsPermissionState.granted();
    return _state;
  }
}

class _FakeGmailRepository implements GmailRepository {
  GmailConnectionState _state = GmailConnectionState.signedOut();

  @override
  Future<GmailConnectionState> connectReadOnly() async {
    _state = GmailConnectionState.connected('user@gmail.com');
    return _state;
  }

  @override
  Future<void> disconnect() async {
    _state = GmailConnectionState.signedOut();
  }

  @override
  Future<GmailConnectionState> getConnectionState() async => _state;

  @override
  Future<List<EmailMessageItem>> getRelevantMessages() async {
    return [
      EmailMessageItem(
        sender: 'alerts@bank.com',
        subject: 'Salary credited',
        snippet: 'Your account has been credited with INR 42,000.',
        dateLabel: '26/03/2026',
        occurredAt: DateTime(2026, 3, 26, 10),
      ),
    ];
  }
}

class _FakeUserProfileRepository implements UserProfileRepository {
  @override
  Future<void> syncCurrentUserProfile({
    required bool gmailConnected,
    required ThemeMode themeMode,
  }) async {}
}

class _FakeAppLaunchRepository implements AppLaunchRepository {
  _FakeAppLaunchRepository({bool initialValue = false})
    : hasCompleted = initialValue;

  bool hasCompleted;

  @override
  Future<bool> hasCompletedEntryFlow() async => hasCompleted;

  @override
  Future<void> setCompletedEntryFlow(bool value) async {
    hasCompleted = value;
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  @override
  Future<void> seedInitialTransactions() async {}

  @override
  Stream<List<TransactionItem>> watchTransactions() => Stream.value([]);

  @override
  Future<void> upsertTransactions(List<TransactionItem> transactions) async {}

  @override
  Future<void> clearTransactions() async {}
}
