import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

class LineChartWidget extends StatefulWidget {
  final List<double> data; // 7 values, one per day (oldest → newest)
  final List<String> labels;

  const LineChartWidget({
    super.key,
    required this.data,
    this.labels = const [],
  });

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(LineChartWidget old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.data, widget.data)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) => CustomPaint(
        painter: _LineChartPainter(
          data: widget.data,
          labels: widget.labels,
          progress: _progress.value,
          lineColor: Theme.of(context).colorScheme.primary,
          gridColor: Colors.grey.shade200,
          labelStyle: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey) ??
              const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double progress; // 0.0 → 1.0
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  const _LineChartPainter({
    required this.data,
    required this.labels,
    required this.progress,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  static const _padL = 48.0;
  static const _padR = 16.0;
  static const _padT = 16.0;
  static const _padB = 36.0;
  static const _dotRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartRect = Rect.fromLTRB(
      _padL,
      _padT,
      size.width - _padR,
      size.height - _padB,
    );

    final maxVal = data.reduce(max) * 1.15;
    final minVal = 0.0;
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    double xOf(int i) =>
        chartRect.left + i / (data.length - 1) * chartRect.width;
    double yOf(double v) =>
        chartRect.bottom - (v - minVal) / range * chartRect.height;

    _drawGrid(canvas, chartRect, maxVal, range);
    _drawAxes(canvas, chartRect);
    _drawLine(canvas, chartRect, xOf, yOf);
    _drawDots(canvas, chartRect, xOf, yOf);
    _drawLabels(canvas, size, chartRect, xOf);
  }

  void _drawGrid(Canvas canvas, Rect r, double maxVal, double range) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = r.bottom - (i / steps) * r.height;
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), paint);

      // Y-axis labels.
      final val = (maxVal * i / steps);
      _paintText(
        canvas,
        val >= 1000 ? '${(val / 1000).toStringAsFixed(1)}k' : val.toStringAsFixed(0),
        Offset(r.left - 4, y),
        align: TextAlign.right,
      );
    }
  }

  void _drawAxes(Canvas canvas, Rect r) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left, r.bottom), paint);
    canvas.drawLine(
        Offset(r.left, r.bottom), Offset(r.right, r.bottom), paint);
  }

  void _drawLine(
      Canvas canvas, Rect r, double Function(int) xOf, double Function(double) yOf) {
    if (data.length < 2) return;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(r);

    final linePath = Path();
    final fillPath = Path();

    final totalSegments = data.length - 1;
    final progressPts = progress * totalSegments;

    linePath.moveTo(xOf(0), yOf(data[0]));
    fillPath.moveTo(xOf(0), r.bottom);
    fillPath.lineTo(xOf(0), yOf(data[0]));

    for (int i = 1; i < data.length; i++) {
      if (i - 1 >= progressPts) break;

      final t = (progressPts - (i - 1)).clamp(0.0, 1.0);
      final x = lerpDouble(xOf(i - 1), xOf(i), t)!;
      final y = lerpDouble(yOf(data[i - 1]), yOf(data[i]), t)!;

      linePath.lineTo(x, y);
      fillPath.lineTo(x, y);

      if (t < 1.0) break;
    }

    fillPath.lineTo(linePath.getBounds().right, r.bottom);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  void _drawDots(
      Canvas canvas, Rect r, double Function(int) xOf, double Function(double) yOf) {
    final totalSegments = data.length - 1;
    final progressPts = progress * totalSegments;

    final dotPaint = Paint()..color = lineColor;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      if (i > progressPts + 0.5) break;
      final center = Offset(xOf(i), yOf(data[i]));
      canvas.drawCircle(center, _dotRadius + 2, whitePaint);
      canvas.drawCircle(center, _dotRadius, dotPaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, Rect r, double Function(int) xOf) {
    for (int i = 0; i < data.length; i++) {
      final label = i < labels.length ? labels[i] : 'D${i + 1}';
      _paintText(
        canvas,
        label,
        Offset(xOf(i), r.bottom + 6),
        align: TextAlign.center,
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset position,
      {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final dx = align == TextAlign.right
        ? position.dx - tp.width
        : align == TextAlign.center
            ? position.dx - tp.width / 2
            : position.dx;

    tp.paint(canvas, Offset(dx, position.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.progress != progress || !listEquals(old.data, data);
}
