import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// Signed-out auth whose guest sign-in can be delayed or made to fail, the
/// way it behaves on a real network / misconfigured project.
class _GuestAuth extends MockFirebaseAuth {
  _GuestAuth({this.error}) : super(signedIn: false);

  final FirebaseAuthException? error;
  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<UserCredential> signInAnonymously() async {
    calls++;
    await gate.future;
    if (error != null) throw error!;
    return super.signInAnonymously();
  }
}

Finder _guestButton() =>
    find.widgetWithText(OutlinedButton, 'Continue without an account');

void main() {
  testWidgets(
    'guest sign-in shows progress, ignores double taps, then opens the app',
    (tester) async {
      final auth = _GuestAuth();
      await pumpApp(tester, auth: auth);
      await reveal(tester, _guestButton());
      await tester.tap(_guestButton());
      await tester.pump();
      // Visible feedback while the network call runs.
      expect(find.text('Signing you in…'), findsOneWidget);
      await tester.tap(find.text('Signing you in…'), warnIfMissed: false);
      await tester.pump();
      expect(
        auth.calls,
        1,
        reason: 'a second tap must not start another sign-in',
      );

      auth.gate.complete();
      await settle(tester);
      expect(find.textContaining('Spent in'), findsOneWidget);
    },
  );

  testWidgets('disabled guest mode explains itself and steers to Google', (
    tester,
  ) async {
    final auth = _GuestAuth(
      error: FirebaseAuthException(code: 'admin-restricted-operation'),
    )..gate.complete();
    await pumpApp(tester, auth: auth);
    await reveal(tester, _guestButton());
    await tester.tap(_guestButton());
    await settle(tester);
    expect(
      find.text(
        'Guest access is turned off for this app right now. Please continue with Google.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('enable Anonymous sign-in'),
      findsOneWidget,
      reason: 'debug builds show the fix',
    );
    expect(_guestButton(), findsNothing, reason: 'retrying can never work');
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets(
    'offline first launch shows an actionable message and allows retry',
    (tester) async {
      final auth = _GuestAuth(
        error: FirebaseAuthException(code: 'network-request-failed'),
      )..gate.complete();
      await pumpApp(tester, auth: auth);
      await reveal(tester, _guestButton());
      await tester.tap(_guestButton());
      await settle(tester);
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(_guestButton(), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(_guestButton()).onPressed,
        isNotNull,
      );
    },
  );

  for (final (name, scale, size, dpr, theme) in [
    ('2x text', 2.0, const Size(1170, 2532), 3.0, ThemeMode.light),
    ('small phone, dark', 1.0, const Size(640, 1136), 2.0, ThemeMode.dark),
    ('landscape', 1.0, const Size(2532, 1170), 3.0, ThemeMode.light),
  ]) {
    testWidgets('welcome layout has no overflow: $name', (tester) async {
      final errors = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (d) =>
          errors.add(d.exceptionAsString().split('\n').first);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      try {
        await pumpApp(
          tester,
          signedIn: false,
          themeMode: theme,
          physicalSize: size,
          devicePixelRatio: dpr,
        );
        await reveal(tester, _guestButton());
      } finally {
        FlutterError.onError = original;
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      }
      expect(errors, isEmpty);
    });
  }
}
