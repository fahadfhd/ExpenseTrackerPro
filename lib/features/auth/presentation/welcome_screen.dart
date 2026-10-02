import 'package:expensetrackerpro/app/app_providers.dart';
import 'package:expensetrackerpro/core/errors/app_failure.dart';
import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:expensetrackerpro/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First-run screen: sign in with Google or continue as a guest. Either way
/// the user gets a private Firebase identity that isolates their data.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(
        () => _error = AppFailure.from(e).kind == FailureKind.network
            ? l10n.firstLaunchOffline
            : l10n.signInFailed,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.read(authRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [Color(0xFF0E7C66), Color(0xFF18A17E)]),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.welcomeBody,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.welcomePrivacy, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                        ],
                      ),
                    ),
                  if (GoogleSignInBootstrap.isSupported)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: _loading ? null : () => _run(auth.linkGoogle),
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.login_rounded),
                      label: Text(l10n.continueWithGoogle),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: _loading ? null : () => _run(auth.continueAsGuest),
                    child: Text(l10n.continueAsGuest),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.guestNote, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
