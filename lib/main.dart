import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/env/environment.dart';
import 'core/router/app_router.dart';
import 'core/utils/app_logger.dart';
import 'features/profile/domain/entities/profile_entity.dart';
import 'features/profile/presentation/providers/profile_providers.dart';
import 'injection_container.dart';
import 'theme/app_theme.dart';

/// Entry point for HealthFit Heal.
///
/// Startup sequence:
///   1. Flutter bindings
///   2. System UI / orientation lock
///   3. [InjectionContainer.initialize] — all services in dependency order
///   4. [runApp] with [ProviderScope] + provider overrides
Future<void> main() async {
  // ── Bindings ───────────────────────────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── Initialise All Services ────────────────────────────────────────────────
  final providerOverrides = await InjectionContainer.initialize();

  log.info(
    '╔════════════════════════════════════════╗\n'
    '║      HealthFit Heal — Starting         ║\n'
    '║  env=${Environment.name.padRight(35)}║\n'
    '║  ai =${Environment.aiProvider.padRight(35)}║\n'
    '║  fb =${Environment.enableFirebase.toString().padRight(35)}║\n'
    '╚════════════════════════════════════════╝',
  );

  // ── Run App ────────────────────────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: providerOverrides,
      child: const HealthFitHealApp(),
    ),
  );
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

