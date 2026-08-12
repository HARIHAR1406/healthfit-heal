import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Category grouping for suggested prompts.
enum PromptCategory {
  all,
  health,
  fitness,
  nutrition,
  mentalWellness,
  sleep,
  lifestyle,
}

extension PromptCategoryX on PromptCategory {
  String get label => switch (this) {
        PromptCategory.all => 'All',
        PromptCategory.health => 'Health',
        PromptCategory.fitness => 'Fitness',
        PromptCategory.nutrition => 'Nutrition',
        PromptCategory.mentalWellness => 'Mental',
        PromptCategory.sleep => 'Sleep',
        PromptCategory.lifestyle => 'Lifestyle',
      };

  String get emoji => switch (this) {
        PromptCategory.all => '✨',
        PromptCategory.health => '❤️',
        PromptCategory.fitness => '💪',
        PromptCategory.nutrition => '🥗',
        PromptCategory.mentalWellness => '🧠',
        PromptCategory.sleep => '😴',
        PromptCategory.lifestyle => '🌿',
      };

  Color get color => switch (this) {
        PromptCategory.all => const Color(0xFF6C63FF),
        PromptCategory.health => const Color(0xFFFF6B6B),
        PromptCategory.fitness => const Color(0xFF00C896),
        PromptCategory.nutrition => const Color(0xFFFFBF00),
        PromptCategory.mentalWellness => const Color(0xFF6C63FF),
        PromptCategory.sleep => const Color(0xFF00B4D8),
        PromptCategory.lifestyle => const Color(0xFF4CAF50),
      };
}

// ── Entity ────────────────────────────────────────────────────────────────────

/// A suggested prompt that can be tapped to start a conversation.
class SuggestedPromptEntity {
  const SuggestedPromptEntity({
    required this.id,
    required this.text,
    required this.category,
    required this.icon,
    required this.color,
    this.description,
    this.isPopular = false,
  });

  final String id;
  final String text;
  final PromptCategory category;
  final IconData icon;
  final Color color;
  final String? description;
  final bool isPopular;
}

