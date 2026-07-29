import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../design_system/colors/app_colors.dart';
import '../../design_system/spacing/app_spacing.dart';
import '../../design_system/typography/app_typography.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GLOBAL SEARCH OVERLAY
// ══════════════════════════════════════════════════════════════════════════════

/// A full-screen search overlay that surfaces features and quick actions.
///
/// Open via [showGlobalSearch].
class GlobalSearchOverlay extends ConsumerStatefulWidget {
  const GlobalSearchOverlay({super.key});

  @override
  ConsumerState<GlobalSearchOverlay> createState() =>
      _GlobalSearchOverlayState();
}

class _GlobalSearchOverlayState extends ConsumerState<GlobalSearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(_fade);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _close() async {
    await _anim.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _query.isEmpty
        ? _SearchItem.allItems
        : _SearchItem.allItems
            .where((item) =>
                item.title.toLowerCase().contains(_query.toLowerCase()) ||
                item.subtitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── Search Bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.surfaceLight,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: AppSpacing.borderMedium,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: AppSpacing.md),
                              const Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  onChanged: (v) => setState(() => _query = v),
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search features, metrics…',
                                    hintStyle: AppTypography.bodyMedium
                                        .copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.md),
                                  ),
                                ),
                              ),
                              if (_query.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: _close,
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Section Header ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md + 4, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                  child: Row(
                    children: [
                      Text(
                        _query.isEmpty
                            ? 'QUICK ACCESS'
                            : 'RESULTS (${results.length})',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Results ──────────────────────────────────────────────────
                Expanded(
                  child: results.isEmpty
                      ? _EmptyResult(query: _query, isDark: isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          itemCount: results.length,
                          itemBuilder: (_, i) => _SearchResultTile(
                            item: results[i],
                            isDark: isDark,
                            onTap: () {
                              _close();
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (context.mounted) {
                                    context.push(results[i].route);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search Result Tile ─────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final _SearchItem item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: AppTypography.captionText.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty Result ──────────────────────────────────────────────────────────────

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.query, required this.isDark});
  final String query;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 52,
              color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                  .withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No results for "$query"',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Data ───────────────────────────────────────────────────────────────

class _SearchItem {
  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  static const List<_SearchItem> allItems = [
    // Dashboard
    _SearchItem(
      title: 'Home Dashboard',
      subtitle: 'Overview of all your health metrics',
      icon: Icons.home_rounded,
      color: AppColors.primary,
      route: RouteNames.home,
    ),
    // Health
    _SearchItem(
      title: 'Health Overview',
      subtitle: 'BMI, heart rate, blood pressure & more',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFFEF5350),
      route: RouteNames.healthDashboard,
    ),
    _SearchItem(
      title: 'BMI Calculator',
      subtitle: 'Track your body mass index',
      icon: Icons.straighten_rounded,
      color: Color(0xFF6C63FF),
      route: RouteNames.bmi,
    ),
    _SearchItem(
      title: 'Heart Rate',
      subtitle: 'Monitor your resting & active HR',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEF5350),
      route: RouteNames.heartRate,
    ),
    _SearchItem(
      title: 'Blood Pressure',
      subtitle: 'Log systolic & diastolic readings',
      icon: Icons.bloodtype_rounded,
      color: Color(0xFF2196F3),
      route: RouteNames.bloodPressure,
    ),
    _SearchItem(
      title: 'Blood Sugar',
      subtitle: 'Track glucose levels over time',
      icon: Icons.water_drop_rounded,
      color: Color(0xFFFFBF00),
      route: RouteNames.bloodSugar,
    ),
    _SearchItem(
      title: 'Blood Oxygen (SpO₂)',
      subtitle: 'Monitor oxygen saturation levels',
      icon: Icons.air_rounded,
      color: Color(0xFF00B4D8),
      route: RouteNames.spo2,
    ),
    // Fitness
    _SearchItem(
      title: 'Fitness Dashboard',
      subtitle: 'Workouts, sessions & streaks',
      icon: Icons.fitness_center_rounded,
      color: AppColors.primary,
      route: RouteNames.workouts,
    ),
    _SearchItem(
      title: 'Workout Library',
      subtitle: 'Browse all exercises & plans',
      icon: Icons.library_books_rounded,
      color: Color(0xFF00C896),
      route: RouteNames.workoutLibrary,
    ),
    _SearchItem(
      title: 'Achievements',
      subtitle: 'View your fitness milestones',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFBF00),
      route: RouteNames.achievements,
    ),
    // Nutrition
    _SearchItem(
      title: 'Nutrition Dashboard',
      subtitle: 'Meals, macros & calorie tracking',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF9800),
      route: RouteNames.nutrition,
    ),
    _SearchItem(
      title: 'Meal Planner',
      subtitle: 'Plan your meals for the week',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFFF6B6B),
      route: RouteNames.mealPlanner,
    ),
    _SearchItem(
      title: 'Water Tracker',
      subtitle: 'Log daily water intake',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF2196F3),
      route: RouteNames.waterTracker,
    ),
    _SearchItem(
      title: 'Weight Tracker',
      subtitle: 'Monitor your weight journey',
      icon: Icons.monitor_weight_rounded,
      color: Color(0xFF6C63FF),
      route: RouteNames.weightTracker,
    ),
    _SearchItem(
      title: 'Food Database',
      subtitle: 'Search 1M+ foods for macros',
      icon: Icons.search_rounded,
      color: Color(0xFF00B4D8),
      route: RouteNames.foodDatabase,
    ),
    // AI
    _SearchItem(
      title: 'AI Health Coach',
      subtitle: 'Smart coaching & personalised advice',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF6C63FF),
      route: RouteNames.aiAssistant,
    ),
    _SearchItem(
      title: 'Smart Insights',
      subtitle: 'AI-powered health analytics',
      icon: Icons.insights_rounded,
      color: Color(0xFF00B4D8),
      route: RouteNames.smartInsights,
    ),
    // Reports
    _SearchItem(
      title: 'Reports & Analytics',
      subtitle: 'Detailed health trend analysis',
      icon: Icons.bar_chart_rounded,
      color: Color(0xFF00C896),
      route: RouteNames.reports,
    ),
    // Medication
    _SearchItem(
      title: 'Medication Tracker',
      subtitle: 'Manage doses & adherence',
      icon: Icons.medication_rounded,
      color: Color(0xFF2196F3),
      route: RouteNames.medication,
    ),
    // Profile
    _SearchItem(
      title: 'Profile',
      subtitle: 'View & edit your health profile',
      icon: Icons.person_rounded,
      color: AppColors.primary,
      route: RouteNames.profile,
    ),
    _SearchItem(
      title: 'Settings',
      subtitle: 'Theme, units, notifications',
      icon: Icons.settings_rounded,
      color: Color(0xFFFF9800),
      route: RouteNames.settings,
    ),
    _SearchItem(
      title: 'Health Goals',
      subtitle: 'Set & adjust daily targets',
      icon: Icons.flag_rounded,
      color: Color(0xFF00C896),
      route: RouteNames.editGoals,
    ),
  ];
}

// ══════════════════════════════════════════════════════════════════════════════
// CONVENIENCE FUNCTION
// ══════════════════════════════════════════════════════════════════════════════

/// Shows the global search overlay as a full-screen route.
void showGlobalSearch(BuildContext context) {
  Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const GlobalSearchOverlay(),
    ),
  );
}
