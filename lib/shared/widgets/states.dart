import 'package:expensetrackerpro/core/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String? title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: compact ? 20 : 48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 48 : 72,
            height: compact ? 48 : 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(compact ? 16 : 24),
            ),
            child: Icon(
              icon,
              size: compact ? 24 : 34,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: l10n.somethingWentWrong,
      // Never the raw error: only a mapped, user-safe message.
      message: l10n.failure(error),
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
    );
  }
}

/// Grey placeholder shapes shown while the first snapshot loads.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loading,
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Skeleton(height: 64, radius: 20),
            ),
        ],
      ),
    );
  }
}

/// Renders loading / error / data for an [AsyncValue] consistently.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => data(value),
      AsyncError(:final error) when !value.hasValue => ErrorState(
        error: error,
        onRetry: onRetry,
      ),
      _ when value.hasValue => data(value.requireValue),
      _ => loading ?? const SkeletonList(),
    };
  }
}
