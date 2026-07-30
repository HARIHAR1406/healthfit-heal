import '../../config/env/app_secrets.dart';
import '../../config/env/environment.dart';
import '../utils/app_logger.dart';

/// Central API key accessor for HealthFit Heal.
///
/// All API keys are read from [AppSecrets] (dart-define compile-time values).
/// They are NEVER stored in SharedPreferences, Hive, logs, or source code.
///
/// In production, keys are injected via CI/CD secrets → --dart-define arguments.
///
/// ── Access pattern ───────────────────────────────────────────────────────────
/// DO:
///   final key = ApiKeyManager.geminiApiKey;
///
/// DON'T:
///   const key = 'AIzaSy...'; // Never hardcode
///   prefs.setString('api_key', key); // Never persist to preferences
///   log.info('Key: $key'); // Never log keys
abstract final class ApiKeyManager {
  // ── Gemini ─────────────────────────────────────────────────────────────────

  /// Google Gemini API key.
  ///
  /// Returns empty string in development if not set.
  static String get geminiApiKey {
    _assertNotLogged();
    return AppSecrets.geminiApiKey;
  }

  /// Returns true if the Gemini key is present and non-empty.
  static bool get hasGeminiKey => AppSecrets.hasGeminiKey;

  // ── OpenAI ─────────────────────────────────────────────────────────────────

  /// OpenAI API key.
  static String get openAiApiKey {
    _assertNotLogged();
    return AppSecrets.openAiApiKey;
  }

  /// Returns true if the OpenAI key is present and starts with 'sk-'.
  static bool get hasOpenAiKey => AppSecrets.hasOpenAiKey;

  // ── Provider Info (safe to log) ────────────────────────────────────────────

  /// Returns the active AI provider identifier (safe to log — no key value).
  static String get activeAiProvider => AppSecrets.resolvedAiProvider;

  // ── Security Validation ────────────────────────────────────────────────────

  /// Validates that required production keys are configured.
  ///
  /// Logs warnings for missing keys. Call at app startup in non-dev envs.
  static void validate() {
    if (Environment.isDevelopment) return;

    final provider = AppSecrets.resolvedAiProvider;

    if (provider == 'gemini' && !hasGeminiKey) {
      log.warning(
        'ApiKeyManager: AI_PROVIDER=gemini but GEMINI_API_KEY is not set',
      );
    }

    if (provider == 'openai' && !hasOpenAiKey) {
      log.warning(
        'ApiKeyManager: AI_PROVIDER=openai but OPENAI_API_KEY is not set '
        '(key must start with sk-)',
      );
    }

    if (Environment.enableCertificatePinning &&
        AppSecrets.pinnedFingerprints.isEmpty) {
      log.warning(
        'ApiKeyManager: certificate pinning enabled but '
        'PINNED_CERT_FINGERPRINTS is empty',
      );
    }

    log.info(
      'ApiKeyManager: validated '
      '(aiProvider=$activeAiProvider, '
      'gemini=${hasGeminiKey ? 'set' : 'missing'}, '
      'openai=${hasOpenAiKey ? 'set' : 'missing'})',
    );
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Guard: ensures keys are not accidentally logged.
  static void _assertNotLogged() {
    // This is a compile-time guard concept.
    // Developers must not pass the return value of these getters to log.*
    // Code review: check for log.*(ApiKeyManager.*) pattern.
  }
}
