import 'package:flutter/material.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/suggested_prompt_entity.dart';

/// Curated collection of prompt templates for the Prompt Library.
///
/// 60+ prompts across 6 categories. Tapping any prompt opens a new chat
/// pre-seeded with that text.
abstract final class PromptTemplates {
  // ── Health ─────────────────────────────────────────────────────────────────

  static const List<SuggestedPromptEntity> health = [
    SuggestedPromptEntity(
      id: 'h_01',
      text: 'What does my resting heart rate say about my health?',
      category: PromptCategory.health,
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF6B6B),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'h_02',
      text: 'How do I improve my blood pressure naturally?',
      category: PromptCategory.health,
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_03',
      text: 'What is a healthy BMI range for my age and height?',
      category: PromptCategory.health,
      icon: Icons.scale_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_04',
      text: 'Explain SpO2 levels and what they mean for my breathing.',
      category: PromptCategory.health,
      icon: Icons.air_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_05',
      text: 'What daily habits reduce the risk of type 2 diabetes?',
      category: PromptCategory.health,
      icon: Icons.bloodtype_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_06',
      text: 'How many steps per day is considered active and healthy?',
      category: PromptCategory.health,
      icon: Icons.directions_walk_rounded,
      color: Color(0xFFFF6B6B),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'h_07',
      text: 'What are the early signs of vitamin D deficiency?',
      category: PromptCategory.health,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_08',
      text: 'How can I strengthen my immune system naturally?',
      category: PromptCategory.health,
      icon: Icons.shield_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_09',
      text: 'What health metrics should I track every day?',
      category: PromptCategory.health,
      icon: Icons.bar_chart_rounded,
      color: Color(0xFFFF6B6B),
    ),
    SuggestedPromptEntity(
      id: 'h_10',
      text: 'How does stress impact my physical health markers?',
      category: PromptCategory.health,
      icon: Icons.psychology_rounded,
      color: Color(0xFFFF6B6B),
    ),
  ];

  // ── Fitness ────────────────────────────────────────────────────────────────

  static const List<SuggestedPromptEntity> fitness = [
    SuggestedPromptEntity(
      id: 'f_01',
      text: 'Design a 4-week beginner strength training plan for me.',
      category: PromptCategory.fitness,
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF00C896),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'f_02',
      text: 'What is the best way to lose fat while preserving muscle?',
      category: PromptCategory.fitness,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFF00C896),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'f_03',
      text: 'Explain progressive overload and how to apply it.',
      category: PromptCategory.fitness,
      icon: Icons.trending_up_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_04',
      text: 'Create a 30-minute home HIIT workout with no equipment.',
      category: PromptCategory.fitness,
      icon: Icons.timer_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_05',
      text: 'How many rest days per week should I take?',
      category: PromptCategory.fitness,
      icon: Icons.hotel_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_06',
      text: 'What is the ideal heart rate zone for fat burning?',
      category: PromptCategory.fitness,
      icon: Icons.favorite_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_07',
      text: 'How do I prevent workout injuries and recover faster?',
      category: PromptCategory.fitness,
      icon: Icons.healing_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_08',
      text: 'What stretches should I do before and after running?',
      category: PromptCategory.fitness,
      icon: Icons.directions_run_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_09',
      text: 'How do I track fitness progress without a scale?',
      category: PromptCategory.fitness,
      icon: Icons.straighten_rounded,
      color: Color(0xFF00C896),
    ),
    SuggestedPromptEntity(
      id: 'f_10',
      text: 'Build me a 5-day split workout routine for muscle gain.',
      category: PromptCategory.fitness,
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF00C896),
    ),
  ];

  // ── Nutrition ──────────────────────────────────────────────────────────────

  static const List<SuggestedPromptEntity> nutrition = [
    SuggestedPromptEntity(
      id: 'n_01',
      text: 'How much protein do I need to build muscle effectively?',
      category: PromptCategory.nutrition,
      icon: Icons.egg_rounded,
      color: Color(0xFFFFBF00),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'n_02',
      text: 'Create a 7-day high-protein meal plan for weight loss.',
      category: PromptCategory.nutrition,
      icon: Icons.restaurant_menu_rounded,
      color: Color(0xFFFFBF00),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'n_03',
      text: 'What are the best pre-workout foods for energy?',
      category: PromptCategory.nutrition,
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_04',
      text: 'Explain intermittent fasting and its benefits.',
      category: PromptCategory.nutrition,
      icon: Icons.schedule_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_05',
      text: 'What is a healthy macronutrient ratio for my goals?',
      category: PromptCategory.nutrition,
      icon: Icons.pie_chart_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_06',
      text: 'How much water should I drink based on my activity level?',
      category: PromptCategory.nutrition,
      icon: Icons.water_drop_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_07',
      text: 'What foods help reduce inflammation in the body?',
      category: PromptCategory.nutrition,
      icon: Icons.eco_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_08',
      text: 'Is creatine safe and how should I take it?',
      category: PromptCategory.nutrition,
      icon: Icons.science_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_09',
      text: 'What should I eat after a workout for optimal recovery?',
      category: PromptCategory.nutrition,
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFFBF00),
    ),
    SuggestedPromptEntity(
      id: 'n_10',
      text: 'How do I calculate my daily calorie needs (TDEE)?',
      category: PromptCategory.nutrition,
      icon: Icons.calculate_rounded,
      color: Color(0xFFFFBF00),
    ),
  ];

  // ── Mental Wellness ────────────────────────────────────────────────────────

  static const List<SuggestedPromptEntity> mentalWellness = [
    SuggestedPromptEntity(
      id: 'm_01',
      text: 'How can I reduce stress after a long work day?',
      category: PromptCategory.mentalWellness,
      icon: Icons.spa_rounded,
      color: Color(0xFF6C63FF),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'm_02',
      text: 'Teach me a 5-minute mindfulness breathing exercise.',
      category: PromptCategory.mentalWellness,
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF6C63FF),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'm_03',
      text: 'How does exercise improve mental health and mood?',
      category: PromptCategory.mentalWellness,
      icon: Icons.psychology_rounded,
      color: Color(0xFF6C63FF),
    ),
    SuggestedPromptEntity(
      id: 'm_04',
      text: 'What are evidence-based techniques for managing anxiety?',
      category: PromptCategory.mentalWellness,
      icon: Icons.healing_rounded,
      color: Color(0xFF6C63FF),
    ),
    SuggestedPromptEntity(
      id: 'm_05',
      text: 'How can I build emotional resilience over time?',
      category: PromptCategory.mentalWellness,
      icon: Icons.shield_rounded,
      color: Color(0xFF6C63FF),
    ),
    SuggestedPromptEntity(
      id: 'm_06',
      text: 'What daily habits improve focus and mental clarity?',
      category: PromptCategory.mentalWellness,
      icon: Icons.center_focus_strong_rounded,
      color: Color(0xFF6C63FF),
    ),
    SuggestedPromptEntity(
      id: 'm_07',
      text: 'How does journaling benefit mental health?',
      category: PromptCategory.mentalWellness,
      icon: Icons.edit_note_rounded,
      color: Color(0xFF6C63FF),
    ),
    SuggestedPromptEntity(
      id: 'm_08',
      text: 'Give me a 10-minute morning mindfulness routine.',
      category: PromptCategory.mentalWellness,
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFF6C63FF),
    ),
  ];

  // ── Sleep ──────────────────────────────────────────────────────────────────

  static const List<SuggestedPromptEntity> sleep = [
    SuggestedPromptEntity(
      id: 's_01',
      text: 'How much sleep do I need for optimal recovery?',
      category: PromptCategory.sleep,
      icon: Icons.bedtime_rounded,
      color: Color(0xFF00B4D8),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 's_02',
      text: 'What evening habits improve sleep quality?',
      category: PromptCategory.sleep,
      icon: Icons.nightlight_round,
      color: Color(0xFF00B4D8),
    ),
    SuggestedPromptEntity(
      id: 's_03',
      text: 'How does poor sleep affect my fitness and weight goals?',
      category: PromptCategory.sleep,
      icon: Icons.trending_down_rounded,
      color: Color(0xFF00B4D8),
    ),
    SuggestedPromptEntity(
      id: 's_04',
      text: 'What is sleep hygiene and how do I practice it?',
      category: PromptCategory.sleep,
      icon: Icons.clean_hands_rounded,
      color: Color(0xFF00B4D8),
    ),
    SuggestedPromptEntity(
      id: 's_05',
      text: 'Why do I feel tired even after 8 hours of sleep?',
      category: PromptCategory.sleep,
      icon: Icons.help_outline_rounded,
      color: Color(0xFF00B4D8),
    ),
    SuggestedPromptEntity(
      id: 's_06',
      text: 'How does screen time before bed affect melatonin?',
      category: PromptCategory.sleep,
      icon: Icons.phone_android_rounded,
      color: Color(0xFF00B4D8),
    ),
    SuggestedPromptEntity(
      id: 's_07',
      text: 'Create a 30-day better sleep challenge for me.',
      category: PromptCategory.sleep,
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF00B4D8),
    ),
    SuggestedPromptEntity(
      id: 's_08',
      text: 'What is the best pre-sleep nutrition for deep sleep?',
      category: PromptCategory.sleep,
      icon: Icons.restaurant_rounded,
      color: Color(0xFF00B4D8),
    ),
  ];

  // ── Lifestyle ──────────────────────────────────────────────────────────────

  static const List<SuggestedPromptEntity> lifestyle = [
    SuggestedPromptEntity(
      id: 'l_01',
      text: 'How do I build a consistent morning routine?',
      category: PromptCategory.lifestyle,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFF4CAF50),
      isPopular: true,
    ),
    SuggestedPromptEntity(
      id: 'l_02',
      text: 'What is the 1% better principle and how do I apply it?',
      category: PromptCategory.lifestyle,
      icon: Icons.upgrade_rounded,
      color: Color(0xFF4CAF50),
    ),
    SuggestedPromptEntity(
      id: 'l_03',
      text: 'How do I create and maintain healthy habits long-term?',
      category: PromptCategory.lifestyle,
      icon: Icons.repeat_rounded,
      color: Color(0xFF4CAF50),
    ),
    SuggestedPromptEntity(
      id: 'l_04',
      text: 'Design a balanced weekly schedule for health and productivity.',
      category: PromptCategory.lifestyle,
      icon: Icons.event_note_rounded,
      color: Color(0xFF4CAF50),
    ),
    SuggestedPromptEntity(
      id: 'l_05',
      text: 'How do I maintain fitness motivation when I feel lazy?',
      category: PromptCategory.lifestyle,
      icon: Icons.emoji_objects_rounded,
      color: Color(0xFF4CAF50),
    ),
    SuggestedPromptEntity(
      id: 'l_06',
      text: 'What are the benefits of cold showers for health?',
      category: PromptCategory.lifestyle,
      icon: Icons.shower_rounded,
      color: Color(0xFF4CAF50),
    ),
    SuggestedPromptEntity(
      id: 'l_07',
      text: 'How can I reduce sitting time if I work a desk job?',
      category: PromptCategory.lifestyle,
      icon: Icons.chair_rounded,
      color: Color(0xFF4CAF50),
    ),
    SuggestedPromptEntity(
      id: 'l_08',
      text: 'What are the top longevity habits backed by science?',
      category: PromptCategory.lifestyle,
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFF4CAF50),
      isPopular: true,
    ),
  ];

  // ── All combined ───────────────────────────────────────────────────────────

  static List<SuggestedPromptEntity> get all => [
        ...health,
        ...fitness,
        ...nutrition,
        ...mentalWellness,
        ...sleep,
        ...lifestyle,
      ];

  static List<SuggestedPromptEntity> get popular =>
      all.where((p) => p.isPopular).toList();

  static List<SuggestedPromptEntity> byCategory(PromptCategory category) =>
      category == PromptCategory.all
          ? all
          : all.where((p) => p.category == category).toList();

  // ── Home page quick suggestions ────────────────────────────────────────────

  static List<SuggestedPromptEntity> homeSuggestions(CoachType coachType) =>
      switch (coachType) {
        CoachType.health => health.take(3).toList(),
        CoachType.fitness => fitness.take(3).toList(),
        CoachType.nutrition => nutrition.take(3).toList(),
        CoachType.lifestyle => lifestyle.take(3).toList(),
        CoachType.habit => lifestyle.take(3).toList(),
        _ => popular.take(6).toList(),
      };
}

