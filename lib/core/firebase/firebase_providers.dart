import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_analytics_service.dart';
import 'firebase_crashlytics_service.dart';
import 'remote_config_service.dart';

// ── Firebase Analytics ─────────────────────────────────────────────────────────

/// Provides the singleton [FirebaseAnalyticsService].
final firebaseAnalyticsProvider = Provider<FirebaseAnalyticsService>(
  (_) => FirebaseAnalyticsService.instance,
  name: 'firebaseAnalyticsProvider',
);

// ── Firebase Crashlytics ───────────────────────────────────────────────────────

/// Provides the singleton [FirebaseCrashlyticsService].
final firebaseCrashlyticsProvider = Provider<FirebaseCrashlyticsService>(
  (_) => FirebaseCrashlyticsService.instance,
  name: 'firebaseCrashlyticsProvider',
);

// ── Remote Config ──────────────────────────────────────────────────────────────

/// Provides the singleton [RemoteConfigService].
/// Re-exported for convenience (also available directly from remote_config_service.dart).
final remoteConfigProvider = Provider<RemoteConfigService>(
  (_) => RemoteConfigService.instance,
  name: 'remoteConfigProvider',
);

// ── Maintenance Mode ───────────────────────────────────────────────────────────

/// Whether the backend is in maintenance mode.
/// Observed by the router to show a maintenance screen.
final maintenanceModeProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).maintenanceMode,
  name: 'maintenanceModeProvider',
);

/// Whether a force-update is required.
final forceUpdateRequiredProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).forceUpdateRequired,
  name: 'forceUpdateRequiredProvider',
);

// ── Feature Flags ──────────────────────────────────────────────────────────────

final featureHealthConnectProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).featureHealthConnect,
  name: 'featureHealthConnectProvider',
);

final featureAiCoachProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).featureAiCoach,
  name: 'featureAiCoachProvider',
);

final featureReportsProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).featureReports,
  name: 'featureReportsProvider',
);

