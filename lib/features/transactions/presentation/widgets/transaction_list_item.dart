import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';

// ---------------------------------------------------------------------------
// Particle data — immutable, safe to pass between build calls.
// ---------------------------------------------------------------------------
class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset origin;
  final double progress; // 0.0 → 1.0

  const _ParticlePainter({
    required this.particles,
    required this.origin,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final dist = p.speed * progress * 90;
      final x = origin.dx + cos(p.angle) * dist;
      final y = origin.dy + sin(p.angle) * dist;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final radius = p.size * (1.0 - progress * 0.4);

      paint.color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------
class TransactionListItem extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem>
    with TickerProviderStateMixin {
  // Swipe controller — unbounded so it can hold raw pixel offsets.
  late final AnimationController _swipe;
  // Particle burst controller.
  late final AnimationController _burst;

  late final List<_Particle> _particles;
  bool _deleted = false;

  static const double _deleteThreshold = 100.0;
  static const _spring = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 28.0,
  );
  static const _deleteSpring = SpringDescription(
    mass: 1.0,
    stiffness: 400.0,
    damping: 18.0,
  );

  static final _rng = Random();
  static const _particleColors = [
    Color(0xFFE53935),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFFFF5722),
  ];

  @override
  void initState() {
    super.initState();
    _swipe = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() {}));

    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() => setState(() {}));

    // Pre-generate 12 particles.
    _particles = List.generate(12, (i) {
      return _Particle(
        angle: (i / 12) * 2 * pi + _rng.nextDouble() * 0.4,
        speed: 0.7 + _rng.nextDouble() * 0.6,
        color: _particleColors[i % _particleColors.length],
        size: 4.0 + _rng.nextDouble() * 4.0,
      );
    });
  }

  @override
  void dispose() {
    _swipe.dispose();
    _burst.dispose();
    super.dispose();
  }

  // ----- Gesture handlers -----

  void _onDragUpdate(DragUpdateDetails d) {
    if (_deleted) return;
    // Only allow leftward swipe.
    _swipe.value = (_swipe.value + d.delta.dx).clamp(
      double.negativeInfinity,
      0.0,
    );
  }

  void _onDragEnd(DragEndDetails d) {
    if (_deleted) return;
    final velocity = d.primaryVelocity ?? 0;

    if (_swipe.value < -_deleteThreshold || velocity < -1200) {
      _triggerDelete();
    } else {
      // Spring snap back.
      _swipe.animateWith(
        SpringSimulation(_spring, _swipe.value, 0.0, velocity),
      );
    }
  }

  void _triggerDelete() {
    _deleted = true;
    // Particle burst.
    _burst.forward(from: 0);

    // Spring fly out to the left edge.
    _swipe
        .animateWith(
          SpringSimulation(_deleteSpring, _swipe.value, -600.0, -200.0),
        )
        .then((_) => widget.onDelete?.call());
  }

  // ----- Build -----

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isExpense = t.type == TransactionType.expense;
    final amountStr =
        '${isExpense ? '-' : '+'}\$${t.amount.toStringAsFixed(2)}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Delete hint shown as item slides away.
        if (_swipe.value < -20)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 28),
            ),
          ),

        // Swipeable card.
        Transform.translate(
          offset: Offset(_swipe.value, 0),
          child: GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _CategoryIcon(category: t.category, isExpense: isExpense),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            t.category,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountStr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isExpense
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d').format(t.date),
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Particle burst overlay.
        if (_burst.isAnimating || _burst.isCompleted)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  origin: const Offset(60, 30),
                  progress: _burst.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String category;
  final bool isExpense;

  const _CategoryIcon({required this.category, required this.isExpense});

  IconData get _icon {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'utilities':
        return Icons.bolt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'income':
        return Icons.account_balance_wallet;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isExpense
        ? Colors.red.shade50
        : Colors.green.shade50;
    final iconColor = isExpense
        ? Colors.red.shade400
        : Colors.green.shade400;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon, color: iconColor, size: 22),
    );
  }
}
