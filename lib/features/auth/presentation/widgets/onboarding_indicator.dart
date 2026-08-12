import 'package:flutter/material.dart';

import '../../../../design_system/colors/app_colors.dart';

/// Animated page indicator dots for the onboarding [PageView].
class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    required this.pageCount,
    required this.currentPage,
    super.key,
    this.activeColor = AppColors.primary,
    this.inactiveColor,
    this.dotSize = 8.0,
    this.activeDotWidth = 24.0,
    this.spacing = 6.0,
  });

  final int pageCount;
  final int currentPage;
  final Color activeColor;
  final Color? inactiveColor;

  /// Diameter of inactive dots.
  final double dotSize;

  /// Width of the active pill indicator.
  final double activeDotWidth;

  /// Horizontal gap between dots.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultInactive = isDark
        ? AppColors.dividerDark
        : AppColors.dividerLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? activeDotWidth : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isActive ? activeColor : (inactiveColor ?? defaultInactive),
            borderRadius: BorderRadius.circular(dotSize / 2),
          ),
        );
      }),
    );
  }
}

