import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_notifier.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// App settings — theme, units, notifications, security, privacy.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          SettingsSectionCard(
            title: 'Appearance',
            titleIcon: Icons.palette_rounded,
            titleColor: AppColors.primary,
            children: [
              _ThemeSelector(
                current: settings.themePreference,
                isDark: isDark,
                onChanged: notifier.updateTheme,
              ),
              _UnitSelector(
                current: settings.unitSystem,
                isDark: isDark,
                onChanged: notifier.updateUnits,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Notifications ─────────────────────────────────────────────────
          SettingsSectionCard(
            title: 'Notifications',
            titleIcon: Icons.notifications_rounded,
            titleColor: AppColors.warning,
            children: [
              SettingsSwitchTile(
                icon: Icons.fitness_center_rounded,
                title: 'Workout Reminders',
                subtitle: 'Daily push to stay active',
                iconColor: AppColors.primary,
                value: settings.notificationPrefs.workoutReminders,
                onChanged: (_) => notifier.toggleWorkoutReminders(),
              ),
              SettingsSwitchTile(
                icon: Icons.restaurant_rounded,
                title: 'Meal Reminders',
                subtitle: 'Log breakfast, lunch, dinner',
                iconColor: AppColors.chartAmber,
                value: settings.notificationPrefs.mealReminders,
                onChanged: (_) => notifier.toggleMealReminders(),
              ),
              SettingsSwitchTile(
                icon: Icons.water_drop_rounded,
                title: 'Water Reminders',
                subtitle: 'Hydration check-ins',
                iconColor: AppColors.info,
                value: settings.notificationPrefs.waterReminders,
                onChanged: (_) => notifier.toggleWaterReminders(),
              ),
              SettingsSwitchTile(
                icon: Icons.medication_rounded,
                title: 'Medication Reminders',
                iconColor: AppColors.secondary,
                value: settings.notificationPrefs.medicationReminders,
                onChanged: (_) => notifier.toggleMedicationReminders(),
              ),
              SettingsSwitchTile(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Insights',
                subtitle: 'Smart coaching nudges',
                iconColor: AppColors.tertiary,
                value: settings.notificationPrefs.aiInsights,
                onChanged: (_) => notifier.toggleAiInsights(),
              ),
              SettingsSwitchTile(
                icon: Icons.bar_chart_rounded,
                title: 'Weekly Reports',
                subtitle: 'Sunday summary emails',
                iconColor: AppColors.chartSky,
                value: settings.notificationPrefs.weeklyReports,
                onChanged: (_) => notifier.toggleWeeklyReports(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Security ──────────────────────────────────────────────────────
          SettingsSectionCard(
            title: 'Security',
            titleIcon: Icons.lock_rounded,
            titleColor: AppColors.error,
            children: [
              SettingsSwitchTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Login',
                subtitle: 'Face ID / Fingerprint',
                iconColor: AppColors.error,
                value: settings.useBiometricAuth,
                onChanged: notifier.updateBiometric,
              ),
              SettingsTile(
                icon: Icons.key_rounded,
                title: 'Change Password',
                iconColor: AppColors.error,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password change flow coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Privacy ───────────────────────────────────────────────────────
          SettingsSectionCard(
            title: 'Privacy',
            titleIcon: Icons.privacy_tip_rounded,
            titleColor: AppColors.tertiary,
            children: [
              SettingsSwitchTile(
                icon: Icons.analytics_rounded,
                title: 'Share Anonymous Data',
                subtitle: 'Help improve the app',
                iconColor: AppColors.tertiary,
                value: settings.shareAnonymousData,
                onChanged: notifier.updateAnonymousSharing,
              ),
              SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete My Data',
                subtitle: 'Remove all stored health data',
                iconColor: AppColors.error,
                onTap: () => _showDeleteDataDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── About ─────────────────────────────────────────────────────────
          SettingsSectionCard(
            title: 'About',
            titleIcon: Icons.info_outline_rounded,
            titleColor: AppColors.textSecondaryLight,
            children: [
              SettingsTile(
                icon: Icons.info_rounded,
                title: 'Version',
                subtitle: settings.appVersion,
                iconColor: AppColors.textSecondaryLight,
              ),
              SettingsTile(
                icon: Icons.code_rounded,
                title: 'Open Source Licences',
                iconColor: AppColors.textSecondaryLight,
                onTap: () => showLicensePage(context: context),
              ),
              SettingsTile(
                icon: Icons.star_rounded,
                title: 'Rate the App',
                iconColor: AppColors.chartAmber,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your health data from our servers. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data deletion requested'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Theme Selector Row ────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.current,
    required this.isDark,
    required this.onChanged,
  });

  final AppThemePreference current;
  final bool isDark;
  final ValueChanged<AppThemePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.contrast_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'App Theme',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: AppThemePreference.values.map((t) {
              final selected = t == current;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => onChanged(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        children: [
                          Icon(t.icon,
                              size: 20,
                              color: selected
                                  ? AppColors.white
                                  : AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            style: AppTypography.captionText.copyWith(
                              color: selected
                                  ? AppColors.white
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Unit Selector ─────────────────────────────────────────────────────────────

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({
    required this.current,
    required this.isDark,
    required this.onChanged,
  });

  final UnitSystem current;
  final bool isDark;
  final ValueChanged<UnitSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.straighten_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Unit System',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SegmentedButton<UnitSystem>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: AppColors.white,
              visualDensity: VisualDensity.compact,
            ),
            segments: UnitSystem.values
                .map((u) => ButtonSegment<UnitSystem>(
                      value: u,
                      label: Text(u.label.split(' ').first),
                    ))
                .toList(),
            selected: {current},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

