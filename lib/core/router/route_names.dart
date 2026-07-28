/// Named route constants for HealthFit Heal.
///
/// All route names must be defined here and never hardcoded inline.
/// Feature routes should follow the pattern '/<feature>/<sub-route>'.
abstract final class RouteNames {
  // ── Shell / Root ──────────────────────────────────────────────────────────
  static const String root = '/';
  static const String shell = 'shell';

  // ── Splash / Onboarding ───────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // ── Main Tabs ─────────────────────────────────────────────────────────────
  static const String home = '/home';
  static const String workouts = '/workouts';
  static const String nutrition = '/nutrition';
  static const String insights = '/insights';
  static const String profile = '/profile';

  // ── Health ────────────────────────────────────────────────────────────────
  static const String healthDashboard = '/health';
  static const String bmi = '/health/bmi';
  static const String heartRate = '/health/heart-rate';
  static const String bloodPressure = '/health/blood-pressure';
  static const String bloodSugar = '/health/blood-sugar';
  static const String spo2 = '/health/spo2';
  static const String medicalRecords = '/health/medical-records';
  static const String healthHistory = '/health/history';
  // Legacy stubs (kept for dashboard metric card back-compat)
  static const String steps = '/health/steps';
  static const String sleep = '/health/sleep';
  static const String water = '/health/water';
  static const String calories = '/health/calories';

  // ── Workouts ──────────────────────────────────────────────────────────────
  static const String workoutDetail = '/workouts/:id';
  static const String workoutLog = '/workouts/log';
  static const String workoutHistory = '/workouts/history';
  static const String workoutPlans = '/workouts/plans';

  // ── Nutrition ─────────────────────────────────────────────────────────────
  static const String nutritionLog = '/nutrition/log';
  static const String nutritionHistory = '/nutrition/history';
  static const String foodSearch = '/nutrition/search';
  static const String mealDetail = '/nutrition/meal/:id';

  // ── AI Assistant ──────────────────────────────────────────────────────────
  static const String aiAssistant = '/ai-assistant';

  // ── Profile / Settings ────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit';
  static const String notifications = '/settings/notifications';
  static const String privacy = '/settings/privacy';
  static const String appearance = '/settings/appearance';
  static const String units = '/settings/units';
  static const String about = '/settings/about';

  // ── Goals ─────────────────────────────────────────────────────────────────
  static const String goals = '/goals';
  static const String editGoals = '/goals/edit';

  // ── Error ─────────────────────────────────────────────────────────────────
  static const String notFound = '/404';
  static const String error = '/error';
}

