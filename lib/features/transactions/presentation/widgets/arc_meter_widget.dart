import 'dart:math';
import 'package:flutter/material.dart';

class ArcMeterWidget extends StatefulWidget {
  final double percentage; // 0.0 – 1.0
  final double spent;
  final double budget;
  final String currency;

  const ArcMeterWidget({
    super.key,
    required this.percentage,
    required this.spent,
    required this.budget,
    this.currency = 'USD',
  });

  @override
  State<ArcMeterWidget> createState() => _ArcMeterWidgetState();
}

class _ArcMeterWidgetState extends State<ArcMeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ArcMeterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
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
    final pct = (widget.percentage * 100).clamp(0, 100).toStringAsFixed(1);
    return Semantics(
      label: 'Budget usage: $pct percent of ${widget.currency} ${widget.budget.toStringAsFixed(0)}',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final animatedPct = widget.percentage * _animation.value;
          return SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _ArcMeterPainter(
                percentage: animatedPct,
                trackColor: Colors.grey.shade200,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(animatedPct * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _arcColor(animatedPct),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ${widget.currency} ${widget.budget.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _arcColor(double pct) {
    if (pct < 0.5) return const Color(0xFF4CAF50);
    if (pct < 0.8) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

class _ArcMeterPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;

  const _ArcMeterPainter({
    required this.percentage,
    required this.trackColor,
  });

  static const double _startAngle = 2.356; // 135°
  static const double _sweepMax = 4.712;   // 270°
  static const double _strokeWidth = 18.0;

  Color get _progressColor {
    if (percentage < 0.5) return const Color(0xFF4CAF50);
    if (percentage < 0.8) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - _strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepMax, false, trackPaint);

    // Progress arc.
    if (percentage > 0) {
      final progressPaint = Paint()
        ..color = _progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          rect, _startAngle, _sweepMax * percentage, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcMeterPainter old) => old.percentage != percentage;
}
