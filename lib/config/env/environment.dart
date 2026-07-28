/// Environment configuration for HealthFit Heal.
///
/// Selects the API base URL based on the `--dart-define=ENVIRONMENT=`
/// compile-time variable. Defaults to 'development'.
///
/// Build commands:
///   Development: flutter run --dart-define=ENVIRONMENT=development
///   Staging:     flutter run --dart-define=ENVIRONMENT=staging
///   Production:  flutter build apk --dart-define=ENVIRONMENT=production
abstract final class Environment {
  // ignore: do_not_use_environment
  static const String _env = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => _env == 'development';
  static bool get isStaging => _env == 'staging';
  static bool get isProduction => _env == 'production';

  /// Current environment name.
  static String get name => _env;

  /// The base URL for the active environment.
  static String get baseUrl => switch (_env) {
        'production' => 'https://api.healthfitheal.com/api/v1',
        'staging' => 'https://api-staging.healthfitheal.com/api/v1',
        _ => 'https://api-dev.healthfitheal.com/api/v1',
      };

  /// Whether to enable verbose logging.
  static bool get enableLogging => !isProduction;

  /// Whether to show the debug banner in the app.
  static bool get showDebugBanner => isDevelopment;
}
