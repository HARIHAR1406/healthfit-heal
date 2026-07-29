import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/env/environment.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/utils/app_logger.dart';
import 'features/notifications/data/services/background_service.dart';
import 'features/notifications/data/services/notification_service.dart';
import 'features/profile/domain/entities/profile_entity.dart';
import 'features/profile/presentation/providers/profile_providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialised before any platform calls
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Initialise Services ────────────────────────────────────────────────────
  await _initServices();

  // ── Run App ────────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: HealthFitHealApp(),
    ),
  );
}

/// Initialises all services required before [runApp].
Future<void> _initServices() async {
  log.info(
    'Starting HealthFit Heal — '
    'env=${Environment.name} '
    'baseUrl=${Environment.baseUrl}',
  );

  // ── Hive (local storage) ───────────────────────────────────────────────────
  await HiveService.instance.init();

  // ── Notification Service ───────────────────────────────────────────────────
  // Mock mode: no platform permissions requested at startup.
  // To activate real notifications, add flutter_local_notifications to
  // pubspec.yaml and configure AndroidManifest/Info.plist (see NotificationService).
  await NotificationService.instance.initialize();

  // ── Background Service ────────────────────────────────────────────────────
  // Registers all background task handlers (mock implementations).
  // To activate real background tasks, add workmanager and call
  // schedulePeriodicTask for each BackgroundTaskType in BackgroundService.
  await BackgroundService.instance.initialize();

  // ── Firebase (placeholder — uncomment when configured) ────────────────────
  // await FirebaseConfig.init();

  log.info('Services initialised successfully.');
}

/// Root application widget for HealthFit Heal.
///
/// Wires [GoRouter] from [appRouterProvider] into [MaterialApp.router],
/// and provides both [AppTheme.lightTheme] and [AppTheme.darkTheme].
class HealthFitHealApp extends ConsumerWidget {
  const HealthFitHealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // ── App Metadata ──────────────────────────────────────────────────────
      title: 'HealthFit Heal',
      debugShowCheckedModeBanner: Environment.showDebugBanner,

      // ── Theming ───────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _resolveThemeMode(ref.watch(appThemePreferenceProvider)),

      // ── Navigation ────────────────────────────────────────────────────────
      routerConfig: router,

      // ── Localisation ──────────────────────────────────────────────────────
      // TODO: Add flutter_localizations when i18n is implemented.
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
      // locale: ref.watch(localeProvider),
    );
  }
}

/// Maps [AppThemePreference] to Flutter's [ThemeMode].
ThemeMode _resolveThemeMode(AppThemePreference pref) {
  return switch (pref) {
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
    AppThemePreference.system => ThemeMode.system,
  };
}
