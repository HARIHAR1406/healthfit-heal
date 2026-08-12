import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH SCORE RING
// ══════════════════════════════════════════════════════════════════════════════

/// Animated donut ring showing overall health score (0–100).
///
/// Animates from 0 on first build. Segments are coloured to show the
/// composite score contributions.
class HealthScoreRing extends StatefulWidget {
  const HealthScoreRing({
    required this.score,
    required this.isDark,
    super.key,
    this.size = 180,
    this.strokeWidth = 16,
    this.showLabel = true,
    this.healthScore,
    this.fitnessScore,
    this.nutritionScore,
  });

  final double score;
  final bool isDark;
  final double size;
  final double strokeWidth;
  final bool showLabel;

  /// Sub-scores for colour segmentation (0–100 each, optional).
  final double? healthScore;
  final double? fitnessScore;
  final double? nutritionScore;

  @override
  State<HealthScoreRing> createState() => _HealthScoreRingState();
}

class _HealthScoreRingState extends State<HealthScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final animatedScore = widget.score * _anim.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ScoreRingPainter(
              score: animatedScore / 100,
              healthPct: (widget.healthScore ?? widget.score) / 100,
              fitnessPct: (widget.fitnessScore ?? widget.score) / 100,
              nutritionPct: (widget.nutritionScore ?? widget.score) / 100,
              strokeWidth: widget.strokeWidth,
              isDark: widget.isDark,
              hasSegments: widget.healthScore != null,
            ),
            child: widget.showLabel
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: widget.score),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text(
                            v.toInt().toString(),
                            style: AppTypography.headlineLarge.copyWith(
                              color: isDarkColor(widget.isDark),
                              fontWeight: FontWeight.w800,
                              fontSize: widget.size * 0.22,
                            ),
                          ),
                        ),
                        Text(
                          'Score',
                          style: AppTypography.captionText.copyWith(
                            color: isDark2(widget.isDark),
                            fontSize: widget.size * 0.08,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Color isDarkColor(bool dark) =>
      dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color isDark2(bool dark) =>
      dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
}

// ── Score Ring Painter ────────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.score,
    required this.healthPct,
    required this.fitnessPct,
    required this.nutritionPct,
    required this.strokeWidth,
    required this.isDark,
    required this.hasSegments,
  });

  final double score; // 0–1
  final double healthPct;
  final double fitnessPct;
  final double nutritionPct;
  final double strokeWidth;
  final bool isDark;
  final bool hasSegments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // top

    // Background track
    final trackPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (hasSegments && score > 0.05) {
      // Three coloured segments: health (40%), fitness (30%), nutrition (30%)
      const gap = 0.02; // gap in turns
      final total = score * 2 * math.pi;

      final segments = [
        (AppColors.secondary, 0.4, healthPct),
        (AppColors.primary, 0.3, fitnessPct),
        (AppColors.tertiary, 0.3, nutritionPct),
      ];

      double cursor = startAngle;
      for (final (color, weight, pct) in segments) {
        final sweep = (total * weight * pct.clamp(0.0, 1.0)) -
            (gap * 2 * math.pi);
        if (sweep <= 0) continue;
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          cursor,
          sweep,
          false,
          paint,
        );
        cursor += sweep + gap * 2 * math.pi;
      }
    } else {
      // Single gradient arc
      final sweepAngle = score * 2 * math.pi;
      if (sweepAngle > 0) {
        final paint = Paint()
          ..shader = const LinearGradient(
            colors: [AppColors.primary, AppColors.tertiary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.score != score || old.hasSegments != hasSegments;
}

// ══════════════════════════════════════════════════════════════════════════════
// RADAR CHART (CustomPainter)
// ══════════════════════════════════════════════════════════════════════════════

/// Spider-web radar chart for the 6-axis health score.
///
/// Uses a [CustomPainter] since fl_chart 0.70 does not include RadarChart.
class HealthRadarChart extends StatefulWidget {
  const HealthRadarChart({
    required this.scores,
    required this.isDark,
    super.key,
    this.size = 200,
  });

  /// Map of axis label → value (0.0–1.0).
  final Map<String, double> scores;
  final bool isDark;
  final double size;

  @override
  State<HealthRadarChart> createState() => _HealthRadarChartState();
}

class _HealthRadarChartState extends State<HealthRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _RadarPainter(
          scores: widget.scores,
          progress: _anim.value,
          isDark: widget.isDark,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.scores,
    required this.progress,
    required this.isDark,
  });

  final Map<String, double> scores;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide * 0.38;
    final labels = scores.keys.toList();
    final values = scores.values.toList();
    final n = labels.length;
    if (n < 3) return;

    final gridColor =
        (isDark ? Colors.white : Colors.grey).withOpacity(0.12);
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // ── Grid rings (3 levels) ───────────────────────────────────────────────
    for (var ring = 1; ring <= 3; ring++) {
      final r = maxR * ring / 3;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / n;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Spokes ─────────────────────────────────────────────────────────────
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxR * math.cos(angle), cy + maxR * math.sin(angle)),
        gridPaint,
      );
    }

    // ── Filled area ────────────────────────────────────────────────────────
    final areaPath = Path();
    final fillPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final r = maxR * (values[i] * progress).clamp(0.0, 1.0);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? areaPath.moveTo(x, y) : areaPath.lineTo(x, y);
    }
    areaPath.close();
    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(areaPath, strokePaint);

    // ── Dots ────────────────────────────────────────────────────────────────
    final dotPaint = Paint()..color = AppColors.primary;
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final r = maxR * (values[i] * progress).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)), 4, dotPaint);
    }

    // ── Labels ──────────────────────────────────────────────────────────────
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final r = maxR + 18;
      tp
        ..text = TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 10,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        )
        ..layout();
      final x = cx + r * math.cos(angle) - tp.width / 2;
      final y = cy + r * math.sin(angle) - tp.height / 2;
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress || old.scores != scores;
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT CARD
// ══════════════════════════════════════════════════════════════════════════════

/// Export format tile shown in the Export Center.
class ExportCard extends StatelessWidget {
  const ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    super.key,
    this.isLoading = false,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLoading;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.captionText.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.captionText.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          'Generate',
                          style: AppTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.download_rounded, size: 14, color: color),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

