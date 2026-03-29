import 'package:expensetrackerpro/domain/entities/gmail_connection_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({
    super.key,
    required this.themeMode,
    required this.connectionState,
    required this.onToggleTheme,
    required this.onGoogleLogin,
    required this.onContinueWithoutGoogle,
  });

  final ThemeMode themeMode;
  final GmailConnectionState connectionState;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onGoogleLogin;
  final VoidCallback onContinueWithoutGoogle;

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_isLoading || widget.connectionState.isUnsupported) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onGoogleLogin();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSkipButton =
        !(defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? const [
                    Color(0xFF0A141B),
                    Color(0xFF101D26),
                    Color(0xFF071015),
                  ]
                : const [
                    Color(0xFFF1F8F2),
                    Color(0xFFFFFFFF),
                    Color(0xFFE7F3EC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton.filledTonal(
                    tooltip: 'Toggle theme',
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      widget.themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0E7C66),
                                    Color(0xFF18A17E),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Welcome to ExpanseTrackerPro',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Use Google login for Gmail read-only access so the app can scan finance emails along with your SMS expense flow.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.connectionState.description,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    _isLoading ||
                                        widget.connectionState.isUnsupported
                                    ? null
                                    : _handleLogin,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: const Text('Continue with Google'),
                              ),
                            ),
                            if (showSkipButton) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: widget.onContinueWithoutGoogle,
                                  child: const Text('Continue without Gmail'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
