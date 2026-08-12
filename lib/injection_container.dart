import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env/environment.dart';
import '../config/firebase/firebase_config.dart';
import '../core/firebase/firebase_crashlytics_service.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_info.dart';
import '../core/router/app_router.dart';
import '../core/security/api_key_manager.dart';
import '../core/storage/hive_service.dart';
import '../core/sync/sync_manager.dart';
import '../core/sync/sync_queue.dart';
import '../core/utils/app_logger.dart';
import '../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../features/auth/data/datasources/firebase_auth_token_provider.dart';
import '../features/notifications/data/services/deep_link_service.dart';
import '../features/notifications/data/services/fcm_service.dart';
import '../features/notifications/data/services/fcm_token_manager.dart';
import '../features/notifications/data/services/notification_service.dart';
import '../features/health/data/services/health_connect_sync_service.dart';

/// Central dependency injection and initialization container for HealthFit Heal.
///
/// Orchestrates the startup sequence in the correct order:
///   1. Hive (local storage — everything else depends on this)
///   2. SyncQueue (depends on Hive)
///   3. Firebase (optional — guarded by [Environment.enableFirebase])
///   4. Network layer (TokenProvider injection)
///   5. Notifications (channels + FCM)
///   6. Health Connect sync
///   7. API key validation
///   8. AppLogger Crashlytics wiring
///
/// Call [InjectionContainer.initialize] from [main] after
/// [WidgetsFlutterBinding.ensureInitialized].
abstract final class InjectionContainer {
  /// Initialises all services in dependency order.
  ///
  /// [container] is used to override providers for the [ProviderScope].
  static Future<List<Override>> initialize() async {
    final overrides = <Override>[];

    // ── Step 1: Local Storage ──────────────────────────────────────────────
    await HiveService.instance.init();
    log.info('IC: Hive initialized');

    // ── Step 2: Offline Sync Queue ─────────────────────────────────────────
    await SyncQueue.instance.initialize();
    log.info('IC: SyncQueue initialized');

    // ── Step 3: Firebase ───────────────────────────────────────────────────
    if (Environment.enableFirebase) {
      await _initFirebase(overrides);
    } else {
      log.info('IC: Firebase disabled (set FIREBASE_ENABLED=true to activate)');
    }

    // ── Step 4: Network ────────────────────────────────────────────────────
    _initNetwork(overrides);

    // ── Step 5: Notifications ──────────────────────────────────────────────
    await _initNotifications();

    // ── Step 6: Health Connect ─────────────────────────────────────────────
    await _initHealthConnect();

    // ── Step 7: Security Validation ────────────────────────────────────────
    ApiKeyManager.validate();

    log.info(
      'IC: initialization complete '
      '(env=${Environment.name}, '
      'firebase=${Environment.enableFirebase}, '
      'ai=${Environment.aiProvider})',
    );

    return overrides;
  }

  // ── Firebase ───────────────────────────────────────────────────────────────

  static Future<void> _initFirebase(List<Override> overrides) async {
    await FirebaseConfig.init();
    log.info('IC: Firebase initialized');

    // ── Firebase Auth token provider ───────────────────────────────────────
    final firebaseAuth = FirebaseAuthDatasource();

    final tokenProvider = FirebaseAuthTokenProvider(
      firebaseAuth: firebaseAuth,
    );

    // ── Crashlytics routing into AppLogger ─────────────────────────────────
    final crashlytics = FirebaseCrashlyticsService.instance;
    log.setCrashlyticsCallback((error, stackTrace, {required fatal}) {
      if (error != null) {
        crashlytics.recordError(error, stackTrace, fatal: fatal);
      }
    });

    log.info('IC: Crashlytics → AppLogger wired');
  }

  // ── Network ────────────────────────────────────────────────────────────────

  static void _initNetwork(List<Override> overrides) {
    // DioClient will use NoOpTokenProvider unless Firebase is enabled.
    // Firebase token provider is wired in _initFirebase via DioClient.setTokenProvider
    // after Firebase Auth is confirmed available.
    //
    // DioClient is a static class — no Riverpod override needed.
    log.info('IC: Network layer configured (base=${Environment.baseUrl})');
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  static Future<void> _initNotifications() async {
    // Local notifications
    await NotificationService.instance.initialize();
    log.info('IC: NotificationService initialized');

    // FCM (only when Firebase is enabled)
    if (Environment.enableFirebase) {
      await FcmService.instance.initialize(
        onForegroundMessage: (message) async {
          // Display foreground FCM messages as local notifications
          final title = DeepLinkService.instance.extractTitle(message);
          final body = DeepLinkService.instance.extractBody(message);
          if (title != null && body != null) {
            await NotificationService.instance.show(
              id: message.hashCode,
              title: title,
              body: body,
              payload: DeepLinkService.instance.handleDeepLink(message),
            );
          }
        },
        onMessageOpenedApp: (message) {
          if (message == null) return;
          final route = DeepLinkService.instance.handleDeepLink(message);
          if (route != null) {
            log.info('IC: FCM deep link → $route');
            // Router navigation will be handled when the app is running
            // via the deep link service payload
          }
        },
      );

      // Upload FCM token to backend
      final token = await FcmService.instance.getToken();
      await FcmTokenManager.instance.updateToken(token);

      log.info('IC: FCM initialized (token=${token?.substring(0, 10)}...)');
    }
  }

  // ── Health Connect ─────────────────────────────────────────────────────────

  static Future<void> _initHealthConnect() async {
    if (!Environment.enableHealthConnect) return;

    await HealthConnectSyncService.instance.initialize();
    log.info('IC: HealthConnectSyncService initialized');
  }
}

