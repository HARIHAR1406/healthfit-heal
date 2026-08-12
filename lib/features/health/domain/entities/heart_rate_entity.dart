import '../../../../features/home/domain/entities/health_metric_entity.dart';

/// Resting-heart-rate context.
enum HeartRateContext { resting, active, sleeping, unknown }

/// A single heart rate reading with timestamp.
class HeartRateReading {
  const HeartRateReading({
    required this.bpm,
    required this.timestamp,
    this.context = HeartRateContext.resting,
  });

  final int bpm;
  final DateTime timestamp;
  final HeartRateContext context;
}

/// One day's average heart-rate data point for the bar chart.
class HeartRateDailyAvg {
  const HeartRateDailyAvg({
    required this.dayLabel,
    required this.avgBpm,
  });

  /// Short day label, e.g. "Mon".
  final String dayLabel;
  final double avgBpm;
}

/// Pure domain entity for heart rate data.
class HeartRateEntity {
  const HeartRateEntity({
    required this.id,
    required this.currentBpm,
    required this.context,
    required this.status,
    required this.dailyAvg,
    required this.weeklyAvg,
    required this.history,
    required this.weeklyData,
    required this.lastUpdated,
  });

  final String id;
  final int currentBpm;
  final HeartRateContext context;
  final HealthMetricStatus status;

  /// Rolling 24-hour average.
  final int dailyAvg;

  /// Rolling 7-day average.
  final int weeklyAvg;

  /// Full reading history (newest first).
  final List<HeartRateReading> history;

  /// 7-point daily-average data for the bar chart (oldest → newest).
  final List<HeartRateDailyAvg> weeklyData;

  final DateTime lastUpdated;

  // ── Static ─────────────────────────────────────────────────────────────────

  /// Derives [HealthMetricStatus] from a resting BPM value.
  static HealthMetricStatus statusForBpm(int bpm) {
    if (bpm < 60) return HealthMetricStatus.warning;
    if (bpm <= 100) return HealthMetricStatus.normal;
    if (bpm <= 120) return HealthMetricStatus.warning;
    return HealthMetricStatus.critical;
  }
}

