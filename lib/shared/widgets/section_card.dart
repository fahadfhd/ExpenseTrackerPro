import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Two-column grid whose rows grow with their content, so tiles stay
/// readable at large text sizes (a fixed-aspect GridView would clip them).
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < children.length ? spacing : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[i]),
                  SizedBox(width: spacing),
                  Expanded(
                    child: i + 1 < children.length
                        ? children[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Small label/value tile used in KPI grids.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final Widget value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DefaultTextStyle.merge(
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                child: value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal progress bar with an accessible description. Past
/// [warnAt]/[alertAt] it changes color *and* shows an icon.
class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    super.key,
    required this.ratio,
    required this.semanticsLabel,
    this.warnAt = 0.75,
    this.alertAt = 1.0,
    this.height = 10,
    this.color,
  });

  final double ratio;
  final String semanticsLabel;
  final double warnAt;
  final double alertAt;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.finance;
    final level = ratio >= alertAt
        ? finance.negative
        : ratio >= warnAt
        ? finance.warning
        : (color ?? theme.colorScheme.primary);
    return Semantics(
      label: semanticsLabel,
      value: '${(ratio * 100).round()}%',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1).toDouble(),
                minHeight: height,
                color: level,
                backgroundColor: finance.track,
              ),
            ),
          ),
          if (ratio >= warnAt) ...[
            const SizedBox(width: 6),
            Icon(
              ratio >= alertAt
                  ? Icons.error_rounded
                  : Icons.warning_amber_rounded,
              size: 18,
              color: level,
            ),
          ],
        ],
      ),
    );
  }
}
