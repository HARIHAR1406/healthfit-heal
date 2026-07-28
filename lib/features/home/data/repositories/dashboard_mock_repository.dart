import 'package:intl/intl.dart';

import '../../../../core/router/route_names.dart';
import '../../domain/entities/activity_item_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/health_metric_entity.dart';
import '../../domain/entities/progress_item_entity.dart';
import '../../domain/entities/quick_action_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// In-memory mock repository providing realistic fixture data.
///
/// Replace with [DashboardRepositoryImpl] (Dio-backed) when the API is ready.
/// All values are intentionally realistic to demonstrate the full UI.
class DashboardMockRepository implements DashboardRepository {
  @override
  Future<DashboardEntity> getDashboard() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return _buildDashboard();
  }

  @override
  Future<DashboardEntity> refresh() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _buildDashboard();
  }

  // ── Builder ──────────────────────────────────────────────────────────────

  DashboardEntity _buildDashboard() {
    return DashboardEntity(
      greeting: _computeGreeting(),
      motivationalQuote: _pickMotivationalQuote(),
      wellnessScore: 78,
      notificationCount: 3,
      currentDate: _formatDate(),
      metrics: _buildMetrics(),
      quickActions: _buildQuickActions(),
      todayProgress: _buildTodayProgress(),
      recentActivities: _buildRecentActivities(),
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  String _computeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _pickMotivationalQuote() {
    const quotes = [
      'Every step counts on your journey to wellness. 💪',
      'Progress, not perfection. Keep moving forward! 🌟',
      'Your body is capable of amazing things — trust it! ✨',
      'Small habits today create extraordinary results tomorrow. 🌱',
      'Health is not a destination, it\'s a way of life. ❤️',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  String _formatDate() {
    return DateFormat('EEEE, d MMMM').format(DateTime.now());
  }

  // ── Health Metrics ────────────────────────────────────────────────────────

  List<HealthMetricEntity> _buildMetrics() => [
        const HealthMetricEntity(
          id: 'bmi',
          type: HealthMetricType.bmi,
          title: 'BMI',
          value: '22.4',
          unit: 'kg/m²',
          status: HealthMetricStatus.normal,
          progressPercent: 0.65,
          route: RouteNames.healthDashboard,
          subtitle: 'Healthy range',
          trend: 'Stable',
        ),
        const HealthMetricEntity(
          id: 'heart_rate',
          type: HealthMetricType.heartRate,
          title: 'Heart Rate',
          value: '72',
          unit: 'bpm',
          status: HealthMetricStatus.normal,
          progressPercent: 0.72,
          route: RouteNames.heartRate,
          subtitle: 'Resting rate',
          trend: '-3 from yesterday',
        ),
        const HealthMetricEntity(
          id: 'steps',
          type: HealthMetricType.steps,
          title: 'Steps',
          value: '7,432',
          unit: 'steps',
          status: HealthMetricStatus.normal,
          progressPercent: 0.74,
          route: RouteNames.steps,
          subtitle: '10,000 goal',
          trend: '+1,200 today',
        ),
        const HealthMetricEntity(
          id: 'water',
          type: HealthMetricType.water,
          title: 'Water',
          value: '1.8',
          unit: 'L',
          status: HealthMetricStatus.warning,
          progressPercent: 0.72,
          route: RouteNames.water,
          subtitle: '2.5L goal',
          trend: '700ml left',
        ),
        const HealthMetricEntity(
          id: 'sleep',
          type: HealthMetricType.sleep,
          title: 'Sleep',
          value: '7h 20m',
          unit: '',
          status: HealthMetricStatus.normal,
          progressPercent: 0.92,
          route: RouteNames.sleep,
          subtitle: '8h goal',
          trend: 'Well rested',
        ),
      ];

  // ── Quick Actions ─────────────────────────────────────────────────────────

  List<QuickActionEntity> _buildQuickActions() => [
        const QuickActionEntity(
          id: 'health',
          type: QuickActionType.health,
          title: 'Health',
          subtitle: 'Vitals & metrics',
          route: RouteNames.healthDashboard,
        ),
        const QuickActionEntity(
          id: 'fitness',
          type: QuickActionType.fitness,
          title: 'Fitness',
          subtitle: 'Workouts & plans',
          route: RouteNames.workouts,
        ),
        const QuickActionEntity(
          id: 'nutrition',
          type: QuickActionType.nutrition,
          title: 'Nutrition',
          subtitle: 'Meals & calories',
          route: RouteNames.nutrition,
        ),
        const QuickActionEntity(
          id: 'ai_assistant',
          type: QuickActionType.aiAssistant,
          title: 'AI Coach',
          subtitle: 'Smart guidance',
          route: RouteNames.aiAssistant,
        ),
        const QuickActionEntity(
          id: 'reports',
          type: QuickActionType.reports,
          title: 'Reports',
          subtitle: 'Progress insights',
          route: RouteNames.insights,
        ),
        const QuickActionEntity(
          id: 'medication',
          type: QuickActionType.medication,
          title: 'Medication',
          subtitle: 'Reminders & log',
          route: RouteNames.healthDashboard,
        ),
      ];

  // ── Today's Progress ──────────────────────────────────────────────────────

  List<ProgressItemEntity> _buildTodayProgress() => [
        const ProgressItemEntity(
          id: 'workout',
          title: 'Workout',
          current: 35,
          goal: 60,
          unit: 'min',
          metricType: 'fitness',
        ),
        const ProgressItemEntity(
          id: 'calories',
          title: 'Calories',
          current: 1247,
          goal: 2000,
          unit: 'kcal',
          metricType: 'calories',
        ),
        const ProgressItemEntity(
          id: 'water_progress',
          title: 'Water',
          current: 1800,
          goal: 2500,
          unit: 'ml',
          metricType: 'water',
        ),
        const ProgressItemEntity(
          id: 'sleep_progress',
          title: 'Sleep',
          current: 7.33,
          goal: 8,
          unit: 'h',
          metricType: 'sleep',
        ),
        const ProgressItemEntity(
          id: 'medication',
          title: 'Medication',
          current: 2,
          goal: 3,
          unit: 'doses',
          metricType: 'medication',
        ),
      ];

  // ── Recent Activities ─────────────────────────────────────────────────────

  List<ActivityItemEntity> _buildRecentActivities() {
    final now = DateTime.now();
    return [
      ActivityItemEntity(
        id: 'act_1',
        type: ActivityType.workout,
        title: 'Morning Run',
        description: 'Cardio · Outdoor',
        timestamp: now.subtract(const Duration(minutes: 45)),
        value: '35',
        unit: 'min',
      ),
      ActivityItemEntity(
        id: 'act_2',
        type: ActivityType.meal,
        title: 'Breakfast Logged',
        description: 'Oats, banana, milk',
        timestamp: now.subtract(const Duration(hours: 2)),
        value: '420',
        unit: 'kcal',
      ),
      ActivityItemEntity(
        id: 'act_3',
        type: ActivityType.water,
        title: 'Water Intake',
        description: 'Morning hydration',
        timestamp: now.subtract(const Duration(hours: 3)),
        value: '500',
        unit: 'ml',
      ),
      ActivityItemEntity(
        id: 'act_4',
        type: ActivityType.medication,
        title: 'Vitamin D Taken',
        description: 'Daily supplement',
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      ActivityItemEntity(
        id: 'act_5',
        type: ActivityType.sleep,
        title: 'Sleep Logged',
        description: 'Deep sleep achieved',
        timestamp: now.subtract(const Duration(hours: 8)),
        value: '7h 20m',
        unit: '',
      ),
      ActivityItemEntity(
        id: 'act_6',
        type: ActivityType.vitals,
        title: 'Vitals Recorded',
        description: 'Blood pressure & SpO₂',
        timestamp: now.subtract(const Duration(hours: 10)),
      ),
    ];
  }
}
