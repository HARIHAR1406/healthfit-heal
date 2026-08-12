import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER TYPE
// ══════════════════════════════════════════════════════════════════════════════

enum ReminderType {
  medication('Medication', Icons.medication_rounded, Color(0xFF2196F3)),
  water('Water Intake', Icons.water_drop_rounded, Color(0xFF00B4D8)),
  meal('Meals', Icons.restaurant_rounded, Color(0xFFFFBF00)),
  workout('Workout', Icons.fitness_center_rounded, Color(0xFF00C896)),
  sleep('Sleep', Icons.bedtime_rounded, Color(0xFF6C63FF)),
  weight('Weight Check', Icons.monitor_weight_rounded, Color(0xFFFF6B6B)),
  bloodPressure('Blood Pressure', Icons.bloodtype_rounded, Color(0xFFEF5350)),
  heartRate('Heart Rate', Icons.favorite_rounded, Color(0xFFFF6BB5)),
  bloodSugar('Blood Sugar', Icons.water_drop_outlined, Color(0xFFFFBF00));

  const ReminderType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// ══════════════════════════════════════════════════════════════════════════════
// REPEAT SCHEDULE
// ══════════════════════════════════════════════════════════════════════════════

enum RepeatSchedule {
  once('Once', 'Does not repeat'),
  daily('Daily', 'Every day'),
  weekdays('Weekdays', 'Monday–Friday'),
  weekends('Weekends', 'Saturday & Sunday'),
  custom('Custom', 'Selected days');

  const RepeatSchedule(this.label, this.description);
  final String label;
  final String description;
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER PRIORITY
// ══════════════════════════════════════════════════════════════════════════════

enum ReminderPriority {
  low('Low'),
  normal('Normal'),
  high('High');

  const ReminderPriority(this.label);
  final String label;
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER STATUS
// ══════════════════════════════════════════════════════════════════════════════

enum ReminderStatus {
  active('Active'),
  disabled('Disabled'),
  snoozed('Snoozed'),
  completed('Completed');

  const ReminderStatus(this.label);
  final String label;
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// A scheduled recurring reminder for a health action.
class ReminderEntity {
  const ReminderEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.repeatSchedule,
    required this.priority,
    required this.status,
    required this.activeDays,
    this.snoozeUntil,
    this.snoozeDurationMinutes = 10,
    this.notes,
    this.linkedEntityId,
    this.metadata = const {},
  });

  final String id;
  final ReminderType type;
  final String title;
  final String body;

  /// Time-of-day this fires (hour + minute from [TimeOfDay]).
  final TimeOfDay scheduledTime;
  final RepeatSchedule repeatSchedule;
  final ReminderPriority priority;
  final ReminderStatus status;

  /// Bit-mask of active days: index 0 = Monday … 6 = Sunday.
  final List<bool> activeDays;

  final DateTime? snoozeUntil;
  final int snoozeDurationMinutes;
  final String? notes;

  /// e.g., medicationId when linked to a specific medication.
  final String? linkedEntityId;
  final Map<String, dynamic> metadata;

  bool get isEnabled => status == ReminderStatus.active;

  String get timeLabel {
    final h = scheduledTime.hour.toString().padLeft(2, '0');
    final m = scheduledTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get activeDaysLabel {
    if (repeatSchedule != RepeatSchedule.custom) return repeatSchedule.label;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final active = <String>[];
    for (var i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) active.add(names[i]);
    }
    return active.isEmpty ? 'No days' : active.join(', ');
  }

  ReminderEntity copyWith({
    String? title,
    String? body,
    TimeOfDay? scheduledTime,
    RepeatSchedule? repeatSchedule,
    ReminderPriority? priority,
    ReminderStatus? status,
    List<bool>? activeDays,
    DateTime? snoozeUntil,
    int? snoozeDurationMinutes,
    String? notes,
  }) =>
      ReminderEntity(
        id: id,
        type: type,
        title: title ?? this.title,
        body: body ?? this.body,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        repeatSchedule: repeatSchedule ?? this.repeatSchedule,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        activeDays: activeDays ?? this.activeDays,
        snoozeUntil: snoozeUntil ?? this.snoozeUntil,
        snoozeDurationMinutes:
            snoozeDurationMinutes ?? this.snoozeDurationMinutes,
        notes: notes ?? this.notes,
        linkedEntityId: linkedEntityId,
        metadata: metadata,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER HISTORY ENTRY
// ══════════════════════════════════════════════════════════════════════════════

enum ReminderHistoryStatus {
  completed('Completed'),
  missed('Missed'),
  skipped('Skipped'),
  snoozed('Snoozed');

  const ReminderHistoryStatus(this.label);
  final String label;

  Color get color => switch (this) {
        ReminderHistoryStatus.completed => const Color(0xFF00C896),
        ReminderHistoryStatus.missed => const Color(0xFFEF5350),
        ReminderHistoryStatus.skipped => const Color(0xFFFF9800),
        ReminderHistoryStatus.snoozed => const Color(0xFF6C63FF),
      };
}

/// A single fired-reminder log entry.
class ReminderHistoryEntry {
  const ReminderHistoryEntry({
    required this.id,
    required this.reminderId,
    required this.type,
    required this.title,
    required this.scheduledAt,
    required this.status,
    this.actedAt,
    this.note,
  });

  final String id;
  final String reminderId;
  final ReminderType type;
  final String title;
  final DateTime scheduledAt;
  final ReminderHistoryStatus status;
  final DateTime? actedAt;
  final String? note;
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER STATISTICS
// ══════════════════════════════════════════════════════════════════════════════

class ReminderStatistics {
  const ReminderStatistics({
    required this.totalFired,
    required this.completed,
    required this.missed,
    required this.skipped,
    required this.snoozed,
    required this.adherenceRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.byType,
  });

  final int totalFired;
  final int completed;
  final int missed;
  final int skipped;
  final int snoozed;
  final double adherenceRate;
  final int currentStreak;
  final int bestStreak;
  final Map<ReminderType, int> byType;
}

