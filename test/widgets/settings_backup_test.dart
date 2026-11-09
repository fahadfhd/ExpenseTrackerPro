import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'a guest sees a clear "Connect backup" option at the top of Settings',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      expect(find.text('Back up your data'), findsOneWidget);
      expect(find.text('Connect backup'), findsOneWidget);
      expect(find.text('Back up now'), findsNothing);
    },
  );

  testWidgets('a Google-connected account sees backup status and Back up now', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'g1', email: 'me@example.com'),
      ),
    );
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    expect(find.text('Backup connected'), findsOneWidget);
    expect(find.textContaining('me@example.com'), findsWidgets);
    expect(find.textContaining('No backup yet'), findsOneWidget);
    expect(find.text('Back up now'), findsWidgets);
    expect(find.text('Connect backup'), findsNothing);
  });
}
