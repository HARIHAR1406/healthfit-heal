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

  // ── Fitness ───────────────────────────────────────────────────────────────
  static const String workoutLibrary = '/workouts/library';
  static const String workoutDetail = '/workouts/detail/:id';
  static const String workoutLog = '/workouts/log';
  static const String workoutHistory = '/workouts/history';
  static const String workoutPlans = '/workouts/plans';
  static const String activeSession = '/workouts/session';
  static const String sessionSummary = '/workouts/session/summary';
  static const String fitnessAnalytics = '/workouts/analytics';
  static const String achievements = '/workouts/achievements';

  // ── Nutrition ─────────────────────────────────────────────────────────────
  static const String mealPlanner = '/nutrition/planner';
  static const String foodDatabase = '/nutrition/foods';
  static const String foodDetail = '/nutrition/foods/detail';
  static const String waterTracker = '/nutrition/water';
  static const String weightTracker = '/nutrition/weight';
  static const String nutritionAnalytics = '/nutrition/analytics';
  static const String calorieTracker = '/nutrition/calories';
  static const String nutritionLog = '/nutrition/log';
  static const String nutritionHistory = '/nutrition/history';
  static const String foodSearch = '/nutrition/search';

  // ── AI Assistant ──────────────────────────────────────────────────────────
  static const String aiAssistant = '/ai-assistant';
  static const String aiChat = '/ai-assistant/chat/:id';
  static const String aiChatNew = '/ai-assistant/chat/new';
  static const String chatHistory = '/ai-assistant/history';
  static const String aiCoach = '/ai-assistant/coach';
  static const String aiCoachChat = '/ai-assistant/coach/:type/chat';
  static const String smartInsights = '/ai-assistant/insights';
  static const String promptLibrary = '/ai-assistant/prompts';
  static const String aiSettings = '/ai-assistant/settings';

  // ── Reports & Analytics ──────────────────────────────────────────────────
  static const String reports = '/reports';
  static const String reportsHealth = '/reports/health';
  static const String reportsFitness = '/reports/fitness';
    static const String reportsNutrition = '/reports/nutrition';
  static const String reportsAI = '/reports/ai';
  static const String reportsExport = '/reports/export';

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

  // ── Medication ────────────────────────────────────────────────────────────
  static const String medication = '/medication';

  // ── Error ─────────────────────────────────────────────────────────────────
  static const String notFound = '/404';
  static const String error = '/error';
}

