import '../../domain/entities/ai_report_entity.dart';
import '../../domain/entities/fitness_report_entity.dart';
import '../../domain/entities/health_report_entity.dart';
import '../../domain/entities/nutrition_report_entity.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/repositories/reports_repository.dart';
import '../mock/ai_mock_data.dart';
import '../mock/fitness_mock_data.dart';
import '../mock/health_mock_data.dart';
import '../mock/nutrition_mock_data.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MOCK REPORTS REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

/// Filter-aware mock implementation of [ReportsRepository].
///
/// Data is generated deterministically from fixed-seed [Random] instances
/// and sliced to the requested date range on every call.
/// Network delay is simulated with [Future.delayed] for realistic UX testing.
class MockReportsRepository implements ReportsRepository {
  const MockReportsRepository();

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _days(ActiveFilter filter) =>
      filter.endDate.difference(filter.startDate).inDays + 1;

  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 600), () => value);

  // ── Health ─────────────────────────────────────────────────────────────────

  @override
  Future<HealthReportEntity> getHealthReport(ActiveFilter filter) async {
    final days = _days(filter).clamp(1, 90);

    final hrSeries = HealthMockData.heartRateSeries(days);
    final bpSeries = HealthMockData.bpSeries(days);
    final sugarSeries = HealthMockData.bloodSugarSeries(days);
    final spo2Series = HealthMockData.spo2Series(days);
    final bmiSeries = HealthMockData.bmiSeries(days);
    final weightSeries = HealthMockData.weightSeries(days);

    final avgHr = HealthMockData.avg(hrSeries);
    final avgSugar = HealthMockData.avg(sugarSeries);
    final avgSpo2 = HealthMockData.avg(spo2Series);
    final currentBmi = bmiSeries.last.value;
    final avgSys = bpSeries.isEmpty
        ? 118.0
        : bpSeries.fold(0.0, (s, p) => s + p.value1) / bpSeries.length;
    final avgDia = bpSeries.isEmpty
        ? 76.0
        : bpSeries.fold(0.0, (s, p) => s + p.value2) / bpSeries.length;

    final radar = HealthMockData.radarScores(
      avgHr: avgHr,
      avgSys: avgSys,
      avgSugar: avgSugar,
      avgSpo2: avgSpo2,
      bmi: currentBmi,
    );
    final score = HealthMockData.healthScore(radar);

    return _delayed(HealthReportEntity(
      healthScore: score,
      healthScoreDelta: 2.4,
      heartRateSeries: hrSeries,
      avgHeartRate: avgHr,
      minHeartRate: HealthMockData.minVal(hrSeries),
      maxHeartRate: HealthMockData.maxVal(hrSeries),
      heartRateDelta: -1.8,
      bpSeries: bpSeries,
      avgSystolic: avgSys,
      avgDiastolic: avgDia,
      bpDelta: -0.5,
      bloodSugarSeries: sugarSeries,
      avgBloodSugar: avgSugar,
      bloodSugarDelta: 1.2,
      spo2Series: spo2Series,
      avgSpo2: avgSpo2,
      spo2Delta: 0.3,
      bmiSeries: bmiSeries,
      currentBmi: currentBmi,
      bmiDelta: -0.2,
      weightSeries: weightSeries,
      currentWeight: weightSeries.last.value,
      weightDelta: -0.4,
      radarScores: radar,
      totalReadings: days * 4,
    ));
  }

  // ── Fitness ────────────────────────────────────────────────────────────────

  @override
  Future<FitnessReportEntity> getFitnessReport(ActiveFilter filter) async {
    final days = _days(filter).clamp(1, 90);

    final freqSeries = FitnessMockData.workoutFrequencySeries(days);
    final calSeries = FitnessMockData.caloriesBurnedSeries(days);
    final minSeries = FitnessMockData.activeMinutesSeries(days);
    final distSeries = FitnessMockData.distanceSeries(days);
    final durSeries = FitnessMockData.durationSeries(days);

    final activeDays =
        freqSeries.where((p) => p.value > 0).length;
    final totalCal =
        calSeries.fold(0.0, (s, p) => s + p.value);
    final totalMins =
        minSeries.fold(0.0, (s, p) => s + p.value).toInt();
    final totalDist =
        distSeries.fold(0.0, (s, p) => s + p.value);
    final avgDur = activeDays == 0
        ? 0.0
        : durSeries
              .where((p) => p.value > 0)
              .fold(0.0, (s, p) => s + p.value) /
          activeDays;

    final streak = FitnessMockData.computeStreak(freqSeries, days);
    final catBreakdown = FitnessMockData.categoryBreakdown(activeDays);
    final weeklyComp = FitnessMockData.weeklyComparison(calSeries, (days / 7).ceil());

    return _delayed(FitnessReportEntity(
      totalWorkouts: activeDays,
      workoutsDelta: 3,
      totalCaloriesBurned: totalCal,
      caloriesBurnedDelta: 150,
      totalActiveMinutes: totalMins,
      activeMinutesDelta: 45,
      totalDistanceKm: totalDist,
      distanceDelta: 2.1,
      avgWorkoutDurationMins: avgDur,
      durationDelta: 5,
      workoutFrequencySeries: freqSeries,
      caloriesBurnedSeries: calSeries,
      activeMinutesSeries: minSeries,
      distanceSeries: distSeries,
      durationSeries: durSeries,
      categoryBreakdown: catBreakdown,
      streak: streak,
      goalCompletionRate: activeDays / (days * 0.6),
      goalCompletionDelta: 0.08,
      weeklyComparison: weeklyComp,
    ));
  }

  // ── Nutrition ──────────────────────────────────────────────────────────────

  @override
  Future<NutritionReportEntity> getNutritionReport(ActiveFilter filter) async {
    final days = _days(filter).clamp(1, 90);

    final calSeries = NutritionMockData.calorieSeries(days);
    final protSeries = NutritionMockData.proteinSeries(days);
    final carbSeries = NutritionMockData.carbsSeries(days);
    final fatSeries = NutritionMockData.fatSeries(days);
    final waterSeries = NutritionMockData.waterSeries(days);
    final consistency = NutritionMockData.mealConsistency(days);
    final macroAvg = NutritionMockData.macroAvg(
      protein: protSeries,
      carbs: carbSeries,
      fat: fatSeries,
    );

    double avg(List list) => list.isEmpty
        ? 0
        : list.fold(0.0, (s, p) => s + (p as dynamic).value) / list.length;

    final avgCal = avg(calSeries);
    final avgWater = avg(waterSeries);
    const targetCal = 2000.0;
    const targetWater = 2500.0;
    final loggedDays = consistency
        .where((r) => r.breakfast || r.lunch || r.dinner)
        .length;
    final consistencyPct = days == 0 ? 0.0 : loggedDays / days;
    final score = NutritionMockData.nutritionScore(
      avgCal: avgCal,
      targetCal: targetCal,
      avgWater: avgWater,
      targetWater: targetWater,
      consistencyPct: consistencyPct,
    );

    return _delayed(NutritionReportEntity(
      nutritionScore: score,
      nutritionScoreDelta: 3.2,
      avgDailyCalories: avgCal,
      caloriesDelta: -50,
      targetCalories: targetCal,
      avgProteinG: avg(protSeries),
      avgCarbsG: avg(carbSeries),
      avgFatG: avg(fatSeries),
      avgFiberG: macroAvg.fiberG,
      avgWaterMl: avgWater,
      waterDelta: 120,
      waterTargetMl: targetWater,
      calorieSeries: calSeries,
      proteinSeries: protSeries,
      carbsSeries: carbSeries,
      fatSeries: fatSeries,
      waterSeries: waterSeries,
      mealConsistency: consistency,
      macroAvg: macroAvg,
      daysLogged: loggedDays,
      loggingConsistencyPct: consistencyPct,
      weeklyMacroComparison: NutritionMockData.weeklyMacroComparison(
        protSeries,
        carbSeries,
        fatSeries,
        (days / 7).ceil(),
      ),
    ));
  }

  // ── AI ─────────────────────────────────────────────────────────────────────

  @override
  Future<AIReportEntity> getAIReport(ActiveFilter filter) async {
    final days = _days(filter).clamp(1, 90);

    final sessionsS = AIMockData.sessionsSeries(days);
    final messagesS = AIMockData.messagesSeries(days);
    final respLengthS = AIMockData.responseLengthSeries(days);

    final totalSessions =
        sessionsS.fold(0.0, (s, p) => s + p.value).toInt();
    final totalMessages =
        messagesS.fold(0.0, (s, p) => s + p.value).toInt();
    final avgDuration = 8.5;
    final topics = AIMockData.topicFrequency(totalMessages);
    final coaches = AIMockData.coachUsage(totalSessions);
    final insights = AIMockData.weeklyInsights((days / 7).ceil().clamp(1, 6));

    return _delayed(AIReportEntity(
      totalSessions: totalSessions,
      sessionsDelta: 5,
      totalMessages: totalMessages,
      messagesDelta: 23,
      avgSessionDurationMins: avgDuration,
      durationDelta: 1.2,
      totalInsightsGenerated: insights.length * 3,
      insightsDelta: 2,
      sessionsSeries: sessionsS,
      messagesSeries: messagesS,
      responseLengthSeries: respLengthS,
      topicFrequency: topics,
      coachUsage: coaches,
      weeklyInsights: insights,
      avgResponseQualityScore: 87.5,
      recommendationsGenerated: insights.length * 4,
      mostUsedCoach: coaches.isEmpty ? 'General' : coaches.first.coachType,
      topTopic: topics.isEmpty ? 'General' : topics.first.topic,
    ));
  }

  // ── Overall Score ──────────────────────────────────────────────────────────

  @override
  Future<double> getOverallHealthScore(ActiveFilter filter) async {
    final health = await getHealthReport(filter);
    final fitness = await getFitnessReport(filter);
    final nutrition = await getNutritionReport(filter);
    return _delayed(
      (health.healthScore * 0.4 +
              fitness.goalCompletionRate * 100 * 0.3 +
              nutrition.nutritionScore * 0.3)
          .clamp(0.0, 100.0),
    );
  }
}
