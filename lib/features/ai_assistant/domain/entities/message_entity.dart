import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Role of a message in the conversation.
enum MessageRole {
  user,
  assistant,
  system,
}

/// Processing status of a message.
enum MessageStatus {
  /// Message has been sent and is waiting for a response.
  sending,

  /// Message has been successfully delivered / generated.
  delivered,

  /// Streaming in progress (assistant token-by-token).
  streaming,

  /// Message generation failed.
  error,
}

// ── Entity ────────────────────────────────────────────────────────────────────

/// A single message in an AI conversation.
class MessageEntity {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.delivered,
    this.isBookmarked = false,
    this.errorMessage,
    this.tokensUsed,
  });

  final String id;
  final String conversationId;
  final MessageRole role;

  /// Raw content — may contain lightweight markdown.
  final String content;

  final DateTime timestamp;
  final MessageStatus status;
  final bool isBookmarked;

  /// Set when [status] is [MessageStatus.error].
  final String? errorMessage;

  /// Optional token count for cost tracking (future use).
  final int? tokensUsed;

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  bool get isStreaming => status == MessageStatus.streaming;
  bool get isError => status == MessageStatus.error;

  /// Truncated preview for list tiles.
  String get preview {
    if (content.length <= 80) return content;
    return '${content.substring(0, 77)}…';
  }

  // ── Factory / Copy ─────────────────────────────────────────────────────────

  factory MessageEntity.user({
    required String id,
    required String conversationId,
    required String content,
  }) =>
      MessageEntity(
        id: id,
        conversationId: conversationId,
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

  factory MessageEntity.assistant({
    required String id,
    required String conversationId,
    required String content,
    MessageStatus status = MessageStatus.delivered,
  }) =>
      MessageEntity(
        id: id,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        status: status,
      );

  factory MessageEntity.streamingPlaceholder({
    required String id,
    required String conversationId,
  }) =>
      MessageEntity(
        id: id,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
      );

  MessageEntity copyWith({
    String? content,
    MessageStatus? status,
    bool? isBookmarked,
    String? errorMessage,
    int? tokensUsed,
  }) =>
      MessageEntity(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        status: status ?? this.status,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        errorMessage: errorMessage ?? this.errorMessage,
        tokensUsed: tokensUsed ?? this.tokensUsed,
      );
}

// ── Lightweight Markdown Span Parser ─────────────────────────────────────────

/// Parses a subset of markdown into [InlineSpan]s for [RichText].
///
/// Supported syntax:
/// - `**bold**` or `__bold__`
/// - `*italic*` or `_italic_`
/// - `` `code` ``
/// - Plain text (fallback)
class MarkdownParser {
  const MarkdownParser._();

  static final _boldPattern = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');
  static final _italicPattern = RegExp(r'\*(.+?)\*|_(.+?)_');
  static final _codePattern = RegExp(r'`(.+?)`');
  static final _combinedPattern = RegExp(
    r'\*\*(.+?)\*\*|__(.+?)__|`(.+?)`|\*(.+?)\*|_(.+?)_',
  );

  /// Returns a list of [InlineSpan]s for use in [RichText].
  static List<InlineSpan> parse(
    String text, {
    required TextStyle baseStyle,
    TextStyle? boldStyle,
    TextStyle? italicStyle,
    TextStyle? codeStyle,
  }) {
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _combinedPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final fullMatch = match.group(0)!;

      if (fullMatch.startsWith('**') || fullMatch.startsWith('__')) {
        final content = match.group(1) ?? match.group(2) ?? '';
        spans.add(TextSpan(
          text: content,
          style: boldStyle ?? baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (fullMatch.startsWith('`')) {
        final content = match.group(3) ?? '';
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              content,
              style: (codeStyle ?? baseStyle).copyWith(
                fontFamily: 'monospace',
                fontSize: (baseStyle.fontSize ?? 14) - 1,
              ),
            ),
          ),
        ));
      } else {
        final content = match.group(4) ?? match.group(5) ?? '';
        spans.add(TextSpan(
          text: content,
          style: italicStyle ??
              baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  /// Splits content into blocks: paragraphs, bullets, code blocks, tables.
  static List<_ContentBlock> parseBlocks(String content) {
    final blocks = <_ContentBlock>[];
    final lines = content.split('\n');
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Fenced code block
      if (line.trim().startsWith('```')) {
        final lang = line.trim().replaceFirst('```', '').trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(_CodeBlock(code: codeLines.join('\n'), language: lang));
        i++;
        continue;
      }

      // Bullet list item
      if (line.startsWith('- ') || line.startsWith('• ')) {
        final bullets = <String>[];
        while (i < lines.length &&
            (lines[i].startsWith('- ') || lines[i].startsWith('• '))) {
          bullets.add(lines[i].substring(2));
          i++;
        }
        blocks.add(_BulletBlock(items: bullets));
        continue;
      }

      // Numbered list
      if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^\d+\. ').hasMatch(lines[i])) {
          items.add(RegExp(r'^\d+\. (.+)').firstMatch(lines[i])?.group(1) ?? lines[i]);
          i++;
        }
        blocks.add(_NumberedBlock(items: items));
        continue;
      }

      // Heading
      if (line.startsWith('### ')) {
        blocks.add(_HeadingBlock(text: line.substring(4), level: 3));
        i++;
        continue;
      }
      if (line.startsWith('## ')) {
        blocks.add(_HeadingBlock(text: line.substring(3), level: 2));
        i++;
        continue;
      }
      if (line.startsWith('# ')) {
        blocks.add(_HeadingBlock(text: line.substring(2), level: 1));
        i++;
        continue;
      }

      // Empty line
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Plain paragraph
      final paragraphLines = <String>[];
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !lines[i].startsWith('- ') &&
          !lines[i].startsWith('• ') &&
          !lines[i].startsWith('```') &&
          !lines[i].startsWith('#') &&
          !RegExp(r'^\d+\. ').hasMatch(lines[i])) {
        paragraphLines.add(lines[i]);
        i++;
      }
      if (paragraphLines.isNotEmpty) {
        blocks.add(_ParagraphBlock(text: paragraphLines.join(' ')));
      }
    }

    return blocks;
  }
}

// ── Content Block Types ───────────────────────────────────────────────────────

abstract class _ContentBlock {
  const _ContentBlock();
}

class _ParagraphBlock extends _ContentBlock {
  const _ParagraphBlock({required this.text});
  final String text;
}

class _BulletBlock extends _ContentBlock {
  const _BulletBlock({required this.items});
  final List<String> items;
}

class _NumberedBlock extends _ContentBlock {
  const _NumberedBlock({required this.items});
  final List<String> items;
}

class _CodeBlock extends _ContentBlock {
  const _CodeBlock({required this.code, this.language = ''});
  final String code;
  final String language;
}

class _HeadingBlock extends _ContentBlock {
  const _HeadingBlock({required this.text, required this.level});
  final String text;
  final int level;
}

// Export block types for use in widgets
typedef ContentBlock = _ContentBlock;
typedef ParagraphBlock = _ParagraphBlock;
typedef BulletBlock = _BulletBlock;
typedef NumberedBlock = _NumberedBlock;
typedef CodeBlock = _CodeBlock;
typedef HeadingBlock = _HeadingBlock;

