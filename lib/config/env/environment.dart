import 'app_secrets.dart';

/// Environment configuration for HealthFit Heal.
///
/// Selects the API base URL and feature flags based on `--dart-define`
/// compile-time variables. Defaults to 'development'.
///
/// ── Build commands ───────────────────────────────────────────────────────────
///   Development (mock AI, no Firebase):
///     flutter run --dart-define=ENVIRONMENT=development
///
///   Staging (Gemini AI, Firebase enabled):
///     flutter run \
///       --dart-define=ENVIRONMENT=staging \
///       --dart-define=FIREBASE_ENABLED=true \
///       --dart-define=AI_PROVIDER=gemini \
///       --dart-define=GEMINI_API_KEY=your_key
///
///   Production (full stack):
///     flutter build apk \
///       --dart-define=ENVIRONMENT=production \
///       --dart-define=FIREBASE_ENABLED=true \
///       --dart-define=AI_PROVIDER=gemini \
///       --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
///       --dart-define=OPENAI_API_KEY=$OPENAI_API_KEY \
///       --dart-define=PINNED_CERT_FINGERPRINTS=$CERT_PINS
abstract final class Environment {
  // ignore: do_not_use_environment
  static const String _env = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // ── Environment flags ──────────────────────────────────────────────────────
  static bool get isDevelopment => _env == 'development';
  static bool get isStaging => _env == 'staging';
  static bool get isProduction => _env == 'production';

  /// Current environment name.
  static String get name => _env;

  // ── API Base URL ───────────────────────────────────────────────────────────

  /// The base URL for the active environment.
  static String get baseUrl => switch (_env) {
        'production' => 'https://api.healthfitheal.com/api/v1',
        'staging' => 'https://api-staging.healthfitheal.com/api/v1',
        _ => 'https://api-dev.healthfitheal.com/api/v1',
      };

  // ── Logging ────────────────────────────────────────────────────────────────

  /// Whether to enable verbose logging (disabled in production).
  static bool get enableLogging => !isProduction;

  /// Whether to show the debug banner in the app.
  static bool get showDebugBanner => isDevelopment;

  // ── Firebase ───────────────────────────────────────────────────────────────

  /// Whether Firebase services are active.
  /// Requires `google-services.json` in android/app/ and flutterfire configure.
  static bool get enableFirebase => AppSecrets.firebaseEnabled;

  // ── AI Provider ────────────────────────────────────────────────────────────

  /// The active AI provider: 'gemini' | 'openai' | 'mock'
  static String get aiProvider => AppSecrets.resolvedAiProvider;

  // ── Health Connect ─────────────────────────────────────────────────────────

  /// Whether Android Health Connect integration is enabled.
  // ignore: do_not_use_environment
  static const bool enableHealthConnect = bool.fromEnvironment(
    'HEALTH_CONNECT_ENABLED',
    defaultValue: true,
  );

  // ── Networking ─────────────────────────────────────────────────────────────

  /// Connection timeout duration.
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout duration.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Send timeout duration.
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for failed network requests.
  static const int maxRetries = 3;

  // ── Security ───────────────────────────────────────────────────────────────

  /// Whether certificate pinning is active.
  static bool get enableCertificatePinning =>
      isProduction && AppSecrets.pinnedFingerprints.isNotEmpty;

  // ── Feature Flags (override with Remote Config at runtime) ─────────────────

  static bool get enableAnalytics => isProduction || isStaging;
  static bool get enableCrashReporting => isProduction || isStaging;
  static bool get enablePerformanceMonitoring => isProduction;
}

