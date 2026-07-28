import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/message_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CHAT BUBBLE
// ══════════════════════════════════════════════════════════════════════════════

/// Animated chat bubble for user and assistant messages.
///
/// Features:
/// - Slide + fade entrance animation
/// - Lightweight markdown rendering (bold, italic, code)
/// - Copy to clipboard on long-press
/// - Regenerate / bookmark actions (assistant only)
/// - Error state visual
class ChatBubble extends StatefulWidget {
  const ChatBubble({
    required this.message,
    required this.isDark,
    super.key,
    this.onRegenerate,
    this.onCopy,
    this.onBookmark,
    this.showAvatar = true,
    this.animateIn = true,
  });

  final MessageEntity message;
  final bool isDark;
  final VoidCallback? onRegenerate;
  final VoidCallback? onCopy;
  final VoidCallback? onBookmark;
  final bool showAvatar;
  final bool animateIn;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: widget.message.isUser
          ? const Offset(0.15, 0)
          : const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.animateIn) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    HapticFeedback.lightImpact();
    widget.onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.only(
            left: isUser ? 48 : 0,
            right: isUser ? 0 : 48,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser && widget.showAvatar) ...[
                _SmallAIAvatar(isDark: widget.isDark),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showActions(context),
                  child: _BubbleContent(
                    message: widget.message,
                    isUser: isUser,
                    isDark: widget.isDark,
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BubbleActionsSheet(
        message: widget.message,
        onCopy: _copyContent,
        onRegenerate: widget.onRegenerate,
        onBookmark: widget.onBookmark,
        isDark: widget.isDark,
      ),
    );
  }
}

// ── Bubble Content ────────────────────────────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.isUser,
    required this.isDark,
  });

  final MessageEntity message;
  final bool isUser;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isUser
        ? AppColors.primary
        : (isDark ? const Color(0xFF1E2140) : const Color(0xFFF0F4FF));
    final textColor =
        isUser ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: message.isError ? AppColors.error.withValues(alpha: 0.12) : bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppSpacing.radiusLg),
          topRight: const Radius.circular(AppSpacing.radiusLg),
          bottomLeft: Radius.circular(isUser ? AppSpacing.radiusLg : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusLg),
        ),
        border: message.isError
            ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isError)
            Row(children: [
              Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              Text('Error',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.error)),
              const SizedBox(height: 4),
            ]),
          _MarkdownContent(
            content: message.content.isEmpty && message.isStreaming
                ? '▌'
                : message.content,
            textColor: textColor,
            isUser: isUser,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: AppTypography.captionText.copyWith(
                  color: textColor.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
              if (!isUser && message.isBookmarked) ...[
                const SizedBox(width: 4),
                Icon(Icons.bookmark_rounded,
                    size: 12, color: textColor.withValues(alpha: 0.7)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Markdown Content ──────────────────────────────────────────────────────────

class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({
    required this.content,
    required this.textColor,
    required this.isUser,
  });

  final String content;
  final Color textColor;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    // For user messages or short content, use simple styled text
    if (isUser || !content.contains('\n')) {
      return RichText(
        text: TextSpan(
          children: MarkdownParser.parse(
            content,
            baseStyle: AppTypography.bodyMedium.copyWith(color: textColor),
            boldStyle: AppTypography.bodyMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
            codeStyle: AppTypography.bodyMedium.copyWith(
              color: textColor,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    // For AI multi-line content, use block parser
    final blocks = MarkdownParser.parseBlocks(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        return _buildBlock(block, textColor);
      }).toList(),
    );
  }

  Widget _buildBlock(ContentBlock block, Color textColor) {
    final baseStyle = AppTypography.bodyMedium.copyWith(color: textColor);

    if (block is HeadingBlock) {
      final size = switch (block.level) {
        1 => 18.0,
        2 => 16.0,
        _ => 15.0,
      };
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          block.text,
          style: baseStyle.copyWith(
            fontSize: size,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (block is BulletBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: MarkdownParser.parse(
                          item,
                          baseStyle: baseStyle,
                          boldStyle:
                              baseStyle.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    if (block is NumberedBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key + 1}. ',
                      style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: MarkdownParser.parse(
                          e.value,
                          baseStyle: baseStyle,
                          boldStyle:
                              baseStyle.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    if (block is CodeBlock) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.language.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  block.language,
                  style: AppTypography.captionText.copyWith(
                    color: textColor.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            SelectableText(
              block.code,
              style: AppTypography.bodySmall.copyWith(
                color: textColor.withValues(alpha: 0.9),
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // ParagraphBlock
    final paragraph = block as ParagraphBlock;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: MarkdownParser.parse(
            paragraph.text,
            baseStyle: baseStyle,
            boldStyle: baseStyle.copyWith(fontWeight: FontWeight.w700),
            italicStyle:
                baseStyle.copyWith(fontStyle: FontStyle.italic),
            codeStyle: baseStyle.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}

// ── Bubble Action Sheet ───────────────────────────────────────────────────────

class _BubbleActionsSheet extends StatelessWidget {
  const _BubbleActionsSheet({
    required this.message,
    required this.isDark,
    this.onCopy,
    this.onRegenerate,
    this.onBookmark,
  });

  final MessageEntity message;
  final bool isDark;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1F3A) : Colors.white;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.copy_rounded,
            label: 'Copy message',
            onTap: () {
              Navigator.pop(context);
              onCopy?.call();
            },
          ),
          if (message.isAssistant) ...[
            _ActionTile(
              icon: message.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: message.isBookmarked ? 'Remove bookmark' : 'Bookmark',
              onTap: () {
                Navigator.pop(context);
                onBookmark?.call();
              },
            ),
            _ActionTile(
              icon: Icons.refresh_rounded,
              label: 'Regenerate response',
              onTap: () {
                Navigator.pop(context);
                onRegenerate?.call();
              },
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
    );
  }
}

// ── Small AI Avatar (inline) ──────────────────────────────────────────────────

class _SmallAIAvatar extends StatelessWidget {
  const _SmallAIAvatar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
