import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/ai_providers.dart';
import '../widgets/insight_coach_widgets.dart';

/// AI Coach hub — 5 coaching domain cards + how-it-works section.
class AICoachPage extends ConsumerWidget {
  const AICoachPage({super.key});

  static const _coaches = [
    CoachType.health,
    CoachType.fitness,
    CoachType.nutrition,
    CoachType.lifestyle,
    CoachType.habit,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = ref.watch(selectedCoachTypeProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'AI Coaches',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            _CoachHero(isDark: isDark),
            const SizedBox(height: AppSpacing.xl),

            // Section title
            Text(
              'Choose Your Coach',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2-column grid of coach cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.85,
              ),
              itemCount: _coaches.length,
              itemBuilder: (_, i) {
                final coach = _coaches[i];
                return CoachCard(
                  coachType: coach,
                  isDark: isDark,
                  isSelected: selected == coach,
                  onTap: () {
                    ref.read(selectedCoachTypeProvider.notifier).state =
                        coach;
                    _startCoachChat(context, coach);
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // How it works section
            _HowItWorks(isDark: isDark),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  void _startCoachChat(BuildContext context, CoachType coach) {
    context.push(
      '/ai-assistant/coach/${coach.name}/chat',
    );
  }
}

// ── Coach Hero ────────────────────────────────────────────────────────────────

class _CoachHero extends StatelessWidget {
  const _CoachHero({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1040), const Color(0xFF0D1224)]
              : [const Color(0xFFEEEBFF), const Color(0xFFF5F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Personal AI Team',
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Select a specialist coach to get personalised, domain-specific guidance powered by AI.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Text('🧑‍⚕️', style: TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        icon: Icons.touch_app_rounded,
        color: const Color(0xFF6C63FF),
        title: 'Choose a Coach',
        desc: 'Select the domain that matches your goal.',
      ),
      (
        icon: Icons.chat_rounded,
        color: const Color(0xFF00C896),
        title: 'Ask Your Question',
        desc: 'Type freely or pick from suggested prompts.',
      ),
      (
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFFF6B6B),
        title: 'Get Expert Advice',
        desc: 'Receive personalised, structured coaching.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...steps.asMap().entries.map((e) {
          final step = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, color: step.color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}. ${step.title}',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        step.desc,
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
          );
        }),
      ],
    );
  }
}
