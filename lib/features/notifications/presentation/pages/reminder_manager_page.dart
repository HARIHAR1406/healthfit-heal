import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/notification_providers.dart';
import '../providers/reminder_notifier.dart';
import '../providers/reminder_state.dart';
import '../widgets/notification_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER MANAGER PAGE
// ══════════════════════════════════════════════════════════════════════════════

class ReminderManagerPage extends ConsumerStatefulWidget {
  const ReminderManagerPage({super.key});

  @override
  ConsumerState<ReminderManagerPage> createState() =>
      _ReminderManagerPageState();
}

class _ReminderManagerPageState extends ConsumerState<ReminderManagerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(reminderNotifierProvider) is ReminderInitial) {
        ref.read(reminderNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(reminderNotifierProvider);
    final byType = ref.watch(remindersByTypeProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Smart Reminders',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              // History link
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Reminder History',
                onPressed: () => context.push(RouteNames.reminderHistory),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _ReminderHero(
                isDark: isDark,
                state: state,
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          switch (state) {
            ReminderLoading() || ReminderInitial() =>
              const SliverFillRemaining(
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ReminderError(:final message) => SliverFillRemaining(
                child: NotificationEmptyState(
                  message: message,
                  icon: Icons.error_outline_rounded,
                  action: FilledButton.icon(
                    onPressed: () =>
                        ref.read(reminderNotifierProvider.notifier).load(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
              ),
            ReminderLoaded() => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                sliver: SliverList.builder(
                  itemCount: ReminderType.values.length,
                  itemBuilder: (_, i) {
                    final type = ReminderType.values[i];
                    final reminder = byType[type];
                    return _ReminderSection(
                      type: type,
                      reminder: reminder,
                      isDark: isDark,
                    );
                  },
                ),
              ),
          },
        ],
      ),
    );
  }
}

// ── Reminder Hero ──────────────────────────────────────────────────────────────

class _ReminderHero extends StatelessWidget {
  const _ReminderHero({required this.isDark, required this.state});
  final bool isDark;
  final ReminderState state;

  @override
  Widget build(BuildContext context) {
    final active =
        state is ReminderLoaded ? (state as ReminderLoaded).activeCount : 0;
    final total = state is ReminderLoaded
        ? (state as ReminderLoaded).reminders.length
        : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1C2A3A)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C896), Color(0xFF00B4D8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C896).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.alarm_rounded,
                        color: AppColors.white, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$active of $total active',
                          style: AppTypography.headlineSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Manage your health reminders',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
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

// ── Reminder Section ──────────────────────────────────────────────────────────

class _ReminderSection extends ConsumerWidget {
  const _ReminderSection({
    required this.type,
    required this.reminder,
    required this.isDark,
  });

  final ReminderType type;
  final ReminderEntity? reminder;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reminderNotifierProvider.notifier);

    if (reminder == null) {
      // No reminder configured for this type — show "Add" tile
      return _AddReminderTile(
        type: type,
        isDark: isDark,
        onAdd: () => _showReminderSheet(context, ref, type, null),
      );
    }

    return ReminderCard(
      key: ValueKey(reminder!.id),
      reminder: reminder!,
      onToggle: () => notifier.toggle(reminder!.id),
      onEditTime: () => _showReminderSheet(context, ref, type, reminder),
      onSnooze: () => _showSnoozeDialog(context, ref, reminder!.id),
      onSkip: () => notifier.skip(reminder!.id),
      onDelete: () => _showDeleteDialog(context, ref, reminder!.id, type.label),
    );
  }

  void _showReminderSheet(
    BuildContext context,
    WidgetRef ref,
    ReminderType type,
    ReminderEntity? existing,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderEditSheet(
        type: type,
        existing: existing,
        onSave: (r) => ref.read(reminderNotifierProvider.notifier).save(r),
      ),
    );
  }

  void _showSnoozeDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: const Text('Snooze for how long?'),
        actions: [5, 10, 15, 30].map((min) {
          return TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(reminderNotifierProvider.notifier)
                  .snooze(id, minutes: min);
            },
            child: Text('$min min'),
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "$name" Reminder?'),
        content: const Text(
            'This will permanently remove this reminder and cancel all scheduled alerts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(reminderNotifierProvider.notifier).delete(id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddReminderTile extends StatelessWidget {
  const _AddReminderTile({
    required this.type,
    required this.isDark,
    required this.onAdd,
  });

  final ReminderType type;
  final bool isDark;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: type.color.withValues(alpha: 0.15),
          width: AppSpacing.borderThin,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(type.icon, color: type.color.withValues(alpha: 0.5), size: 22),
        ),
        title: Text(
          type.label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Tap to configure',
          style: AppTypography.captionText.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark.withValues(alpha: 0.6)
                : AppColors.textSecondaryLight.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.add_circle_outline_rounded,
          color: type.color.withValues(alpha: 0.6),
        ),
        onTap: onAdd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    );
  }
}

// ── Reminder Edit Bottom Sheet ─────────────────────────────────────────────────

class _ReminderEditSheet extends StatefulWidget {
  const _ReminderEditSheet({
    required this.type,
    required this.onSave,
    this.existing,
  });

  final ReminderType type;
  final ReminderEntity? existing;
  final ValueChanged<ReminderEntity> onSave;

  @override
  State<_ReminderEditSheet> createState() => _ReminderEditSheetState();
}

class _ReminderEditSheetState extends State<_ReminderEditSheet> {
  late TimeOfDay _time;
  late RepeatSchedule _repeat;
  late List<bool> _activeDays;
  late ReminderPriority _priority;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _time = e?.scheduledTime ?? const TimeOfDay(hour: 8, minute: 0);
    _repeat = e?.repeatSchedule ?? RepeatSchedule.daily;
    _activeDays = e?.activeDays ??
        [true, true, true, true, true, true, true];
    _priority = e?.priority ?? ReminderPriority.normal;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.type.color;
    final isNew = widget.existing == null;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl,
              MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(widget.type.icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNew
                              ? 'Add ${widget.type.label} Reminder'
                              : 'Edit ${widget.type.label} Reminder',
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.type.label,
                          style: AppTypography.captionText
                              .copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Time picker
              _SectionLabel('Reminder Time', isDark: isDark),
              const SizedBox(height: AppSpacing.xs),
              TimePickerTile(
                label: 'Alert Time',
                time: _time,
                color: color,
                onChanged: (t) => setState(() => _time = t),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Repeat schedule
              _SectionLabel('Repeat Schedule', isDark: isDark),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: RepeatSchedule.values.map((r) {
                  final isSelected = _repeat == r;
                  return GestureDetector(
                    onTap: () => setState(() => _repeat = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        r.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Days selector (custom only)
              if (_repeat == RepeatSchedule.custom) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel('Active Days', isDark: isDark),
                const SizedBox(height: AppSpacing.sm),
                DaysOfWeekSelector(
                  activeDays: _activeDays,
                  color: color,
                  onChanged: (d) => setState(() => _activeDays = d),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Priority
              _SectionLabel('Priority', isDark: isDark),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: ReminderPriority.values.map((p) {
                  final isSelected = _priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          p.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Save
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(
                          isNew ? 'Add Reminder' : 'Save Changes',
                          style: AppTypography.labelLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final existing = widget.existing;
    final reminder = ReminderEntity(
      id: existing?.id ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
      type: widget.type,
      title: existing?.title ?? '${widget.type.label} Reminder',
      body: existing?.body ?? 'Your ${widget.type.label.toLowerCase()} reminder is due.',
      scheduledTime: _time,
      repeatSchedule: _repeat,
      priority: _priority,
      status: ReminderStatus.active,
      activeDays: _activeDays,
    );
    widget.onSave(reminder);
    if (mounted) Navigator.of(context).pop();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.overline.copyWith(
        color: AppColors.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
