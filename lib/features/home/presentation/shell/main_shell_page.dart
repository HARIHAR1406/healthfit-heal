import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// The persistent shell scaffold for the main app.
///
/// Renders:
///   - The current tab body via [StatefulNavigationShell]
///   - Material 3 [NavigationBar] with 5 tabs
///   - Floating AI Assistant action button
///
/// This widget is rebuilt only when the selected tab changes.
class MainShellPage extends StatelessWidget {
  const MainShellPage({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  // ── Tab definitions ──────────────────────────────────────────────────────

  static const _destinations = [
    _TabDest(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _TabDest(
      label: 'Health',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart_rounded,
    ),
    _TabDest(
      label: 'Fitness',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
    ),
    _TabDest(
      label: 'Nutrition',
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
    ),
    _TabDest(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _onTabSelected(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      // Return to initial location of the branch when re-selecting current tab
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,

      // ── Bottom Navigation Bar ──────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (i) => _onTabSelected(i, context),
        isDark: isDark,
      ),

      // ── AI Assistant FAB ───────────────────────────────────────────────────
      floatingActionButton: _AiFab(
        onPressed: () => context.push(RouteNames.aiAssistant),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.isDark,
  });

  final int selectedIndex;
  final List<_TabDest> destinations;
  final ValueChanged<int> onDestinationSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      animationDuration: const Duration(milliseconds: 300),
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      surfaceTintColor: AppColors.primary,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      height: AppSpacing.bottomNavHeight + AppSpacing.md,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: destinations
          .map(
            (d) => NavigationDestination(
              icon: Icon(d.icon, semanticLabel: d.label),
              selectedIcon: Icon(
                d.selectedIcon,
                color: AppColors.primary,
              ),
              label: d.label,
            ),
          )
          .toList(),
    );
  }
}

// ── AI FAB ────────────────────────────────────────────────────────────────────

class _AiFab extends StatelessWidget {
  const _AiFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open AI Health Coach',
      button: true,
      child: FloatingActionButton.extended(
        heroTag: 'ai_fab',
        onPressed: onPressed,
        backgroundColor: AppColors.tertiary,
        foregroundColor: AppColors.white,
        elevation: AppSpacing.elevationMd,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text(
          'AI Coach',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _TabDest {
  const _TabDest({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
