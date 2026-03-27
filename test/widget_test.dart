import 'package:expensetrackerpro/app/app.dart';
import 'package:expensetrackerpro/domain/entities/email_message_item.dart';
import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:expensetrackerpro/domain/entities/sms_permission_state.dart';
import 'package:expensetrackerpro/domain/repositories/gmail_repository.dart';
import 'package:expensetrackerpro/domain/repositories/sms_permission_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders SMS and Gmail access flows', (
    WidgetTester tester,
  ) async {
    final smsRepository = _FakeSmsPermissionRepository();
    final gmailRepository = _FakeGmailRepository();

    await tester.pumpWidget(
      ExpanseTrackerProApp(
        smsPermissionRepository: smsRepository,
        gmailRepository: gmailRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ExpanseTrackerPro'), findsOneWidget);
    expect(find.text('Total spent'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(find.text('Allow SMS access'), findsOneWidget);
    await tester.tap(find.text('Allow SMS access'));
    await tester.pumpAndSettle();
    expect(find.text('SMS access enabled'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -320));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect Gmail').last);
    await tester.pumpAndSettle();
    expect(find.text('Gmail connected'), findsOneWidget);

    await tester.tap(find.text('Scan finance emails'));
    await tester.pumpAndSettle();
    expect(find.text('Salary credited'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
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
    return const [
      EmailMessageItem(
        sender: 'alerts@bank.com',
        subject: 'Salary credited',
        snippet: 'Your account has been credited with INR 42,000.',
        dateLabel: '26/03/2026',
      ),
    ];
  }
}
