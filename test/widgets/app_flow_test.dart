import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('signed-out users see the welcome screen and can continue as guest', (tester) async {
    final env = await pumpApp(tester, signedIn: false);
    expect(find.text('Welcome to ExpanseTrackerPro'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tapText(tester, 'Continue without an account');
    expect(env.auth.currentUser, isNotNull);
    expect(find.text('Welcome to ExpanseTrackerPro'), findsNothing);
    expect(find.textContaining('Spent in'), findsOneWidget);
  });

  testWidgets('dashboard shows onboarding for a new user', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Spent in'), findsOneWidget);
    expect(find.text("Welcome! Let's set things up"), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
  });
}
