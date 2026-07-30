/// Compile-time secret accessor for HealthFit Heal.
///
/// All API keys and secrets are injected at compile time via `--dart-define`.
/// They are NEVER stored in source control, preferences, or logs.
///
/// Usage (development):
///   flutter run \
///     --dart-define=ENVIRONMENT=development \
///     --dart-define=GEMINI_API_KEY=your_key \
///     --dart-define=OPENAI_API_KEY=your_key
///
/// Usage (production):
///   flutter build apk \
///     --dart-define=ENVIRONMENT=production \
///     --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }} \
///     --dart-define=OPENAI_API_KEY=${{ secrets.OPENAI_API_KEY }}
///
/// For CI/CD (GitHub Actions, Codemagic, Bitrise):
///   Pass secrets as environment variables → dart-define arguments.
///   Never echo them to build logs.
abstract final class AppSecrets {
  // ── AI Provider Keys ──────────────────────────────────────────────────────

  // ignore: do_not_use_environment
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // ignore: do_not_use_environment
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  // ── AI Provider Selection ─────────────────────────────────────────────────

  /// Which AI provider to use: 'gemini' | 'openai' | 'mock'
  // ignore: do_not_use_environment
  static const String aiProvider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'mock',
  );

  /// Which AI model to use (provider-specific).
  /// Gemini: 'gemini-1.5-flash' | 'gemini-1.5-pro' | 'gemini-2.0-flash'
  /// OpenAI: 'gpt-4o-mini' | 'gpt-4o'
  // ignore: do_not_use_environment
  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: '',
  );

  // ── Certificate Pinning ───────────────────────────────────────────────────

  /// Comma-separated SHA-256 fingerprints for certificate pinning.
  /// Format: 'sha256/AAAA...,sha256/BBBB...'
  /// Leave empty to disable pinning (development only).
  // ignore: do_not_use_environment
  static const String pinnedCertFingerprints = String.fromEnvironment(
    'PINNED_CERT_FINGERPRINTS',
    defaultValue: '',
  );

  // ── Sentry / Error Reporting ──────────────────────────────────────────────

  // ignore: do_not_use_environment
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // ── Feature Gate ──────────────────────────────────────────────────────────

  /// Whether Firebase is active. Set to 'true' when google-services.json
  /// is placed in android/app/ and flutterfire configure has been run.
  // ignore: do_not_use_environment
  static const bool firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  // ── Validation ────────────────────────────────────────────────────────────

  /// Returns true if the Gemini key appears valid (non-empty).
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Returns true if the OpenAI key appears valid (non-empty, starts with sk-).
  static bool get hasOpenAiKey =>
      openAiApiKey.isNotEmpty && openAiApiKey.startsWith('sk-');

  /// Returns true if at least one AI provider key is configured.
  static bool get hasAnyAiKey => hasGeminiKey || hasOpenAiKey;

  /// Returns the resolved AI provider taking key availability into account.
  static String get resolvedAiProvider {
    if (aiProvider == 'gemini' && hasGeminiKey) return 'gemini';
    if (aiProvider == 'openai' && hasOpenAiKey) return 'openai';
    return 'mock';
  }

  /// Pinned fingerprints as a list. Empty if pinning is disabled.
  static List<String> get pinnedFingerprints {
    if (pinnedCertFingerprints.isEmpty) return [];
    return pinnedCertFingerprints
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
  }
}
