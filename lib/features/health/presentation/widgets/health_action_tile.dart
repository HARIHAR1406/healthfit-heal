import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/health_record_entity.dart';

/// A quick-access action tile for the Health Dashboard action grid.
class HealthActionTile extends StatefulWidget {
  const HealthActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    super.key,
    this.value,
    this.unit,
    this.statusWidget,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final String? value;
  final String? unit;
  final Widget? statusWidget;

  @override
  State<HealthActionTile> createState() => _HealthActionTileState();
}

class _HealthActionTileState extends State<HealthActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
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
      label: '${widget.label}${widget.value != null ? ": ${widget.value} ${widget.unit ?? ''}" : ''}',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          context.push(widget.route);
        },
        onTapCancel: () => _ctrl.forward(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: AppSpacing.borderThin,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: AppSpacing.iconMd,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.value != null) ...[
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: widget.value!,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.unit != null)
                        TextSpan(
                          text: ' ${widget.unit}',
                          style: AppTypography.captionText.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ]),
                  ),
                ],
                if (widget.statusWidget != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  widget.statusWidget!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Medical Record Tile ───────────────────────────────────────────────────────

/// A tile in the medical records list.
class MedicalRecordTile extends StatelessWidget {
  const MedicalRecordTile({required this.record, super.key, this.onTap});

  final HealthRecordEntity record;
  final VoidCallback? onTap;

  IconData get _icon => switch (record.type) {
        HealthRecordType.labReport => Icons.science_rounded,
        HealthRecordType.prescription => Icons.medication_rounded,
        HealthRecordType.imaging => Icons.image_rounded,
        HealthRecordType.consultation => Icons.person_rounded,
        HealthRecordType.vaccination => Icons.vaccines_rounded,
        HealthRecordType.other => Icons.folder_rounded,
      };

  Color get _color => switch (record.type) {
        HealthRecordType.labReport => AppColors.chartCoral,
        HealthRecordType.prescription => AppColors.success,
        HealthRecordType.imaging => AppColors.chartSky,
        HealthRecordType.consultation => AppColors.tertiary,
        HealthRecordType.vaccination => AppColors.chartAmber,
        HealthRecordType.other => AppColors.chartIndigo,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM yyyy').format(record.date);

    return Semantics(
      label: '${record.title}. ${record.type.label}. $dateStr',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: AppSpacing.borderThin,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(_icon, color: _color, size: AppSpacing.iconMd),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.doctorName != null
                          ? '${record.doctorName!} · $dateStr'
                          : dateStr,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 11,
                      ),
                    ),
                    if (record.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: 4,
                        children: record.tags
                            .take(3)
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                ),
                                child: Text(
                                  t,
                                  style: AppTypography.overline
                                      .copyWith(color: _color, fontSize: 9),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Attachment + arrow
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (record.hasAttachment)
                    Icon(
                      Icons.attach_file_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppSpacing.iconSm,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
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
