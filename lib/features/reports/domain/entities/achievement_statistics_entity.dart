// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT TIER
// ══════════════════════════════════════════════════════════════════════════════

enum AchievementTier {
  bronze('Bronze', 0xFFCD7F32),
  silver('Silver', 0xFFC0C0C0),
  gold('Gold', 0xFFFFD700),
  platinum('Platinum', 0xFF00B4D8),
  diamond('Diamond', 0xFF6C63FF);

  const AchievementTier(this.label, this.colorValue);
  final String label;
  final int colorValue;
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT ENTRY
// ══════════════════════════════════════════════════════════════════════════════

/// A single achievement earned by the user.
class AchievementEntry {
  const AchievementEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.tier,
    required this.category,
    required this.earnedAt,
    required this.isNew,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementTier tier;
  final String category;
  final DateTime earnedAt;
  final bool isNew;
}

// ══════════════════════════════════════════════════════════════════════════════
// GOAL COMPLETION STATS
// ══════════════════════════════════════════════════════════════════════════════

/// Goal completion statistics for a single goal type.
class GoalStats {
  const GoalStats({
    required this.label,
    required this.emoji,
    required this.targetCount,
    required this.completedCount,
    required this.completionRate,
    required this.streak,
    required this.bestStreak,
  });

  final String label;
  final String emoji;
  final int targetCount;
  final int completedCount;
  final double completionRate;
  final int streak;
  final int bestStreak;

  bool get isOnTrack => completionRate >= 0.8;
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT STATISTICS ENTITY
// ══════════════════════════════════════════════════════════════════════════════

/// Complete achievement and goal statistics for a user.
class AchievementStatisticsEntity {
  const AchievementStatisticsEntity({
    required this.achievements,
    required this.totalAchievements,
    required this.newAchievements,
    required this.totalPoints,
    required this.currentLevel,
    required this.nextLevelPoints,
    required this.progressToNextLevel,
    required this.goalStats,
    required this.overallGoalCompletionRate,
    required this.currentActivityStreak,
    required this.longestActivityStreak,
    required this.currentMedicationStreak,
    required this.longestMedicationStreak,
    required this.personalRecords,
    required this.activeDaysThisMonth,
    required this.activeDaysLastMonth,
    required this.achievementTimeline,
  });

  final List<AchievementEntry> achievements;
  final int totalAchievements;
  final int newAchievements;

  // ── Points & Levels ───────────────────────────────────────────────────────
  final int totalPoints;
  final int currentLevel;
  final int nextLevelPoints;

  /// 0.0–1.0
  final double progressToNextLevel;

  // ── Goals ─────────────────────────────────────────────────────────────────
  final List<GoalStats> goalStats;
  final double overallGoalCompletionRate;

  // ── Streaks ───────────────────────────────────────────────────────────────
  final int currentActivityStreak;
  final int longestActivityStreak;
  final int currentMedicationStreak;
  final int longestMedicationStreak;

  // ── Personal Records ──────────────────────────────────────────────────────
  final Map<String, double> personalRecords;

  // ── Activity ──────────────────────────────────────────────────────────────
  final int activeDaysThisMonth;
  final int activeDaysLastMonth;

  /// Timeline for achievement display (date → list of achievement IDs earned).
  final Map<DateTime, List<String>> achievementTimeline;

  List<AchievementEntry> get newOnes =>
      achievements.where((a) => a.isNew).toList();

  List<AchievementEntry> byTier(AchievementTier tier) =>
      achievements.where((a) => a.tier == tier).toList();

  int get activeDaysDelta => activeDaysThisMonth - activeDaysLastMonth;
}

