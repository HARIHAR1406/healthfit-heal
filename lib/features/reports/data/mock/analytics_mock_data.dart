import 'dart:math' as math;

import '../../domain/entities/achievement_statistics_entity.dart';
import '../../domain/entities/comparison_data_entity.dart';
import '../../domain/entities/health_insight_entity.dart';
import '../../domain/entities/health_report_entity.dart';
import '../../domain/entities/nutrition_report_entity.dart';
import '../../domain/entities/fitness_report_entity.dart';
import '../../domain/entities/trend_data_entity.dart';
import '../../domain/entities/report_filter.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// INSIGHTS MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

class InsightsMockData {
  InsightsMockData._();

  static InsightsReport generate(ActiveFilter filter) {
    final now = DateTime.now();
    final insights = <HealthInsightEntity>[
      // ── Daily Insights ───────────────────────────────────────────────────
      HealthInsightEntity(
        id: 'ins_001',
        type: InsightType.daily,
        category: InsightCategory.cardiovascular,
        priority: InsightPriority.medium,
        title: 'Resting Heart Rate Elevated',
        summary: 'Your average resting HR is 78 bpm — slightly above your 7-day baseline of 72 bpm.',
        detail: 'An elevated resting heart rate can indicate stress, dehydration, or insufficient recovery. Consider a rest day and ensure you are drinking at least 2.5L of water.',
        generatedAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
        actionLabel: 'View Heart Rate',
        relatedMetricValue: 78,
        relatedMetricUnit: 'bpm',
        relatedMetricDelta: 6,
        confidence: 0.87,
        sources: ['Heart Rate', 'Sleep Quality', 'Activity'],
      ),
      HealthInsightEntity(
        id: 'ins_002',
        type: InsightType.daily,
        category: InsightCategory.nutrition,
        priority: InsightPriority.positive,
        title: 'Great Hydration Yesterday',
        summary: 'You drank 2,800 mL of water — 12% above your 2,500 mL target.',
        detail: 'Consistent hydration supports kidney function, energy levels, and workout recovery. Keep up the great work!',
        generatedAt: now.subtract(const Duration(hours: 5)),
        isRead: true,
        relatedMetricValue: 2800,
        relatedMetricUnit: 'mL',
        relatedMetricDelta: 300,
        confidence: 0.95,
        sources: ['Water Intake'],
        actionLabel: 'View Water Log',
      ),

      // ── Weekly Insights ──────────────────────────────────────────────────
      HealthInsightEntity(
        id: 'ins_003',
        type: InsightType.weekly,
        category: InsightCategory.fitness,
        priority: InsightPriority.positive,
        title: 'New Weekly Workout Record!',
        summary: 'You completed 6 workouts this week — your personal best!',
        detail: 'Consistency is key. Your 6-session week is a 20% improvement over your 8-week average. Active minutes totalled 285 — well above the WHO recommendation of 150 min/week.',
        generatedAt: now.subtract(const Duration(days: 1)),
        isRead: false,
        relatedMetricValue: 6,
        relatedMetricUnit: 'sessions',
        relatedMetricDelta: 1,
        confidence: 0.99,
        sources: ['Workout Log', 'Active Minutes'],
        actionLabel: 'View Workouts',
      ),
      HealthInsightEntity(
        id: 'ins_004',
        type: InsightType.weekly,
        category: InsightCategory.nutrition,
        priority: InsightPriority.medium,
        title: 'Protein Intake Below Target',
        summary: 'Average daily protein this week: 98g — 22% below your 125g target.',
        detail: 'Adequate protein is essential for muscle repair and satiety. Focus on adding one high-protein meal (chicken, eggs, Greek yogurt) per day to close the gap.',
        generatedAt: now.subtract(const Duration(days: 1)),
        isRead: false,
        relatedMetricValue: 98,
        relatedMetricUnit: 'g/day',
        relatedMetricDelta: -27,
        confidence: 0.91,
        sources: ['Nutrition Log', 'Macro Tracking'],
        actionLabel: 'View Nutrition',
      ),
      HealthInsightEntity(
        id: 'ins_005',
        type: InsightType.weekly,
        category: InsightCategory.sleep,
        priority: InsightPriority.high,
        title: 'Sleep Consistency Declining',
        summary: 'Average bedtime this week varied by 2.1 hours — disrupting your circadian rhythm.',
        detail: 'Variable sleep timing reduces sleep quality even when total hours are adequate. Try to maintain a consistent ±30 min bedtime window each night.',
        generatedAt: now.subtract(const Duration(days: 2)),
        isRead: false,
        relatedMetricValue: 6.8,
        relatedMetricUnit: 'hrs avg',
        relatedMetricDelta: -0.8,
        confidence: 0.82,
        sources: ['Sleep Data', 'Bedtime Patterns'],
      ),
      // ── Monthly Insights ─────────────────────────────────────────────────
      HealthInsightEntity(
        id: 'ins_006',
        type: InsightType.monthly,
        category: InsightCategory.weight,
        priority: InsightPriority.positive,
        title: 'Healthy Weight Loss Trend',
        summary: 'You lost 1.8 kg this month at a healthy 0.45 kg/week pace.',
        detail: 'Medical guidelines recommend 0.25–0.5 kg/week for sustainable fat loss. Your pace is perfectly within this range. BMI moved from 25.4 to 24.7 — now in the normal range.',
        generatedAt: now.subtract(const Duration(days: 5)),
        isRead: true,
        relatedMetricValue: 1.8,
        relatedMetricUnit: 'kg lost',
        relatedMetricDelta: -1.8,
        confidence: 0.96,
        sources: ['Weight Log', 'BMI', 'Calorie Deficit'],
        actionLabel: 'View Weight Trend',
      ),
      HealthInsightEntity(
        id: 'ins_007',
        type: InsightType.monthly,
        category: InsightCategory.cardiovascular,
        priority: InsightPriority.positive,
        title: 'Blood Pressure Improving',
        summary: '30-day average BP: 118/76 mmHg — optimal range achieved.',
        detail: 'Your blood pressure has been consistently in the optimal range (< 120/80) for 3 consecutive weeks. This is attributed to your increased cardio activity and improved diet quality.',
        generatedAt: now.subtract(const Duration(days: 7)),
        isRead: true,
        relatedMetricValue: 118,
        relatedMetricUnit: 'mmHg systolic',
        relatedMetricDelta: -4,
        confidence: 0.93,
        sources: ['BP Readings', 'Exercise Log'],
      ),
      // ── Risk Alerts ───────────────────────────────────────────────────────
      HealthInsightEntity(
        id: 'ins_008',
        type: InsightType.riskAlert,
        category: InsightCategory.cardiovascular,
        priority: InsightPriority.high,
        title: 'Blood Sugar Spike Detected',
        summary: 'Post-meal blood sugar reached 168 mg/dL on Tuesday — above optimal range.',
        detail: 'A post-meal blood sugar above 140 mg/dL may indicate reduced insulin sensitivity. Consider reducing refined carbohydrates in meals and adding a 15-minute post-meal walk.',
        generatedAt: now.subtract(const Duration(days: 3)),
        isRead: false,
        relatedMetricValue: 168,
        relatedMetricUnit: 'mg/dL',
        relatedMetricDelta: 28,
        confidence: 0.88,
        sources: ['Blood Sugar Log'],
        actionLabel: 'View Blood Sugar',
      ),
      // ── Recommendations ───────────────────────────────────────────────────
      HealthInsightEntity(
        id: 'ins_009',
        type: InsightType.recommendation,
        category: InsightCategory.fitness,
        priority: InsightPriority.medium,
        title: 'Add Zone 2 Cardio',
        summary: 'Your current training is 80% high-intensity. Adding low-intensity cardio will improve fat oxidation.',
        detail: 'Zone 2 cardio (60–70% max HR) for 30–45 min, 2x/week builds aerobic base, improves mitochondrial density, and accelerates recovery. It should feel conversational.',
        generatedAt: now.subtract(const Duration(days: 2)),
        isRead: false,
        confidence: 0.79,
        sources: ['Workout Intensity', 'HR Zones'],
        actionLabel: 'View Fitness Plan',
      ),
      HealthInsightEntity(
        id: 'ins_010',
        type: InsightType.recommendation,
        category: InsightCategory.mental,
        priority: InsightPriority.low,
        title: 'Stress Recovery Score Low',
        summary: 'Your 7-day HRV average is trending downward — consider active recovery activities.',
        detail: 'Heart rate variability (HRV) is a strong indicator of autonomic nervous system recovery. Activities like yoga, meditation, or light walks can help restore HRV within 3–5 days.',
        generatedAt: now.subtract(const Duration(days: 1)),
        isRead: false,
        confidence: 0.74,
        sources: ['HRV Data', 'Sleep Quality', 'Training Load'],
        actionLabel: 'View AI Coach',
      ),
      // ── Achievements ──────────────────────────────────────────────────────
      HealthInsightEntity(
        id: 'ins_011',
        type: InsightType.achievement,
        category: InsightCategory.fitness,
        priority: InsightPriority.positive,
        title: '30-Day Workout Streak! 🔥',
        summary: 'You have worked out for 30 consecutive days — an incredible achievement!',
        detail: 'Building a 30-day exercise habit is scientifically proven to make exercise self-sustaining. Your consistency places you in the top 5% of users.',
        generatedAt: now.subtract(const Duration(days: 1)),
        isRead: false,
        relatedMetricValue: 30,
        relatedMetricUnit: 'days',
        confidence: 1.0,
        sources: ['Workout Log'],
      ),
      HealthInsightEntity(
        id: 'ins_012',
        type: InsightType.achievement,
        category: InsightCategory.nutrition,
        priority: InsightPriority.positive,
        title: 'Hydration Goal: 14-Day Streak! 💧',
        summary: 'You have hit your water intake target for 14 consecutive days.',
        detail: 'Consistent hydration is one of the highest-impact health habits. Your dedication is showing in your energy levels and workout performance.',
        generatedAt: now.subtract(const Duration(days: 2)),
        isRead: true,
        relatedMetricValue: 14,
        relatedMetricUnit: 'days',
        confidence: 1.0,
        sources: ['Water Log'],
      ),
    ];

    final unread = insights.where((i) => !i.isRead).length;
    final critical = insights.where((i) => i.priority == InsightPriority.critical || i.priority == InsightPriority.high).length;
    final positive = insights.where((i) => i.isPositive).length;

    return InsightsReport(
      insights: insights,
      totalInsights: insights.length,
      unreadCount: unread,
      criticalCount: critical,
      positiveCount: positive,
      lastGeneratedAt: now.subtract(const Duration(hours: 2)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TRENDS MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

class TrendsMockData {
  TrendsMockData._();

  static final _rnd = math.Random(42);

  static List<DataPoint> _series(
    int days,
    double base,
    double variance, {
    double trend = 0.0,
  }) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final noise = (_rnd.nextDouble() - 0.5) * variance;
      final value = base + (trend * i) + noise;
      return DataPoint(
        date: now.subtract(Duration(days: days - 1 - i)),
        value: value.clamp(base * 0.5, base * 1.5),
      );
    });
  }

  static double _avg(List<DataPoint> s) =>
      s.isEmpty ? 0 : s.fold(0.0, (a, b) => a + b.value) / s.length;

  static double _stddev(List<DataPoint> s, double mean) {
    if (s.isEmpty) return 0;
    final variance =
        s.fold(0.0, (a, b) => a + math.pow(b.value - mean, 2)) / s.length;
    return math.sqrt(variance);
  }

  static List<double> _weekChanges(List<DataPoint> s) {
    final weeks = <double>[];
    for (int i = 7; i < s.length; i += 7) {
      final cur = _avg(s.sublist(i - 7, i));
      final prev = i >= 14 ? _avg(s.sublist(i - 14, i - 7)) : cur;
      weeks.add(prev == 0 ? 0 : (cur - prev) / prev * 100);
    }
    return weeks.isEmpty ? [0.0] : weeks;
  }

  static TrendDataEntity _build(
    TrendMetric metric,
    int days,
    double base,
    double variance,
    double trend,
    TrendDirection dir,
    String desc, {
    String? risk,
  }) {
    final series = _series(days, base, variance, trend: trend);
    final cur = _avg(series);
    final prev = _avg(_series(days, base - trend * days, variance));
    final stddev = _stddev(series, cur);
    return TrendDataEntity(
      metric: metric,
      series: series,
      direction: dir,
      currentAvg: cur,
      previousAvg: prev,
      changePercent: prev == 0 ? 0 : (cur - prev) / prev * 100,
      changeAbsolute: cur - prev,
      minValue: series.map((p) => p.value).reduce(math.min),
      maxValue: series.map((p) => p.value).reduce(math.max),
      standardDeviation: stddev,
      trendStrength: (0.4 + _rnd.nextDouble() * 0.5).clamp(0.0, 1.0),
      weekOverWeekChanges: _weekChanges(series),
      description: desc,
      riskLevel: risk,
    );
  }

  static TrendsReport generate(ActiveFilter filter) {
    final days = filter.endDate.difference(filter.startDate).inDays.clamp(7, 90);

    final trends = [
      _build(TrendMetric.heartRate, days, 72, 8, -0.05,
          TrendDirection.improving, 'Declining at ~0.3 bpm/week — good cardiovascular adaptation'),
      _build(TrendMetric.systolicBP, days, 120, 6, -0.04,
          TrendDirection.improving, 'Gradually improving — dietary and exercise changes showing effect'),
      _build(TrendMetric.diastolicBP, days, 78, 4, -0.02,
          TrendDirection.stable, 'Stable within normal range'),
      _build(TrendMetric.bloodSugar, days, 100, 12, 0.08,
          TrendDirection.declining, 'Slight upward trend — monitor post-meal readings',
          risk: 'medium'),
      _build(TrendMetric.spo2, days, 97.5, 1.2, 0.01,
          TrendDirection.stable, 'Excellent and stable — well within healthy range'),
      _build(TrendMetric.bmi, days, 24.8, 0.4, -0.01,
          TrendDirection.improving, 'Slowly decreasing — on track for weight management goal'),
      _build(TrendMetric.weight, days, 74.5, 0.6, -0.05,
          TrendDirection.improving, 'Gradual healthy weight loss — 0.3 kg/week average'),
      _build(TrendMetric.water, days, 2200, 300, 15,
          TrendDirection.improving, 'Hydration improving week over week'),
      _build(TrendMetric.calories, days, 1950, 200, -5,
          TrendDirection.stable, 'Stable within 100 kcal of target'),
      _build(TrendMetric.sleep, days, 7.2, 0.8, -0.02,
          TrendDirection.declining, 'Slight sleep duration decrease — check sleep habits',
          risk: 'low'),
      _build(TrendMetric.workouts, days, 0.7, 0.4, 0.01,
          TrendDirection.improving, 'Workout frequency increasing — great consistency'),
      _build(TrendMetric.activeMinutes, days, 45, 20, 2,
          TrendDirection.improving, 'Active minutes trending up week over week'),
      _build(TrendMetric.medicationAdherence, days, 88, 8, 0.1,
          TrendDirection.stable, 'Good adherence — occasional missed doses on weekends'),
      _build(TrendMetric.nutritionScore, days, 72, 10, 0.2,
          TrendDirection.improving, 'Meal quality gradually improving'),
    ];

    final improving = trends.where((t) => t.isImproving).length;
    final declining = trends.where((t) => t.isDeclining).length;
    final stable = trends.length - improving - declining;

    return TrendsReport(
      trends: trends,
      improvingCount: improving,
      decliningCount: declining,
      stableCount: stable,
      periodLabel: filter.label,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPARISON MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

class ComparisonMockData {
  ComparisonMockData._();

  static final _rnd = math.Random(77);

  static List<DataPoint> _series(int days, double base, double noise) {
    final now = DateTime.now();
    return List.generate(days, (i) => DataPoint(
          date: now.subtract(Duration(days: days - 1 - i)),
          value: (base + (_rnd.nextDouble() - 0.5) * noise)
              .clamp(base * 0.7, base * 1.3),
        ));
  }

  static double _avg(List<DataPoint> s) =>
      s.isEmpty ? 0 : s.fold(0.0, (a, b) => a + b.value) / s.length;

  static PeriodStats _buildPeriod(
    String label,
    DateTime start,
    DateTime end, {
    double hrBase = 74,
    double workoutBase = 4,
    double calBase = 1950,
    double scoreBase = 74,
    double improveFactor = 1.0,
  }) {
    final days = end.difference(start).inDays + 1;
    final hrS = _series(days, hrBase, 10);
    final calS = _series(days, calBase, 200);
    final wkS = _series(days, workoutBase / 7, 0.5);
    final waterS = _series(days, 2200, 300);

    return PeriodStats(
      label: label,
      startDate: start,
      endDate: end,
      healthScore: (scoreBase * improveFactor).clamp(0, 100),
      fitnessScore: ((scoreBase - 5) * improveFactor).clamp(0, 100),
      nutritionScore: ((scoreBase - 8) * improveFactor).clamp(0, 100),
      overallScore: (scoreBase * improveFactor * 0.98).clamp(0, 100),
      avgHeartRate: _avg(hrS),
      avgBloodSugar: 98 + _rnd.nextDouble() * 8,
      avgSpo2: 97.2 + _rnd.nextDouble() * 0.8,
      avgSystolic: 118 + _rnd.nextDouble() * 6,
      avgDiastolic: 76 + _rnd.nextDouble() * 4,
      totalWorkouts: (workoutBase + _rnd.nextDouble() * 2).round(),
      totalCaloriesBurned:
          (workoutBase * 320 + _rnd.nextDouble() * 150).roundToDouble(),
      totalActiveMinutes: (workoutBase * 45 + _rnd.nextDouble() * 30).round(),
      totalDistanceKm: workoutBase * 4.2 + _rnd.nextDouble() * 5,
      avgDailyCalories: _avg(calS),
      avgWaterMl: _avg(waterS),
      daysLogged: (days * 0.85 + _rnd.nextDouble() * days * 0.15).round(),
      heartRateSeries: hrS,
      calorieSeries: calS,
      workoutSeries: wkS,
      waterSeries: waterS,
      macroAvg: MacroBreakdown(
        proteinG: 95 + _rnd.nextDouble() * 20,
        carbsG: 220 + _rnd.nextDouble() * 40,
        fatG: 65 + _rnd.nextDouble() * 15,
        fiberG: 22 + _rnd.nextDouble() * 8,
      ),
      categoryBreakdown: [
        WorkoutCategoryBreakdown(
            category: 'Strength',
            sessions: 2,
            color: const Color(0xFF6C63FF)),
        WorkoutCategoryBreakdown(
            category: 'Cardio', sessions: 2, color: const Color(0xFFFF6B6B)),
        WorkoutCategoryBreakdown(
            category: 'Yoga', sessions: 1, color: const Color(0xFF00C896)),
      ],
    );
  }

  static ComparisonDataEntity generate(ComparisonPeriod period) {
    final now = DateTime.now();
    final days = period == ComparisonPeriod.yearOverYear
        ? 365
        : period == ComparisonPeriod.monthOverMonth
            ? 30
            : 7;

    final curEnd = now;
    final curStart = now.subtract(Duration(days: days - 1));
    final prevEnd = curStart.subtract(const Duration(days: 1));
    final prevStart = prevEnd.subtract(Duration(days: days - 1));

    final periodLabel = period.label.split(' vs ')[0];
    final prevLabel = period.label.split(' vs ')[1];

    final current = _buildPeriod(
      periodLabel, curStart, curEnd,
      hrBase: 72, workoutBase: 5, calBase: 1950, scoreBase: 76,
      improveFactor: 1.0,
    );
    final previous = _buildPeriod(
      prevLabel, prevStart, prevEnd,
      hrBase: 75, workoutBase: 4, calBase: 2020, scoreBase: 72,
      improveFactor: 0.95,
    );

    final comparisons = <MetricComparison>[
      _metric('Heart Rate', 'bpm', current.avgHeartRate, previous.avgHeartRate,
          false, current.heartRateSeries, previous.heartRateSeries),
      _metric('Workouts', 'sessions', current.totalWorkouts.toDouble(),
          previous.totalWorkouts.toDouble(), true,
          current.workoutSeries, previous.workoutSeries),
      _metric('Calories Burned', 'kcal', current.totalCaloriesBurned,
          previous.totalCaloriesBurned, true,
          current.calorieSeries, previous.calorieSeries),
      _metric('Active Minutes', 'min', current.totalActiveMinutes.toDouble(),
          previous.totalActiveMinutes.toDouble(), true,
          current.workoutSeries, previous.workoutSeries),
      _metric('Water Intake', 'mL', current.avgWaterMl, previous.avgWaterMl,
          true, current.waterSeries, previous.waterSeries),
      _metric('Blood Sugar', 'mg/dL', current.avgBloodSugar,
          previous.avgBloodSugar, false,
          current.heartRateSeries, previous.heartRateSeries),
      _metric('Nutrition Score', 'pts', current.nutritionScore,
          previous.nutritionScore, true,
          current.calorieSeries, previous.calorieSeries),
      _metric('Overall Score', 'pts', current.overallScore,
          previous.overallScore, true,
          current.calorieSeries, previous.calorieSeries),
    ];

    final improvements =
        comparisons.where((c) => c.improved).length;
    final regressions = comparisons.length - improvements;

    return ComparisonDataEntity(
      period: period,
      current: current,
      previous: previous,
      metricComparisons: comparisons,
      winnerLabel: current.overallScore >= previous.overallScore
          ? periodLabel
          : prevLabel,
      improvementsCount: improvements,
      regressionsCount: regressions,
    );
  }

  static MetricComparison _metric(
    String label,
    String unit,
    double current,
    double previous,
    bool higherIsBetter,
    List<DataPoint> curSeries,
    List<DataPoint> prevSeries,
  ) {
    final changePct =
        previous == 0 ? 0.0 : (current - previous) / previous * 100;
    return MetricComparison(
      label: label,
      unit: unit,
      currentValue: current,
      previousValue: previous,
      changePercent: changePct,
      isPositiveChange: higherIsBetter ? current > previous : current < previous,
      currentSeries: curSeries,
      previousSeries: prevSeries,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACHIEVEMENT MOCK DATA
// ══════════════════════════════════════════════════════════════════════════════

class AchievementMockData {
  AchievementMockData._();

  static AchievementStatisticsEntity generate(ActiveFilter filter) {
    final now = DateTime.now();

    final achievements = <AchievementEntry>[
      AchievementEntry(
        id: 'ach_001', title: '30-Day Streak', emoji: '🔥',
        description: 'Worked out every day for 30 days',
        tier: AchievementTier.gold, category: 'Fitness',
        earnedAt: now.subtract(const Duration(days: 1)), isNew: true,
      ),
      AchievementEntry(
        id: 'ach_002', title: 'Hydration Hero', emoji: '💧',
        description: 'Hit water target 14 days in a row',
        tier: AchievementTier.silver, category: 'Nutrition',
        earnedAt: now.subtract(const Duration(days: 3)), isNew: true,
      ),
      AchievementEntry(
        id: 'ach_003', title: 'Heart Warrior', emoji: '❤️',
        description: 'Blood pressure in optimal range for 21 days',
        tier: AchievementTier.gold, category: 'Health',
        earnedAt: now.subtract(const Duration(days: 7)), isNew: false,
      ),
      AchievementEntry(
        id: 'ach_004', title: 'First 5K', emoji: '🏃',
        description: 'Ran 5 km in a single session',
        tier: AchievementTier.bronze, category: 'Fitness',
        earnedAt: now.subtract(const Duration(days: 14)), isNew: false,
      ),
      AchievementEntry(
        id: 'ach_005', title: 'Calorie Master', emoji: '🍎',
        description: 'Logged meals for 30 consecutive days',
        tier: AchievementTier.silver, category: 'Nutrition',
        earnedAt: now.subtract(const Duration(days: 20)), isNew: false,
      ),
      AchievementEntry(
        id: 'ach_006', title: 'Deep Sleeper', emoji: '😴',
        description: 'Achieved 8+ hours sleep for 7 nights',
        tier: AchievementTier.bronze, category: 'Sleep',
        earnedAt: now.subtract(const Duration(days: 25)), isNew: false,
      ),
      AchievementEntry(
        id: 'ach_007', title: 'Centurion', emoji: '💯',
        description: 'Completed 100 total workouts',
        tier: AchievementTier.platinum, category: 'Fitness',
        earnedAt: now.subtract(const Duration(days: 30)), isNew: false,
      ),
      AchievementEntry(
        id: 'ach_008', title: 'Med Adherent', emoji: '💊',
        description: 'Perfect medication adherence for 2 weeks',
        tier: AchievementTier.silver, category: 'Medication',
        earnedAt: now.subtract(const Duration(days: 45)), isNew: false,
      ),
    ];

    final goalStats = <GoalStats>[
      const GoalStats(
        label: 'Daily Steps', emoji: '👟',
        targetCount: 30, completedCount: 24,
        completionRate: 0.80, streak: 5, bestStreak: 12,
      ),
      const GoalStats(
        label: 'Water Intake', emoji: '💧',
        targetCount: 30, completedCount: 28,
        completionRate: 0.93, streak: 14, bestStreak: 14,
      ),
      const GoalStats(
        label: 'Workout Sessions', emoji: '🏋️',
        targetCount: 20, completedCount: 18,
        completionRate: 0.90, streak: 6, bestStreak: 30,
      ),
      const GoalStats(
        label: 'Calorie Target', emoji: '🔥',
        targetCount: 30, completedCount: 22,
        completionRate: 0.73, streak: 3, bestStreak: 10,
      ),
      const GoalStats(
        label: 'Sleep Goal', emoji: '😴',
        targetCount: 30, completedCount: 20,
        completionRate: 0.67, streak: 2, bestStreak: 7,
      ),
      const GoalStats(
        label: 'Medication', emoji: '💊',
        targetCount: 30, completedCount: 27,
        completionRate: 0.90, streak: 10, bestStreak: 15,
      ),
    ];

    final overallRate = goalStats.fold(0.0, (s, g) => s + g.completionRate) /
        goalStats.length;

    // Build achievement timeline (date → achievement IDs)
    final timeline = <DateTime, List<String>>{};
    for (final a in achievements) {
      final key =
          DateTime(a.earnedAt.year, a.earnedAt.month, a.earnedAt.day);
      timeline.putIfAbsent(key, () => []).add(a.id);
    }

    return AchievementStatisticsEntity(
      achievements: achievements,
      totalAchievements: achievements.length,
      newAchievements: achievements.where((a) => a.isNew).length,
      totalPoints: 4250,
      currentLevel: 8,
      nextLevelPoints: 5000,
      progressToNextLevel: 4250 / 5000,
      goalStats: goalStats,
      overallGoalCompletionRate: overallRate,
      currentActivityStreak: 30,
      longestActivityStreak: 30,
      currentMedicationStreak: 10,
      longestMedicationStreak: 15,
      personalRecords: {
        'Longest Run': 8.4,
        'Max Push-ups': 52,
        'Best Sleep': 9.2,
        'Lowest HR': 54,
        'Max Steps': 18420,
        'Highest Water': 4200,
      },
      activeDaysThisMonth: 24,
      activeDaysLastMonth: 21,
      achievementTimeline: timeline,
    );
  }

  static List<PersonalRecord> personalRecords() => [
        PersonalRecord(
          label: 'Longest Run',
          value: 8.4,
          unit: 'km',
          achievedAt: DateTime.now().subtract(const Duration(days: 12)),
          emoji: '🏃',
        ),
        PersonalRecord(
          label: 'Lowest Resting HR',
          value: 54,
          unit: 'bpm',
          achievedAt: DateTime.now().subtract(const Duration(days: 5)),
          emoji: '❤️',
        ),
        PersonalRecord(
          label: 'Most Steps in a Day',
          value: 18420,
          unit: 'steps',
          achievedAt: DateTime.now().subtract(const Duration(days: 20)),
          emoji: '👟',
        ),
        PersonalRecord(
          label: 'Best Sleep',
          value: 9.2,
          unit: 'hrs',
          achievedAt: DateTime.now().subtract(const Duration(days: 30)),
          emoji: '😴',
        ),
        PersonalRecord(
          label: 'Highest Hydration',
          value: 4200,
          unit: 'mL',
          achievedAt: DateTime.now().subtract(const Duration(days: 8)),
          emoji: '💧',
        ),
        PersonalRecord(
          label: 'Longest Workout Streak',
          value: 30,
          unit: 'days',
          achievedAt: DateTime.now().subtract(const Duration(days: 1)),
          emoji: '🔥',
        ),
      ];
}

