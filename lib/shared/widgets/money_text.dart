import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MoneyTone { neutral, positive, negative }

/// Formats an amount through the central [CurrencyFormatter]. When signed,
/// the text carries an explicit +/− so meaning never depends on color.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.amountMinor, {
    super.key,
    this.style,
    this.tone = MoneyTone.neutral,
    this.signed = false,
    this.textAlign,
  });

  final int amountMinor;
  final TextStyle? style;
  final MoneyTone tone;

  /// Prefix with + (positive tone) or − (negative tone).
  final bool signed;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(currencyFormatterProvider);
    final colors = context.finance;
    final text = signed && tone != MoneyTone.neutral
        ? formatter.signed(amountMinor, positive: tone == MoneyTone.positive)
        : formatter.format(amountMinor);
    final color = switch (tone) {
      MoneyTone.neutral => null,
      MoneyTone.positive => colors.positive,
      MoneyTone.negative => colors.negative,
    };
    return Text(
      text,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Use for the value side of a label/value [Row]: the amount takes the space
/// left after the label and scales down rather than overflowing (large
/// accessibility text sizes) or being truncated (a cut-off amount misleads).
class FitAmount extends StatelessWidget {
  const FitAmount({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Flexible(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: child,
    ),
  );
}
