import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_logger.dart';

/// Firebase Remote Config wrapper for HealthFit Heal.
///
/// Provides typed accessors for all remote-controlled feature flags and values.
/// Falls back to compile-time defaults when Firebase is unavailable.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService _instance = RemoteConfigService._();
  static RemoteConfigService get instance => _instance;

  FirebaseRemoteConfig get _config => FirebaseRemoteConfig.instance;

  // ── Fetch & Activate ───────────────────────────────────────────────────────

  /// Fetches the latest remote config values and activates them.
  Future<void> refresh() async {
    try {
      final updated = await _config.fetchAndActivate();
      log.info('RemoteConfig: refresh completed (updated=$updated)');
    } catch (e) {
      log.warning('RemoteConfig: refresh failed — using cached values', error: e);
    }
  }

  // ── AI Provider Flags ──────────────────────────────────────────────────────

  /// Active AI provider override from Remote Config.
  /// 'gemini' | 'openai' | 'mock'
  String get aiProvider => _config.getString('ai_provider');

  /// AI model identifier.
  String get aiModel => _config.getString('ai_model');

  /// Maximum messages per AI session before prompting to start a new chat.
  int get maxAiMessagesPerSession =>
      _config.getInt('max_ai_messages_per_session');

  // ── Sync Flags ─────────────────────────────────────────────────────────────

  /// How often Health Connect data should sync, in minutes.
  int get healthSyncIntervalMinutes =>
      _config.getInt('health_sync_interval_minutes');

  /// Maximum number of items in the offline sync queue.
  int get offlineQueueMaxSize => _config.getInt('offline_queue_max_size');

  // ── App Control ────────────────────────────────────────────────────────────

  /// Whether the app is in maintenance mode (show maintenance screen).
  bool get maintenanceMode => _config.getBool('maintenance_mode');

  /// Whether a force update is required.
  bool get forceUpdateRequired => _config.getBool('force_update_required');

  /// Minimum app version string (semver) that can connect to the backend.
  String get minimumAppVersion => _config.getString('minimum_app_version');

  // ── Feature Flags ──────────────────────────────────────────────────────────

  bool get featureHealthConnect => _config.getBool('feature_health_connect');
  bool get featureAiCoach => _config.getBool('feature_ai_coach');
  bool get featureReports => _config.getBool('feature_reports');
  bool get featureNutritionAi => _config.getBool('feature_nutrition_ai');

  // ── Generic Accessors ──────────────────────────────────────────────────────

  String getString(String key) => _config.getString(key);
  bool getBool(String key) => _config.getBool(key);
  int getInt(String key) => _config.getInt(key);
  double getDouble(String key) => _config.getDouble(key);
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

/// Provides the singleton [RemoteConfigService].
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (_) => RemoteConfigService.instance,
  name: 'remoteConfigServiceProvider',
);
