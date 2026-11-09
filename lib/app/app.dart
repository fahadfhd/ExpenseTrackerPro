import 'package:kept/app/main_shell.dart';
import 'package:kept/core/firebase/firebase_providers.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/theme/app_theme.dart';
import 'package:kept/features/auth/presentation/welcome_screen.dart';
import 'package:kept/presentation/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KeptApp extends ConsumerWidget {
  const KeptApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark),
      locale: settings.locale,
      // Tap anywhere outside a text field to hide the keyboard. Number
      // keyboards on iPhone have no "Done" key, so this is the only way out.
      // Children that handle taps (buttons, fields) win the gesture, so this
      // only fires for taps on empty space.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// Splash while the persisted Firebase session loads, the welcome screen
/// when there is none, otherwise the app. The shell is keyed by uid so
/// switching accounts rebuilds every user-scoped provider and screen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return switch (auth) {
      AsyncData(value: final user?) => MainShell(key: ValueKey(user.uid)),
      AsyncData() || AsyncError() => const WelcomeScreen(),
      _ => const SplashScreen(),
    };
  }
}
