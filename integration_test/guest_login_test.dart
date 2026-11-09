import 'package:kept/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end check against the real Firebase project: a new user can
/// start without an account and reach the dashboard.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest can sign in and reach the dashboard', (tester) async {
    await app.main();
    // Wait for the welcome screen (or an existing session).
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('Continue without an account').evaluate().isNotEmpty ||
          find.textContaining('Spent in').evaluate().isNotEmpty) {
        break;
      }
    }
    if (find.text('Continue without an account').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue without an account'));
    }
    String? outcome;
    for (var i = 0; i < 120 && outcome == null; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.textContaining('Spent in').evaluate().isNotEmpty) {
        outcome = 'dashboard';
      } else if (find
          .textContaining('Guest access is turned off')
          .evaluate()
          .isNotEmpty) {
        outcome = 'guest-disabled';
      } else if (find.textContaining("You're offline").evaluate().isNotEmpty) {
        outcome = 'offline';
      } else if (find
          .textContaining("Sign-in didn't complete")
          .evaluate()
          .isNotEmpty) {
        outcome = 'failed';
      }
    }
    debugPrint('GUEST LOGIN OUTCOME: ${outcome ?? 'timeout'}');
    // Give Firestore a moment, then report any permission problem on screen.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    debugPrint(
      'PERMISSION ERROR VISIBLE: ${find.textContaining("don't have permission").evaluate().isNotEmpty}',
    );
    expect(outcome, 'dashboard');
  });
}
