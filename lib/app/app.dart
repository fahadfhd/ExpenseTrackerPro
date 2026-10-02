import 'package:expensetrackerpro/app/main_shell.dart';
import 'package:expensetrackerpro/core/firebase/firebase_providers.dart';
import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:expensetrackerpro/features/auth/presentation/welcome_screen.dart';
import 'package:expensetrackerpro/presentation/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpanseTrackerProApp extends ConsumerWidget {
  const ExpanseTrackerProApp({super.key});

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
