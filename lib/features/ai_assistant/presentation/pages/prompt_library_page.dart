import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/suggested_prompt_entity.dart';
import '../providers/ai_providers.dart';
import '../providers/ai_state.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/insight_coach_widgets.dart';

/// Categorised prompt library — 60+ prompts across 6 categories.
class PromptLibraryPage extends ConsumerWidget {
  const PromptLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promptState = ref.watch(promptLibraryProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          'Prompt Library',
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: TextField(
              onChanged: (q) =>
                  ref.read(promptLibraryProvider.notifier).setQuery(q),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Search prompts…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1F3A)
                    : const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.md),
              ),
            ),
          ),

          // Category filter
          CategoryChipRow(
            categories: PromptCategory.values,
            activeCategory: promptState is PromptLibraryLoaded
                ? promptState.activeCategory
                : PromptCategory.all,
            onCategorySelected: (cat) =>
                ref.read(promptLibraryProvider.notifier).setCategory(cat),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Grid
          Expanded(
            child: switch (promptState) {
              PromptLibraryLoading() =>
                const Center(child: CircularProgressIndicator()),
              PromptLibraryError(:final message) => Center(
                  child: Text(message,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error)),
                ),
              PromptLibraryLoaded() => _PromptGrid(isDark: isDark),
            },
          ),
        ],
      ),
    );
  }
}

// ── Prompt Grid ───────────────────────────────────────────────────────────────

class _PromptGrid extends ConsumerWidget {
  const _PromptGrid({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(filteredPromptsProvider);

    if (prompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No prompts found',
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.9,
      ),
      itemCount: prompts.length,
      itemBuilder: (_, i) {
        final prompt = prompts[i];
        return PromptCard(
          prompt: prompt,
          isDark: isDark,
          onTap: () => _openChat(context, prompt),
        );
      },
    );
  }

  void _openChat(BuildContext context, SuggestedPromptEntity prompt) {
    context.push(
      '/ai-assistant/chat/new',
      extra: {'initialPrompt': prompt.text},
    );
  }
}

