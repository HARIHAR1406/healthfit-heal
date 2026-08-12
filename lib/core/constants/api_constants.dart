import '../../config/env/environment.dart';

/// API endpoint constants for HealthFit Heal.
///
/// All paths are relative to [Environment.baseUrl].
/// Do not hardcode full URLs in features — always compose from these.
abstract final class ApiConstants {
  // ── Base ──────────────────────────────────────────────────────────────────
  static String get baseUrl => Environment.baseUrl;
  static const String apiVersion = '/api/v1';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';

  // ── User Profile ──────────────────────────────────────────────────────────
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String uploadAvatar = '/users/avatar';
  static const String deleteAccount = '/users/account';
  static const String changePassword = '/users/password';

  // ── Health Dashboard ──────────────────────────────────────────────────────
  static const String dashboard = '/health/dashboard';
  static const String healthSummary = '/health/summary';

  // ── Activity / Steps ──────────────────────────────────────────────────────
  static const String activityToday = '/activity/today';
  static const String activityHistory = '/activity/history';
  static const String logActivity = '/activity/log';
  static const String activityGoals = '/activity/goals';

  // ── Nutrition ─────────────────────────────────────────────────────────────
  static const String nutritionToday = '/nutrition/today';
  static const String nutritionHistory = '/nutrition/history';
  static const String logMeal = '/nutrition/log';
  static const String foodSearch = '/nutrition/food/search';
  static const String nutritionGoals = '/nutrition/goals';

  // ── Workouts ──────────────────────────────────────────────────────────────
  static const String workouts = '/workouts';
  static const String workoutById = '/workouts/{id}';
  static const String logWorkout = '/workouts/log';
  static const String workoutHistory = '/workouts/history';
  static const String workoutPlans = '/workouts/plans';

  // ── Sleep ─────────────────────────────────────────────────────────────────
  static const String sleepToday = '/sleep/today';
  static const String sleepHistory = '/sleep/history';
  static const String logSleep = '/sleep/log';
  static const String sleepGoals = '/sleep/goals';

  // ── Water ─────────────────────────────────────────────────────────────────
  static const String waterToday = '/water/today';
  static const String waterHistory = '/water/history';
  static const String logWater = '/water/log';
  static const String waterGoals = '/water/goals';

  // ── Vitals ────────────────────────────────────────────────────────────────
  static const String vitals = '/vitals';
  static const String logVitals = '/vitals/log';
  static const String vitalsHistory = '/vitals/history';

  // ── Goals ─────────────────────────────────────────────────────────────────
  static const String goals = '/goals';
  static const String updateGoals = '/goals';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/{id}/read';
  static const String updateFcmToken = '/notifications/fcm-token';

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Substitutes path parameters in a route template.
  ///
  /// Example: [withId('/workouts/{id}', '123')] → '/workouts/123'
  static String withId(String path, String id) =>
      path.replaceFirst('{id}', id);
}

