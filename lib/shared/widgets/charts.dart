import 'dart:math' as math;

import 'package:expensetrackerpro/core/money/currency_formatter.dart';
import 'package:expensetrackerpro/core/settings/app_settings.dart';
import 'package:expensetrackerpro/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chart widgets receive already-aggregated values (computed once in
/// providers) and only lay them out. Conventions: one value axis, thin
/// rounded marks, recessive grid, tooltips on touch, a legend for two
/// series, and a semantics summary so screen readers get the numbers.

class BarItem {
  const BarItem({
    required this.label,
    required this.valueMinor,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String label;
  final int valueMinor;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
}

/// Ranked horizontal bars with labels and values written out. Single hue:
/// the job is magnitude, so color does not encode identity.
class RankedBars extends ConsumerWidget {
  const RankedBars({super.key, required this.items, this.maxItems = 6, this.otherLabel});

  final List<BarItem> items;
  final int maxItems;

  /// Label for the folded remainder when there are more than [maxItems].
  final String? otherLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final money = ref.watch(currencyFormatterProvider);
    final color = context.finance.series1;
    var shown = items;
    if (items.length > maxItems && otherLabel != null) {
      final rest = items.skip(maxItems - 1).fold<int>(0, (s, i) => s + i.valueMinor);
      shown = [
        ...items.take(maxItems - 1),
        BarItem(label: otherLabel!, valueMinor: rest, icon: Icons.more_horiz_rounded),
      ];
    }
    final max = shown.fold<int>(0, (m, i) => math.max(m, i.valueMinor));
    final total = shown.fold<int>(0, (s, i) => s + i.valueMinor);

    return Column(
      children: [
        for (final item in shown)
          Semantics(
            button: item.onTap != null,
            label: '${item.label}, ${money.format(item.valueMinor)}',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 20, color: item.iconColor ?? theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Flexible so large text wraps instead of
                              // overflowing the row.
                              Flexible(
                                child: Text.rich(
                                  TextSpan(
                                    text: money.format(item.valueMinor),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                    children: [
                                      if (total != 0)
                                        TextSpan(
                                          text: '  ${(item.valueMinor * 100 / total).round()}%',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: max == 0 ? 0 : item.valueMinor / max,
                              minHeight: 8,
                              color: color,
                              backgroundColor: context.finance.track,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

FlGridData _grid(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    strokeWidth: 1,
  ),
);

AxisTitles _moneyAxis(BuildContext context, CurrencyFormatter money) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 48,
    getTitlesWidget: (value, meta) {
      if (value == meta.max && value != 0) return const SizedBox.shrink();
      return SideTitleWidget(
        meta: meta,
        child: Text(
          money.compact(value.round()),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    },
  ),
);

const _hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

Color _tooltipColor(BuildContext context) =>
    Theme.of(context).colorScheme.inverseSurface;

TextStyle _tooltipStyle(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.onInverseSurface,
  fontWeight: FontWeight.w700,
  fontSize: 12,
);

/// Spending per day of a month.
class DailyBarChart extends ConsumerWidget {
  const DailyBarChart({
    super.key,
    required this.byDay,
    required this.daysInMonth,
    required this.semanticsLabel,
  });

  final Map<int, int> byDay;
  final int daysInMonth;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(currencyFormatterProvider);
    final color = context.finance.series1;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            gridData: _grid(context),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: _moneyAxis(context, money),
              rightTitles: _hidden,
              topTitles: _hidden,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final day = value.toInt();
                    if (day != 1 && day % 5 != 0) return const SizedBox.shrink();
                    return SideTitleWidget(meta: meta, child: Text('$day', style: labelStyle));
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => _tooltipColor(context),
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  '${group.x}: ${money.format(rod.toY.round())}',
                  _tooltipStyle(context),
                ),
              ),
            ),
            barGroups: [
              for (var d = 1; d <= daysInMonth; d++)
                BarChartGroupData(
                  x: d,
                  barRods: [
                    BarChartRodData(
                      toY: (byDay[d] ?? 0).toDouble(),
                      width: 6,
                      color: color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthBar {
  const MonthBar({required this.label, required this.a, this.b});
  final String label;
  final int a;
  final int? b;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

/// Bars per month; one series, or two grouped series with a legend.
class MonthlyBarChart extends ConsumerWidget {
  const MonthlyBarChart({
    super.key,
    required this.months,
    required this.aLabel,
    this.bLabel,
    required this.semanticsLabel,
  });

  final List<MonthBar> months;
  final String aLabel;
  final String? bLabel;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(currencyFormatterProvider);
    final colors = context.finance;
    final twoSeries = bLabel != null;
    // Series 1 (blue) = a, series 2 (orange) = b.
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (twoSeries) ...[
            Wrap(
              spacing: 16,
              children: [_LegendDot(colors.series1, aLabel), _LegendDot(colors.series2, bLabel!)],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                gridData: _grid(context),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: _moneyAxis(context, money),
                  rightTitles: _hidden,
                  topTitles: _hidden,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= months.length) return const SizedBox.shrink();
                        return SideTitleWidget(meta: meta, child: Text(months[i].label, style: labelStyle));
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => _tooltipColor(context),
                    getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                      '${rodIndex == 0 ? aLabel : bLabel}\n${money.format(rod.toY.round())}',
                      _tooltipStyle(context),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < months.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: months[i].a.toDouble(),
                          width: twoSeries ? 9 : 16,
                          color: colors.series1,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        if (twoSeries)
                          BarChartRodData(
                            toY: (months[i].b ?? 0).toDouble(),
                            width: 9,
                            color: colors.series2,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-series trend line over months.
class TrendLineChart extends ConsumerWidget {
  const TrendLineChart({
    super.key,
    required this.labels,
    required this.values,
    required this.semanticsLabel,
  });

  final List<String> labels;
  final List<int> values;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(currencyFormatterProvider);
    final color = context.finance.series1;
    final surface = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            gridData: _grid(context),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: _moneyAxis(context, money),
              rightTitles: _hidden,
              topTitles: _hidden,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length || value != i) return const SizedBox.shrink();
                    return SideTitleWidget(meta: meta, child: Text(labels[i], style: labelStyle));
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => _tooltipColor(context),
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${labels[s.x.toInt()]}: ${money.format(s.y.round())}',
                      _tooltipStyle(context),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i].toDouble()),
                ],
                color: color,
                barWidth: 2,
                isCurved: false,
                dotData: FlDotData(
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-part stacked bar (e.g. principal vs interest) with a legend and
/// written values.
class SplitBar extends ConsumerWidget {
  const SplitBar({
    super.key,
    required this.aLabel,
    required this.aMinor,
    required this.bLabel,
    required this.bMinor,
  });

  final String aLabel;
  final int aMinor;
  final String bLabel;
  final int bMinor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(currencyFormatterProvider);
    final colors = context.finance;
    final total = aMinor + bMinor;
    final aFlex = total == 0 ? 1 : math.max(1, (aMinor * 1000 / total).round());
    final bFlex = total == 0 ? 1 : math.max(1, (bMinor * 1000 / total).round());
    final surface = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return Semantics(
      label: '$aLabel ${money.format(aMinor)}, $bLabel ${money.format(bMinor)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: aFlex, child: ColoredBox(color: colors.series1)),
                  // 2px surface gap between segments.
                  SizedBox(width: 2, child: ColoredBox(color: surface)),
                  Expanded(flex: bFlex, child: ColoredBox(color: colors.series2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LegendDot(colors.series1, '$aLabel · ${money.format(aMinor)}'),
              _LegendDot(colors.series2, '$bLabel · ${money.format(bMinor)}'),
            ],
          ),
        ],
      ),
    );
  }
}
