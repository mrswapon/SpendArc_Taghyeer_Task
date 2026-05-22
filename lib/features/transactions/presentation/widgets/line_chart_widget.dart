import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartWidget extends StatelessWidget {
  final List<double> expenseData;
  final List<double> incomeData;
  final List<String> labels;

  const LineChartWidget({
    super.key,
    required this.expenseData,
    required this.incomeData,
    this.labels = const [],
  });

  static const _expenseBarIndex = 0;
  static const _incomeBarIndex = 1;
  static const _incomeColor = Color(0xFF2E7D32);
  static const _expenseColor = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        );

    final pointCount = _resolvePointCount();
    if (pointCount == 0) {
      return _EmptyChart(labelStyle: labelStyle);
    }

    final normalizedExpense = _normalizeSeries(expenseData, pointCount);
    final normalizedIncome = _normalizeSeries(incomeData, pointCount);
    final normalizedLabels = _normalizeLabels(pointCount);
    final maxY = _computeMaxY(normalizedExpense, normalizedIncome);
    final yInterval = max(maxY / 4, 1.0);
    final isToday = pointCount - 1;
    final hasAnyValue = [...normalizedExpense, ...normalizedIncome]
        .any((value) => value > 0);

    return LineChart(
      _chartData(
        normalizedExpense: normalizedExpense,
        normalizedIncome: normalizedIncome,
        normalizedLabels: normalizedLabels,
        maxY: maxY,
        yInterval: yInterval,
        pointCount: pointCount,
        isToday: isToday,
        hasAnyValue: hasAnyValue,
        labelStyle: labelStyle,
        primary: primary,
      ),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
    );
  }

  LineChartData _chartData({
    required List<double> normalizedExpense,
    required List<double> normalizedIncome,
    required List<String> normalizedLabels,
    required double maxY,
    required double yInterval,
    required int pointCount,
    required int isToday,
    required bool hasAnyValue,
    required TextStyle labelStyle,
    required Color primary,
  }) {
    return LineChartData(
      minX: 0,
      maxX: pointCount <= 1 ? 0 : (pointCount - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      backgroundColor: Colors.transparent,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: value == 0
              ? Colors.grey.shade300
              : Colors.grey.shade200.withValues(alpha: 0.7),
          strokeWidth: value == 0 ? 1.2 : 1,
          dashArray: value == 0 ? null : [6, 6],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value > maxY) {
                return const SizedBox.shrink();
              }
              final text = value >= 1000
                  ? '${(value / 1000).toStringAsFixed(1)}k'
                  : value.toStringAsFixed(0);
              return SideTitleWidget(
                meta: meta,
                child: Text(text, style: labelStyle),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              final index = value.toInt();
              if (index < 0 || index >= normalizedLabels.length) {
                return const SizedBox.shrink();
              }
              final isLastDay = index == isToday;
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  normalizedLabels[index],
                  style: labelStyle.copyWith(
                    color: isLastDay ? primary : Colors.grey.shade500,
                    fontWeight: isLastDay ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchSpotThreshold: 28,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          final color = _colorForBarIndex(_barIndexFromData(barData));
          return spotIndexes.map((_) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: color.withValues(alpha: 0.25),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
              FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: color,
                ),
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBorderRadius: BorderRadius.circular(12),
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          tooltipMargin: 12,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (spot) => _colorForBarIndex(spot.barIndex),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final label =
                  spot.barIndex == _incomeBarIndex ? 'Income' : 'Expense';
              return LineTooltipItem(
                '$label  •  ${spot.y.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.4,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        _buildBarData(
          data: normalizedExpense,
          color: _expenseColor,
          showAreaFill: hasAnyValue,
        ),
        _buildBarData(
          data: normalizedIncome,
          color: _incomeColor,
          showAreaFill: false,
        ),
      ],
    );
  }

  int _barIndexFromData(LineChartBarData barData) {
    final color = barData.color;
    if (color == _incomeColor) return _incomeBarIndex;
    return _expenseBarIndex;
  }

  Color _colorForBarIndex(int barIndex) {
    return barIndex == _incomeBarIndex ? _incomeColor : _expenseColor;
  }

  int _resolvePointCount() {
    return max(
      expenseData.length,
      max(incomeData.length, labels.length),
    );
  }

  List<double> _normalizeSeries(List<double> data, int length) {
    if (data.length == length) return data;
    if (data.length > length) return data.sublist(0, length);
    return [...data, ...List<double>.filled(length - data.length, 0)];
  }

  List<String> _normalizeLabels(int length) {
    if (labels.length >= length) return labels.sublist(0, length);
    return [
      ...labels,
      ...List.generate(
        length - labels.length,
        (i) => 'D${labels.length + i + 1}',
      ),
    ];
  }

  double _computeMaxY(List<double> expense, List<double> income) {
    final allValues = [...expense, ...income];
    if (allValues.isEmpty) return 1;
    final peak = allValues.reduce(max);
    return peak <= 0 ? 1 : peak * 1.2;
  }

  LineChartBarData _buildBarData({
    required List<double> data,
    required Color color,
    required bool showAreaFill,
  }) {
    final spots = _toSpots(data);
    if (spots.isEmpty) {
      return LineChartBarData(
        spots: const [FlSpot(0, 0)],
        show: false,
        color: color,
      );
    }

    return LineChartBarData(
      spots: spots,
      isCurved: spots.length >= 2,
      curveSmoothness: 0.28,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      isStrokeJoinRound: true,
      shadow: Shadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: spot.y > 0 ? 4.5 : 3.5,
          color: Colors.white,
          strokeWidth: 2.5,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: showAreaFill && spots.length >= 2,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _toSpots(List<double> data) {
    return List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final TextStyle labelStyle;

  const _EmptyChart({required this.labelStyle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded,
              size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'No chart data yet',
            style: labelStyle.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
