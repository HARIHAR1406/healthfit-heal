import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/medication_entity.dart';
import '../providers/medication_providers.dart';
import '../providers/medication_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION DASHBOARD PAGE
// ══════════════════════════════════════════════════════════════════════════════

class MedicationDashboardPage extends ConsumerStatefulWidget {
  const MedicationDashboardPage({super.key});

  @override
  ConsumerState<MedicationDashboardPage> createState() =>
      _MedicationDashboardPageState();
}

class _MedicationDashboardPageState
    extends ConsumerState<MedicationDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(medicationNotifierProvider) is MedicationInitial) {
        ref.read(medicationNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(medicationNotifierProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Medications',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                color: AppColors.primary,
                onPressed: () => _showAddMedicationSheet(context),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _MedHeroBanner(isDark: isDark),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          switch (state) {
            MedicationLoading() => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            MedicationError(:final message) => SliverFillRemaining(
                child: _ErrorView(
                  message: message,
                  onRetry: () =>
                      ref.read(medicationNotifierProvider.notifier).load(),
                ),
              ),
            MedicationLoaded(:final summary) => SliverList(
                delegate: SliverChildListDelegate([
                  // Adherence ring + stats
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _AdherenceCard(summary: summary, isDark: isDark),
                  ),

                  // Today's schedule
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: _TodaySchedule(
                        summary: summary, isDark: isDark),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // All medications
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: _MedicationList(summary: summary, isDark: isDark),
                  ),
                  const SizedBox(height: AppSpacing.massive),
                ]),
              ),
            _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
          },
        ],
      ),

      // FAB: add medication
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text(
          'Add Medication',
          style: AppTypography.labelLarge.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  void _showAddMedicationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMedicationSheet(),
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────────────────────────

class _MedHeroBanner extends StatelessWidget {
  const _MedHeroBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1B2A), const Color(0xFF1A2A3A)]
              : [const Color(0xFFE3F2FD), const Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxxl, AppSpacing.xl, AppSpacing.lg),
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
                        colors: [
                          Color(0xFF2196F3),
                          Color(0xFF00B4D8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Tracker',
                          style: AppTypography.headlineSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Stay on track with your medications',
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

// ── Adherence Card ─────────────────────────────────────────────────────────────

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard({required this.summary, required this.isDark});
  final MedicationSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final adherencePct = (summary.adherenceRate * 100).toInt();
    final color = adherencePct >= 80
        ? AppColors.primary
        : adherencePct >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Adherence ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: summary.adherenceRate),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 8,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    Text(
                      '$adherencePct%',
                      style: AppTypography.titleMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30-Day Adherence',
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adherencePct >= 80
                          ? 'Excellent! Keep it up 🎉'
                          : adherencePct >= 60
                              ? 'Good progress — stay consistent'
                              : 'Needs improvement — set reminders',
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
          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              _StatBubble(
                  label: 'Active',
                  value: '${summary.activeMedications}',
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _StatBubble(
                  label: 'Taken Today',
                  value: '${summary.takenToday}',
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _StatBubble(
                  label: 'Upcoming',
                  value: '${summary.upcomingToday}',
                  color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              _StatBubble(
                  label: 'Missed',
                  value: '${summary.missedToday}',
                  color: summary.missedToday > 0
                      ? AppColors.error
                      : AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTypography.captionText.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's Schedule ──────────────────────────────────────────────────────────

class _TodaySchedule extends ConsumerWidget {
  const _TodaySchedule({required this.summary, required this.isDark});
  final MedicationSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final doseLogState = ref.watch(doseLogNotifierProvider);
    final activeMeds = summary.medications.where((m) => m.isActive).toList();

    // Build a flat list of today's doses
    final todayDoses = <_ScheduledDose>[];
    for (final med in activeMeds) {
      for (final hour in med.scheduledTimes) {
        final time = DateTime(now.year, now.month, now.day, hour);
        todayDoses.add(_ScheduledDose(medication: med, scheduledAt: time));
      }
    }
    todayDoses.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: AppTypography.titleMedium.copyWith(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (todayDoses.isEmpty)
          _EmptySchedule(isDark: isDark)
        else
          ...todayDoses.map((dose) => _DoseTile(
                dose: dose,
                isDark: isDark,
                isLogging: doseLogState is DoseLogLogging &&
                    doseLogState.medicationId == dose.medication.id,
                onTake: () => ref.read(doseLogNotifierProvider.notifier).logDose(
                      medicationId: dose.medication.id,
                      scheduledAt: dose.scheduledAt,
                      status: DoseStatus.taken,
                    ),
                onSkip: () => ref.read(doseLogNotifierProvider.notifier).logDose(
                      medicationId: dose.medication.id,
                      scheduledAt: dose.scheduledAt,
                      status: DoseStatus.skipped,
                    ),
              )),
      ],
    );
  }
}

class _ScheduledDose {
  const _ScheduledDose({required this.medication, required this.scheduledAt});
  final MedicationEntity medication;
  final DateTime scheduledAt;
}

class _DoseTile extends StatelessWidget {
  const _DoseTile({
    required this.dose,
    required this.isDark,
    required this.isLogging,
    required this.onTake,
    required this.onSkip,
  });

  final _ScheduledDose dose;
  final bool isDark;
  final bool isLogging;
  final VoidCallback onTake;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = dose.scheduledAt.isBefore(now);
    final timeLabel =
        '${dose.scheduledAt.hour.toString().padLeft(2, '0')}:${dose.scheduledAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: dose.medication.color.withOpacity(0.2),
          width: AppSpacing.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medication icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dose.medication.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(dose.medication.form.icon,
                color: dose.medication.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose.medication.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${dose.medication.dosage} · $timeLabel',
                  style: AppTypography.captionText.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (isLogging)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Skip
                IconButton(
                  icon: Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.warning.withOpacity(0.8), size: 20),
                  onPressed: onSkip,
                  tooltip: 'Skip',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                // Take
                FilledButton(
                  onPressed: onTake,
                  style: FilledButton.styleFrom(
                    backgroundColor: dose.medication.color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Take',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No doses scheduled for today',
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

// ── Medication List ────────────────────────────────────────────────────────────

class _MedicationList extends ConsumerWidget {
  const _MedicationList({required this.summary, required this.isDark});
  final MedicationSummary summary;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'All Medications',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${summary.medications.length} total',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...summary.medications.map((med) => _MedicationCard(
              medication: med,
              isDark: isDark,
              onToggle: () => ref
                  .read(medicationNotifierProvider.notifier)
                  .toggleActive(med),
              onDelete: () => _showDeleteDialog(context, ref, med),
            )),
      ],
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, MedicationEntity med) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${med.name}?'),
        content:
            const Text('This will remove the medication from your tracker.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(medicationNotifierProvider.notifier)
                  .deleteMedication(med.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
  });

  final MedicationEntity medication;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timesLabel = medication.scheduledTimes
        .map((h) => '${h.toString().padLeft(2, '0')}:00')
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: medication.isActive
              ? medication.color.withOpacity(0.2)
              : AppColors.dividerLight,
          width: AppSpacing.borderThin,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: medication.isActive
                ? medication.color.withOpacity(0.15)
                : AppColors.dividerLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            medication.form.icon,
            color:
                medication.isActive ? medication.color : AppColors.textSecondaryLight,
            size: 22,
          ),
        ),
        title: Text(
          medication.name,
          style: AppTypography.titleSmall.copyWith(
            color: medication.isActive
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
            decoration: medication.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${medication.dosage} · ${medication.frequency.label}',
              style: AppTypography.captionText.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            if (timesLabel.isNotEmpty)
              Text(
                '⏰ $timesLabel',
                style: AppTypography.captionText.copyWith(
                  color: medication.color.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch.adaptive(
              value: medication.isActive,
              onChanged: (_) => onToggle(),
              activeColor: medication.color,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppColors.error.withOpacity(0.6), size: 18),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Medication Bottom Sheet ────────────────────────────────────────────────

class _AddMedicationSheet extends StatelessWidget {
  const _AddMedicationSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Text(
                  'Add Medication',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Full medication management coming soon.\nYou\'ll be able to add prescriptions, set reminders, and track adherence.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '🚀 Coming in v1.1',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error.withOpacity(0.6)),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
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

