import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/suggested_prompt_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AI AVATAR
// ══════════════════════════════════════════════════════════════════════════════

/// Large AI avatar with gradient, sparkle icon, and animated online indicator.
class AIAvatar extends StatefulWidget {
  const AIAvatar({
    super.key,
    this.size = 72,
    this.isOnline = true,
    this.animate = true,
  });

  final double size;
  final bool isOnline;
  final bool animate;

  @override
  State<AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<AIAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animate && widget.isOnline) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glow ring
        if (widget.isOnline)
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: widget.size + 8,
              height: widget.size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ),

        // Avatar
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C88FF), Color(0xFFFF6BB5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: widget.size * 0.45,
            color: Colors.white,
          ),
        ),

        // Online dot
        if (widget.isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF00C896),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TYPING INDICATOR
// ══════════════════════════════════════════════════════════════════════════════

/// Animated 3-dot typing indicator shown while AI is generating a response.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.isDark = false});
  final bool isDark;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _anims = _ctrls.map((c) {
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    _startStagger();
  }

  void _startStagger() {
    for (var i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor =
        widget.isDark ? Colors.white70 : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF1E2140)
                  : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _anims[i],
                  builder: (_, __) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      transform: Matrix4.translationValues(
                          0, _anims[i].value, 0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUGGESTION CHIP
// ══════════════════════════════════════════════════════════════════════════════

/// Tappable category-coloured suggestion chip for the AI home and prompt pages.
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    required this.prompt,
    required this.onTap,
    super.key,
    this.compact = false,
  });

  final SuggestedPromptEntity prompt;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: prompt.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: prompt.color.withValues(alpha: 0.3),
            width: AppSpacing.borderThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(prompt.icon, color: prompt.color, size: compact ? 14 : 16),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                prompt.text,
                style: AppTypography.bodySmall.copyWith(
                  color: prompt.color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY CHAT WIDGET
// ══════════════════════════════════════════════════════════════════════════════

/// Displayed when a conversation has no messages yet.
class EmptyChatWidget extends StatelessWidget {
  const EmptyChatWidget({
    required this.coachType,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.isDark,
    super.key,
  });

  final dynamic coachType; // CoachType
  final List<SuggestedPromptEntity> suggestions;
  final ValueChanged<String> onSuggestionTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Avatar
            const AIAvatar(size: 80),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              coachType.label as String,
              style: AppTypography.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your personal AI health companion.\nAsk me anything!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Suggestions
            if (suggestions.isNotEmpty) ...[
              Text(
                'Try asking…',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: suggestions.take(4).map((p) {
                  return SuggestionChip(
                    prompt: p,
                    onTap: () => onSuggestionTap(p.text),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHAT COMPOSER
// ══════════════════════════════════════════════════════════════════════════════

/// Multi-line text input bar with send + voice buttons.
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    required this.onSend,
    required this.onVoice,
    required this.isDark,
    super.key,
    this.isLoading = false,
    this.initialText = '',
  });

  final ValueChanged<String> onSend;
  final VoidCallback onVoice;
  final bool isDark;
  final bool isLoading;
  final String initialText;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  late final TextEditingController _ctrl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
    _hasText = widget.initialText.isNotEmpty;
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    _ctrl.clear();
    setState(() => _hasText = false);
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF151929) : Colors.white;
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Voice button
            IconButton(
              icon: Icon(
                Icons.mic_rounded,
                color: widget.isDark
                    ? Colors.white54
                    : AppColors.textSecondaryLight,
              ),
              onPressed: widget.onVoice,
              tooltip: 'Voice input (coming soon)',
              style: IconButton.styleFrom(
                backgroundColor: widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF1E2140)
                      : const Color(0xFFF5F7FF),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium.copyWith(
                    color: widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask your AI Coach…',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: widget.isDark
                          ? Colors.white38
                          : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: (_hasText && !widget.isLoading) ? _send : null,
                icon: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: _hasText ? AppColors.primary : Colors.grey,
                      ),
                style: IconButton.styleFrom(
                  backgroundColor: _hasText && !widget.isLoading
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CATEGORY CHIP ROW
// ══════════════════════════════════════════════════════════════════════════════

/// Horizontal scrolling row of category filter chips.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    required this.categories,
    required this.activeCategory,
    required this.onCategorySelected,
    super.key,
  });

  final List<PromptCategory> categories;
  final PromptCategory activeCategory;
  final ValueChanged<PromptCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: categories.map((cat) {
          final isActive = cat == activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text('${cat.emoji} ${cat.label}'),
                selected: isActive,
                onSelected: (_) => onCategorySelected(cat),
                selectedColor: cat.color.withValues(alpha: 0.2),
                backgroundColor: Colors.transparent,
                checkmarkColor: cat.color,
                side: BorderSide(
                  color: isActive
                      ? cat.color
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isActive ? 1.5 : 1,
                ),
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: isActive ? cat.color : null,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
