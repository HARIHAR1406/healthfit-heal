import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// A single row in a health readings history list.
///
/// Shows timestamp, value, optional status chip, and optional notes.
class HealthReadingTile extends StatelessWidget {
  const HealthReadingTile({
    required this.title,
    required this.value,
    required this.timestamp,
    super.key,
    this.subtitle,
    this.iconData,
    this.iconColor = AppColors.primary,
    this.statusWidget,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final String value;
  final DateTime timestamp;
  final String? subtitle;
  final IconData? iconData;
  final Color iconColor;
  final Widget? statusWidget;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('dd MMM · hh:mm a').format(timestamp);

    return Semantics(
      label: '$title: $value. $dateStr',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(AppSpacing.radiusXl) : Radius.zero,
          bottom: isLast ? const Radius.circular(AppSpacing.radiusXl) : Radius.zero,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.vertical(
              top: isFirst
                  ? const Radius.circular(AppSpacing.radiusXl)
                  : Radius.zero,
              bottom: isLast
                  ? const Radius.circular(AppSpacing.radiusXl)
                  : Radius.zero,
            ),
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(
                      color: isDark
                          ? AppColors.dividerDark
                          : AppColors.dividerLight,
                      width: AppSpacing.borderThin,
                    ),
            ),
          ),
          child: Row(
            children: [
              // Icon
              if (iconData != null)
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: AppSpacing.iconSm),
                ),

              // Title + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: AppTypography.captionText.copyWith(
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Value + optional status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (statusWidget != null) ...[
                    const SizedBox(height: 4),
                    statusWidget!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

