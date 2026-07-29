import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_providers.dart';
import '../providers/profile_state.dart';
import '../widgets/profile_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Main profile tab — header, stats, goal progress, and navigation tiles.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(profileNotifierProvider) is ProfileInitial) {
        ref.read(profileNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profileState = ref.watch(profileNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: switch (profileState) {
        ProfileLoading() => const _LoadingView(),
        ProfileError(:final message) => _ErrorView(
            message: message,
            onRetry: () => ref.read(profileNotifierProvider.notifier).load(),
          ),
        ProfileLoaded(:final profile) ||
        ProfileSaved(:final profile) ||
        ProfileSaving(:final profile) =>
          _ProfileContent(
            profile: profile,
            isSaving: profileState is ProfileSaving,
            isDark: isDark,
          ),
        _ => const _LoadingView(),
      },
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load profile',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE CONTENT
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isSaving,
    required this.isDark,
  });

  final UserProfileEntity profile;
  final bool isSaving;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── SliverAppBar ─────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Profile',
            style: AppTypography.titleLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            if (isSaving)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                tooltip: 'Edit Profile',
                onPressed: () => context.push(RouteNames.editProfile),
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                tooltip: 'Settings',
                onPressed: () => context.push(RouteNames.settings),
              ),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _ProfileHeader(profile: profile, isDark: isDark),
          ),
        ),

        // ── Stats Row ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: _StatsRow(profile: profile),
          ),
        ),

        // ── Today's Goals ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            child: _GoalsSection(profile: profile, isDark: isDark),
          ),
        ),

        // ── Quick Nav ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            child: _QuickNavSection(isDark: isDark),
          ),
        ),

        // ── Account ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.massive,
            ),
            child: _AccountSection(profile: profile, isDark: isDark),
          ),
        ),
      ],
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.isDark});
  final UserProfileEntity profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1A2A3A)]
              : [const Color(0xFFE8F4FE), const Color(0xFFF5F9FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxxl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              ProfileAvatar(
                initials: profile.initials,
                size: 88,
                avatarUrl: profile.avatarUrl,
                showEditBadge: false,
              ),
              const SizedBox(height: AppSpacing.md),

              // Name
              Text(
                profile.fullName,
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),

              // Email + join date
              Text(
                profile.email,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Badges row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Badge(
                    text: profile.activityLevel.label,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Badge(
                    text: '${profile.age} years',
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _Badge(
                    text: profile.bmiLabel,
                    color: profile.bmiColor,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});
  final UserProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final isMetric =
        profile.settings.unitSystem == UnitSystem.metric;
    return Row(
      children: [
        Expanded(
          child: ProfileStatChip(
            label: 'Height',
            value: isMetric
                ? profile.heightCm.toStringAsFixed(0)
                : (profile.heightCm / 2.54).toStringAsFixed(0),
            unit: isMetric ? 'cm' : 'in',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ProfileStatChip(
            label: 'Weight',
            value: isMetric
                ? profile.weightKg.toStringAsFixed(1)
                : (profile.weightKg * 2.205).toStringAsFixed(1),
            unit: isMetric ? 'kg' : 'lb',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ProfileStatChip(
            label: 'BMI',
            value: profile.bmi.toStringAsFixed(1),
            unit: '',
            color: profile.bmiColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ProfileStatChip(
            label: 'TDEE',
            value: profile.tdee.toStringAsFixed(0),
            unit: 'kcal',
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }
}

// ── Goals Section ─────────────────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.profile, required this.isDark});
  final UserProfileEntity profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final g = profile.goals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              'Daily Goals',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push(RouteNames.editGoals),
              child: Text(
                'Edit',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              GoalProgressRow(
                icon: Icons.local_fire_department_rounded,
                label: 'Daily Calories',
                current: g.dailyCaloriesTarget * 0.72,
                target: g.dailyCaloriesTarget,
                unit: 'kcal',
                color: AppColors.chartCoral,
              ),
              const SizedBox(height: AppSpacing.sm),
              GoalProgressRow(
                icon: Icons.water_drop_rounded,
                label: 'Water Intake',
                current: g.dailyWaterMlTarget * 0.6,
                target: g.dailyWaterMlTarget,
                unit: 'ml',
                color: AppColors.info,
              ),
              const SizedBox(height: AppSpacing.sm),
              GoalProgressRow(
                icon: Icons.directions_walk_rounded,
                label: 'Steps',
                current: g.dailyStepsTarget * 0.54,
                target: g.dailyStepsTarget.toDouble(),
                unit: 'steps',
                color: AppColors.tertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              GoalProgressRow(
                icon: Icons.bedtime_rounded,
                label: 'Sleep',
                current: 6.5,
                target: g.sleepHoursTarget,
                unit: 'hrs',
                color: AppColors.chartPink,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Quick Nav Section ─────────────────────────────────────────────────────────

class _QuickNavSection extends StatelessWidget {
  const _QuickNavSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: AppTypography.titleMedium.copyWith(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SettingsSectionCard(
          title: 'Manage',
          children: [
            SettingsTile(
              icon: Icons.person_rounded,
              title: 'Edit Profile',
              subtitle: 'Update personal information',
              iconColor: AppColors.primary,
              onTap: () => context.push(RouteNames.editProfile),
            ),
            SettingsTile(
              icon: Icons.flag_rounded,
              title: 'Health Goals',
              subtitle: 'Adjust your daily targets',
              iconColor: AppColors.tertiary,
              onTap: () => context.push(RouteNames.editGoals),
            ),
            SettingsTile(
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'Theme, units, notifications',
              iconColor: AppColors.warning,
              onTap: () => context.push(RouteNames.settings),
            ),
            SettingsTile(
              icon: Icons.bar_chart_rounded,
              title: 'Reports & Analytics',
              subtitle: 'View your health insights',
              iconColor: AppColors.chartSky,
              onTap: () => context.push(RouteNames.reports),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Account Section ──────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.profile, required this.isDark});
  final UserProfileEntity profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Support',
      children: [
        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & FAQ',
          subtitle: 'Browse common questions',
          iconColor: AppColors.primary,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          iconColor: AppColors.info,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          iconColor: AppColors.textSecondaryLight,
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          destructive: true,
          onTap: () => _showSignOutDialog(context),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RouteNames.login);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
