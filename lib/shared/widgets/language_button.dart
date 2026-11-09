import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kept/core/l10n/l10n.dart';
import 'package:kept/core/settings/app_settings.dart';
import 'package:kept/core/utils/haptics.dart';

/// Compact language switcher. It lives on the welcome screen so people can
/// choose their language before they sign in; Settings has the full picker
/// (which also offers "Device language").
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key, this.onDark = false});

  /// Light-on-dark styling for the brand backdrop.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final current = ref.watch(appLocaleProvider).languageCode;
    final foreground = onDark ? Colors.white : scheme.onSurface;
    final background = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : scheme.surfaceContainerHighest;

    return PopupMenuButton<String>(
      tooltip: context.l10n.settingsLanguage,
      initialValue: current,
      position: PopupMenuPosition.under,
      onSelected: (code) {
        Haptics.selection();
        ref.read(settingsProvider.notifier).setLocale(code);
      },
      itemBuilder: (context) => [
        for (final locale in AppLocalizations.supportedLocales)
          PopupMenuItem<String>(
            value: locale.languageCode,
            child: Text(languageNativeName(locale.languageCode)),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.translate_rounded, size: 18, color: foreground),
            const SizedBox(width: 6),
            Text(
              languageNativeName(current),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: foreground),
          ],
        ),
      ),
    );
  }
}
