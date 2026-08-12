import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_notifier.dart';
import '../providers/notification_providers.dart';
import '../providers/notification_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS PAGE
// ══════════════════════════════════════════════════════════════════════════════

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(notificationNotifierProvider) is NotificationInitial) {
        ref.read(notificationNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Notification Settings',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ── Sections ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Master ─────────────────────────────────────────────────
                _SettingsSection(
                  title: 'Master Control',
                  isDark: isDark,
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.notifications_rounded,
                      label: 'All Notifications',
                      description: 'Master switch for all alerts',
                      value: settings.masterEnabled,
                      color: AppColors.primary,
                      isDark: isDark,
                      onChanged: (v) => notifier.updateSettings(
                          settings.copyWith(masterEnabled: v)),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Alert Type ─────────────────────────────────────────────
                _SettingsSection(
                  title: 'Alert Type',
                  isDark: isDark,
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.volume_up_rounded,
                      label: 'Sound',
                      description: 'Play alert sound',
                      value: settings.soundEnabled,
                      color: AppColors.info,
                      isDark: isDark,
                      enabled: settings.masterEnabled,
                      onChanged: (v) => notifier.updateSettings(
                          settings.copyWith(soundEnabled: v)),
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.vibration_rounded,
                      label: 'Vibration',
                      description: 'Vibrate on notification',
                      value: settings.vibrationEnabled,
                      color: AppColors.info,
                      isDark: isDark,
                      enabled: settings.masterEnabled,
                      onChanged: (v) => notifier.updateSettings(
                          settings.copyWith(vibrationEnabled: v)),
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.do_not_disturb_on_rounded,
                      label: 'Silent Mode',
                      description: 'No sound or vibration',
                      value: settings.silentMode,
                      color: AppColors.warning,
                      isDark: isDark,
                      enabled: settings.masterEnabled,
                      onChanged: (v) => notifier.updateSettings(
                          settings.copyWith(silentMode: v)),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Quiet Hours ────────────────────────────────────────────
                _SettingsSection(
                  title: 'Do Not Disturb',
                  isDark: isDark,
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.bedtime_rounded,
                      label: 'Quiet Hours',
                      description: 'Mute all alerts during set hours',
                      value: settings.quietHoursEnabled,
                      color: const Color(0xFF6C63FF),
                      isDark: isDark,
                      enabled: settings.masterEnabled,
                      onChanged: (v) => notifier.updateSettings(
                          settings.copyWith(quietHoursEnabled: v)),
                    ),
                    if (settings.quietHoursEnabled) ...[
                      _QuietHoursTile(
                        label: 'Start Time',
                        time: settings.quietHoursStart,
                        isDark: isDark,
                        onChanged: (t) => notifier.updateSettings(
                            settings.copyWith(quietHoursStart: t)),
                      ),
                      _QuietHoursTile(
                        label: 'End Time',
                        time: settings.quietHoursEnd,
                        isDark: isDark,
                        onChanged: (t) => notifier.updateSettings(
                            settings.copyWith(quietHoursEnd: t)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Category Toggles ───────────────────────────────────────
                _SettingsSection(
                  title: 'Notification Categories',
                  isDark: isDark,
                  children: NotificationCategory.values.map((cat) {
                    final enabled =
                        settings.categoryToggles[cat] ?? true;
                    return _SettingsSwitchTile(
                      icon: cat.icon,
                      label: cat.label,
                      description: 'Allow ${cat.label} notifications',
                      value: enabled,
                      color: cat.color,
                      isDark: isDark,
                      enabled: settings.masterEnabled,
                      onChanged: (v) {
                        final updated = Map<NotificationCategory, bool>.from(
                            settings.categoryToggles);
                        updated[cat] = v;
                        notifier.updateSettings(
                            settings.copyWith(categoryToggles: updated));
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Status ─────────────────────────────────────────────────
                if (settings.isInQuietHours)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime_rounded,
                            color: Color(0xFF6C63FF), size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Quiet Hours active — notifications are muted',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  final String title;
  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
              width: AppSpacing.borderThin,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Settings Switch Tile ──────────────────────────────────────────────────────

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.color,
    required this.isDark,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final Color color;
  final bool isDark;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: color,
        ),
      ),
    );
  }
}

// ── Quiet Hours Tile ──────────────────────────────────────────────────────────

class _QuietHoursTile extends StatelessWidget {
  const _QuietHoursTile({
    required this.label,
    required this.time,
    required this.isDark,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final bool isDark;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: const Icon(Icons.access_time_rounded,
            color: Color(0xFF6C63FF), size: 20),
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            timeStr,
            style: AppTypography.titleSmall.copyWith(
              color: const Color(0xFF6C63FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
