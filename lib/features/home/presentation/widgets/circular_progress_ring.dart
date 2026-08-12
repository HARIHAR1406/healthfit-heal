import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Animated circular progress ring with a center label.
///
/// Used in the "Today's Progress" section.
/// Animates from 0 to [fraction] when the widget first appears.
class CircularProgressRing extends StatefulWidget {
  const CircularProgressRing({
    required this.fraction,
    required this.size,
    super.key,
    this.strokeWidth = 6.0,
    this.color = AppColors.primary,
    this.trackColor,
    this.centerWidget,
    this.animate = true,
    this.duration = const Duration(milliseconds: 900),
  });

  /// Progress from 0.0 to 1.0.
  final double fraction;

  /// Outer diameter of the ring.
  final double size;

  final double strokeWidth;
  final Color color;

  /// Background track color; defaults to [color] at low opacity.
  final Color? trackColor;

  /// Optional widget displayed inside the ring.
  final Widget? centerWidget;

  /// Whether to run the entrance animation.
  final bool animate;
  final Duration duration;

  @override
  State<CircularProgressRing> createState() => _CircularProgressRingState();
}

class _CircularProgressRingState extends State<CircularProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(CircularProgressRing old) {
    super.didUpdateWidget(old);
    if (old.fraction != widget.fraction) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          painter: _RingPainter(
            fraction: widget.fraction * _anim.value,
            strokeWidth: widget.strokeWidth,
            color: widget.color,
            trackColor: widget.trackColor ??
                widget.color.withOpacity(0.12),
          ),
          child: Center(child: widget.centerWidget),
        ),
      ),
    );
  }
}

// ── Custom Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // 12 o'clock

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track arc (full circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 2,
      false,
      trackPaint,
    );

    // Progress arc
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 2 * fraction,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// Compact ring with a label + unit inside, used in progress grids.
class LabeledProgressRing extends StatelessWidget {
  const LabeledProgressRing({
    required this.fraction,
    required this.label,
    required this.unit,
    required this.color,
    super.key,
    this.size = 72,
    this.strokeWidth = 6,
  });

  final double fraction;
  final String label;
  final String unit;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CircularProgressRing(
      fraction: fraction,
      size: size,
      strokeWidth: strokeWidth,
      color: color,
      centerWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
              fontSize: size < 80 ? 11 : 14,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: AppTypography.captionText.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: size < 80 ? 9 : 11,
              ),
            ),
        ],
      ),
    );
  }
}
