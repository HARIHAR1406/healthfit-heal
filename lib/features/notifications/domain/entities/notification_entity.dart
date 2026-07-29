import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION CATEGORY
// ══════════════════════════════════════════════════════════════════════════════

enum NotificationCategory {
  health('Health', Icons.monitor_heart_rounded, Color(0xFFEF5350)),
  fitness('Fitness', Icons.fitness_center_rounded, Color(0xFF00C896)),
  nutrition('Nutrition', Icons.restaurant_rounded, Color(0xFFFFBF00)),
  medication('Medication', Icons.medication_rounded, Color(0xFF2196F3)),
  aiCoach('AI Coach', Icons.auto_awesome_rounded, Color(0xFF6C63FF)),
  system('System', Icons.settings_rounded, Color(0xFF607D8B)),
  achievement('Achievement', Icons.emoji_events_rounded, Color(0xFFFFBF00));

  const NotificationCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION PRIORITY
// ══════════════════════════════════════════════════════════════════════════════

enum NotificationPriority {
  low('Low', 0),
  normal('Normal', 1),
  high('High', 2),
  urgent('Urgent', 3);

  const NotificationPriority(this.label, this.level);
  final String label;
  final int level;
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Represents a single in-app notification record.
class NotificationEntity {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.actionRoute,
    this.actionLabel,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;

  /// Optional image (achievement badge, chart thumbnail).
  final String? imageUrl;

  /// GoRouter path to navigate to when tapped.
  final String? actionRoute;
  final String? actionLabel;

  /// Arbitrary extra data (e.g., medicationId, workoutId).
  final Map<String, dynamic> metadata;

  NotificationEntity copyWith({
    bool? isRead,
    String? actionRoute,
  }) =>
      NotificationEntity(
        id: id,
        title: title,
        body: body,
        category: category,
        priority: priority,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        imageUrl: imageUrl,
        actionRoute: actionRoute ?? this.actionRoute,
        actionLabel: actionLabel,
        metadata: metadata,
      );

  /// Relative time label (e.g., "2 min ago", "Yesterday").
  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Per-device notification preferences (persisted to Hive).
class NotificationSettings {
  const NotificationSettings({
    this.masterEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.silentMode = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.categoryToggles = const {
      NotificationCategory.health: true,
      NotificationCategory.fitness: true,
      NotificationCategory.nutrition: true,
      NotificationCategory.medication: true,
      NotificationCategory.aiCoach: true,
      NotificationCategory.system: true,
      NotificationCategory.achievement: true,
    },
  });

  final bool masterEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool silentMode;
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final Map<NotificationCategory, bool> categoryToggles;

  bool isCategoryEnabled(NotificationCategory cat) =>
      masterEnabled && (categoryToggles[cat] ?? true);

  bool get isInQuietHours {
    if (!quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = quietHoursStart.hour * 60 + quietHoursStart.minute;
    final endMinutes = quietHoursEnd.hour * 60 + quietHoursEnd.minute;
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    // Wraps midnight
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? silentMode,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    Map<NotificationCategory, bool>? categoryToggles,
  }) =>
      NotificationSettings(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        silentMode: silentMode ?? this.silentMode,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
        categoryToggles: categoryToggles ?? this.categoryToggles,
      );
}
