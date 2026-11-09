import 'package:kept/app/app_providers.dart';
import 'package:kept/core/errors/app_failure.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/features/auth/data/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/shared/widgets/language_button.dart';

enum _Busy { none, google, guest }

/// First-run screen: sign in with Google or continue as a guest. Either way
/// the user gets a private Firebase identity that isolates their data.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  _Busy _busy = _Busy.none;
  String? _error;
  String? _errorDetail;
  bool _guestDisabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Respect the OS "reduce motion" setting.
      if (MediaQuery.disableAnimationsOf(context)) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _signIn(_Busy which) async {
    if (_busy != _Busy.none) return; // ignore double taps
    final l10n = context.l10n;
    final auth = ref.read(authRepositoryProvider);
    setState(() {
      _busy = which;
      _error = null;
      _errorDetail = null;
    });
    try {
      if (which == _Busy.google) {
        final result = await auth.linkGoogle();
        if (result == GoogleLinkResult.cancelled && mounted) {
          setState(() => _error = l10n.signInCancelled);
        }
      } else {
        await auth.continueAsGuest();
      }
      // On success AuthGate replaces this screen; nothing else to do.
    } catch (e) {
      debugPrint('Sign-in failed: ${AppFailure.from(e)}');
      if (!mounted) return;
      final kind = AppFailure.from(e).kind;
      setState(() {
        if (kind == FailureKind.network) {
          _error = l10n.firstLaunchOffline;
        } else if (which == _Busy.guest &&
            kind == FailureKind.signInMethodDisabled) {
          // Retrying can never work; steer the user to Google instead.
          _guestDisabled = true;
          _error = l10n.guestUnavailable;
          _errorDetail = kDebugMode ? l10n.guestUnavailableDev : null;
        } else {
          _error = l10n.signInFailed;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  /// Fade + slight upward slide, staggered by [start] (0–1).
  Widget _reveal(double start, Widget child) {
    final curve = CurvedAnimation(
      parent: _intro,
      curve: Interval(
        start,
        (start + 0.5).clamp(0, 1),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final googleSupported = GoogleSignInBootstrap.isSupported;

    // Light status-bar icons on the dark brand backdrop.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF062A24),
        body: Stack(
          children: [
            const Positioned.fill(child: _Backdrop()),
            SafeArea(
              // The sign-in panel runs to the bottom edge and pads itself.
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(24, 8, 16, 0),
                                child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: LanguageButton(onDark: true),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  4,
                                ),
                                child: _reveal(0, _Hero(l10n: l10n)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _reveal(
                                  0.2,
                                  _FeatureGrid(
                                    features: [
                                      (
                                        Icons.account_balance_wallet_rounded,
                                        l10n.welcomeFeatureTrack,
                                      ),
                                      (
                                        Icons.notifications_active_rounded,
                                        l10n.welcomeFeatureDues,
                                      ),
                                      (
                                        Icons.insights_rounded,
                                        l10n.welcomeFeatureLoans,
                                      ),
                                      (
                                        Icons.shield_rounded,
                                        l10n.welcomeFeaturePrivate,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 20),
                              _reveal(
                                0.45,
                                _SignInPanel(
                                  busy: _busy,
                                  googleSupported: googleSupported,
                                  guestDisabled: _guestDisabled,
                                  error: _error,
                                  errorDetail: _errorDetail,
                                  onGoogle: () => _signIn(_Busy.google),
                                  onGuest: () => _signIn(_Busy.guest),
                                  theme: theme,
                                  bottomInset: MediaQuery.viewPaddingOf(
                                    context,
                                  ).bottom,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brand gradient with two soft light blooms.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    Widget bloom(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B3D33), Color(0xFF0E7C66), Color(0xFF062A24)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: bloom(const Color(0x5534D399), 320),
            ),
            Positioned(
              top: 220,
              left: -140,
              child: bloom(const Color(0x332DD4BF), 300),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                l10n.appTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          child: Text(
            l10n.welcomeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.welcomeBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Four value points as a compact 2×2 grid, so both sign-in buttons fit on
/// screen without scrolling on a typical phone.
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<(IconData, String)> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile((IconData, String) f) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f.$1, color: const Color(0xFFA7F3D0), size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            f.$2,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < features.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < features.length ? 10 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(features[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < features.length
                        ? tile(features[i + 1])
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SignInPanel extends StatelessWidget {
  const _SignInPanel({
    required this.busy,
    required this.googleSupported,
    required this.guestDisabled,
    required this.error,
    required this.errorDetail,
    required this.onGoogle,
    required this.onGuest,
    required this.theme,
    required this.bottomInset,
  });

  final _Busy busy;
  final bool googleSupported;
  final bool guestDisabled;
  final String? error;
  final String? errorDetail;
  final VoidCallback onGoogle;
  final VoidCallback onGuest;
  final ThemeData theme;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final locked = busy != _Busy.none;
    final panelColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0F1A21)
        : Colors.white;

    Widget spinner(Color color) => SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
    );

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 22, 20, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            // The buttons below stay available, so trying again is one tap.
            _ErrorCard(message: error!, detail: errorDetail),
            const SizedBox(height: 16),
          ],
          if (googleSupported) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: locked ? null : onGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy == _Busy.google)
                    spinner(scheme.onPrimary)
                  else
                    const _GoogleMark(),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      busy == _Busy.google
                          ? l10n.signingIn
                          : l10n.continueWithGoogle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.googleNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!guestDisabled) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(color: scheme.outline),
              ),
              onPressed: locked ? null : onGuest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy == _Busy.guest)
                    spinner(scheme.primary)
                  else
                    Icon(Icons.person_outline_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      busy == _Busy.guest
                          ? l10n.signingIn
                          : l10n.continueAsGuest,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.guestNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.welcomePrivacy,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A neutral "G" badge for the Google button (no bundled brand asset).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            height: 1,
          ),
        ),
      ),
    );
  }
}
