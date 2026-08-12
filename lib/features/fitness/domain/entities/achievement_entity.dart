/// Achievement badge types.
enum AchievementType {
  firstWorkout,
  streak7,
  streak30,
  calories1000,
  workouts10,
  workouts100,
  marathon,
  personalBest,
  earlyBird,
  weekendWarrior,
}

extension AchievementTypeX on AchievementType {
  String get title => switch (this) {
        AchievementType.firstWorkout => 'First Workout',
        AchievementType.streak7 => '7-Day Streak',
        AchievementType.streak30 => '30-Day Streak',
        AchievementType.calories1000 => '1000 Calories',
        AchievementType.workouts10 => '10 Workouts',
        AchievementType.workouts100 => '100 Workouts',
        AchievementType.marathon => 'Marathon Badge',
        AchievementType.personalBest => 'Personal Best',
        AchievementType.earlyBird => 'Early Bird',
        AchievementType.weekendWarrior => 'Weekend Warrior',
      };

  String get description => switch (this) {
        AchievementType.firstWorkout => 'Completed your very first workout!',
        AchievementType.streak7 => 'Worked out 7 days in a row.',
        AchievementType.streak30 => 'Worked out 30 days straight!',
        AchievementType.calories1000 => 'Burned 1,000 calories total.',
        AchievementType.workouts10 => 'Completed 10 workouts.',
        AchievementType.workouts100 => 'Completed 100 workouts!',
        AchievementType.marathon =>
          'Ran a total of 42.195 km across workouts.',
        AchievementType.personalBest => 'Set a new personal record.',
        AchievementType.earlyBird => 'Completed a workout before 8 AM.',
        AchievementType.weekendWarrior =>
          'Worked out every weekend for a month.',
      };

  String get icon => switch (this) {
        AchievementType.firstWorkout => '🏆',
        AchievementType.streak7 => '🔥',
        AchievementType.streak30 => '💪',
        AchievementType.calories1000 => '⚡',
        AchievementType.workouts10 => '🎯',
        AchievementType.workouts100 => '🌟',
        AchievementType.marathon => '🏃',
        AchievementType.personalBest => '🥇',
        AchievementType.earlyBird => '🌅',
        AchievementType.weekendWarrior => '⚔️',
      };
}

/// An achievement entity.
class AchievementEntity {
  const AchievementEntity({
    required this.id,
    required this.type,
    required this.unlockedAt,
    required this.isUnlocked,
    required this.progressCurrent,
    required this.progressTarget,
  });

  final String id;
  final AchievementType type;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int progressCurrent;
  final int progressTarget;

  double get progressFraction =>
      (progressCurrent / progressTarget).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
      'progressCurrent': progressCurrent,
      'progressTarget': progressTarget,
    };
  }

  factory AchievementEntity.fromMap(Map<String, dynamic> map) {
    return AchievementEntity(
      id: map['id'] as String? ?? '',
      type: AchievementType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => AchievementType.firstWorkout,
      ),
      unlockedAt: map['unlockedAt'] != null ? DateTime.parse(map['unlockedAt'] as String) : null,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      progressCurrent: (map['progressCurrent'] as num?)?.toInt() ?? 0,
      progressTarget: (map['progressTarget'] as num?)?.toInt() ?? 1,
    );
  }
}

