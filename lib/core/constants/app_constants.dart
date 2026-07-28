/// Application-wide constants for HealthFit Heal.
abstract final class AppConstants {
  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'HealthFit Heal';
  static const String appPackageName = 'com.healthfitheal.app';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ── Storage Keys ──────────────────────────────────────────────────────────
  static const String hiveUserBox = 'user_box';
  static const String hiveSettingsBox = 'settings_box';
  static const String hiveCacheBox = 'cache_box';
  static const String hiveHealthBox = 'health_box';

  static const String secureKeyAccessToken = 'access_token';
  static const String secureKeyRefreshToken = 'refresh_token';
  static const String secureKeyUserId = 'user_id';
  static const String secureKeyBiometricEnabled = 'biometric_enabled';

  // ── Network ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int initialPage = 1;

  // ── Cache ─────────────────────────────────────────────────────────────────
  static const Duration cacheDefaultTtl = Duration(hours: 1);
  static const Duration cacheLongTtl = Duration(hours: 24);
  static const Duration cacheShortTtl = Duration(minutes: 15);

  // ── Validation ────────────────────────────────────────────────────────────
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 128;
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
  static const int nameMaxLength = 50;
  static const int bioMaxLength = 200;

  // ── Health Metrics ────────────────────────────────────────────────────────
  static const int defaultDailyStepsGoal = 10000;
  static const int defaultDailyCaloriesGoal = 2000;
  static const double defaultDailyWaterGoalLitres = 2.5;
  static const int defaultSleepGoalHours = 8;
  static const int defaultWeeklyWorkoutDays = 5;

  // ── Animation ─────────────────────────────────────────────────────────────
  static const int splashDelayMs = 2000;

  // ── Date & Time ───────────────────────────────────────────────────────────
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String timeFormatDisplay = 'h:mm a';
  static const String dateTimeFormatDisplay = 'MMM dd, yyyy h:mm a';

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const String supportEmail = 'support@healthfitheal.com';
  static const String privacyPolicyUrl = 'https://healthfitheal.com/privacy';
  static const String termsOfServiceUrl = 'https://healthfitheal.com/terms';
}
