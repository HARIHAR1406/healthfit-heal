import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/bmi_entity.dart';

/// Animated semicircular BMI gauge (speedometer-style).
///
/// Draws a 180° arc split into 4 colour segments corresponding to BMI categories.
/// An animated needle sweeps to [fraction] (0.0–1.0 across BMI range 10–40).
class BmiGauge extends StatefulWidget {
  const BmiGauge({
    required this.bmiValue,
    required this.category,
    super.key,
    this.size = 240.0,
    this.animate = true,
  });

  final double bmiValue;
  final BmiCategory category;
  final double size;
  final bool animate;

  @override
  State<BmiGauge> createState() => _BmiGaugeState();
}

class _BmiGaugeState extends State<BmiGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  double get _fraction => ((widget.bmiValue - 10) / 30).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    if (widget.animate) _ctrl.forward();
  }

  @override
  void didUpdateWidget(BmiGauge old) {
    super.didUpdateWidget(old);
    if (old.bmiValue != widget.bmiValue) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'BMI gauge: ${widget.bmiValue.toStringAsFixed(1)}. Category: ${widget.category.label}',
      child: SizedBox(
        width: widget.size,
        height: widget.size * 0.6,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => CustomPaint(
            painter: _GaugePainter(
              fraction: _fraction * _anim.value,
              isDark: isDark,
            ),
            child: _Center(
              bmiValue: widget.bmiValue,
              category: widget.category,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter ─────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.fraction, required this.isDark});

  final double fraction;
  final bool isDark;

  static const _segments = [
    _Segment(0.0, 0.283, AppColors.chartSky),        // Underweight (10–18.5)
    _Segment(0.283, 0.5, AppColors.success),           // Normal (18.5–25)
    _Segment(0.5, 0.667, AppColors.warning),           // Overweight (25–30)
    _Segment(0.667, 1.0, AppColors.error),             // Obese (30–40)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;
    final outerR = size.width / 2 * 0.92;
    final innerR = outerR * 0.68;
    const strokeW = 16.0;
    const sweepDeg = 180.0;

    // Draw arc segments
    for (final seg in _segments) {
      final paint = Paint()
        ..color = seg.color.withOpacity(isDark ? 0.9 : 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt;

      final startAngle = math.pi + seg.start * math.pi;
      final sweepAngle = (seg.end - seg.start) * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR - strokeW / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw gaps between segments
    final gapPaint = Paint()
      ..color = isDark ? AppColors.backgroundDark : AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + 2;

    for (final pos in [0.283, 0.5, 0.667]) {
      final angle = math.pi + pos * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: outerR - strokeW / 2),
        angle - 0.01,
        0.02,
        false,
        gapPaint,
      );
    }

    // Needle
    final needleAngle = math.pi + fraction * math.pi;
    final needleTip = Offset(
      cx + (outerR - strokeW * 0.5) * math.cos(needleAngle),
      cy + (outerR - strokeW * 0.5) * math.sin(needleAngle),
    );
    final needleBase = Offset(
      cx + innerR * 0.3 * math.cos(needleAngle + math.pi),
      cy + innerR * 0.3 * math.sin(needleAngle + math.pi),
    );

    canvas.drawLine(
      needleBase,
      needleTip,
      Paint()
        ..color =
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Centre dot
    canvas.drawCircle(
      Offset(cx, cy),
      8,
      Paint()
        ..color =
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()
        ..color = isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction;
}

class _Segment {
  const _Segment(this.start, this.end, this.color);
  final double start;
  final double end;
  final Color color;
}

// ── Centre Label ──────────────────────────────────────────────────────────────

class _Center extends StatelessWidget {
  const _Center({
    required this.bmiValue,
    required this.category,
    required this.isDark,
  });

  final double bmiValue;
  final BmiCategory category;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 1.0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bmiValue.toStringAsFixed(1),
              style: AppTypography.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              category.label,
              style: AppTypography.labelMedium.copyWith(
                color: switch (category) {
                  BmiCategory.normalWeight => AppColors.success,
                  BmiCategory.underweight => AppColors.chartSky,
                  BmiCategory.overweight => AppColors.warning,
                  BmiCategory.obese => AppColors.error,
                },
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

