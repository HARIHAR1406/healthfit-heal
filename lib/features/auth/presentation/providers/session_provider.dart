import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/session_service.dart';
import 'auth_providers.dart';

/// Async provider that performs the session check on app startup.
///
/// Used by [SplashPage] to determine the initial route.
/// Caches the result — will not re-run unless invalidated.
final sessionCheckProvider = FutureProvider.autoDispose<SessionStatus>(
  (ref) async {
    final sessionService = ref.watch(sessionServiceProvider);
    return sessionService.checkSession();
  },
  name: 'sessionCheckProvider',
);

/// Provides the remembered email for the login form auto-fill.
final rememberedEmailProvider = Provider<String?>(
  (ref) {
    final session = ref.watch(sessionServiceProvider);
    return session.rememberedEmail;
  },
  name: 'rememberedEmailProvider',
);

/// Whether onboarding has been completed.
final onboardingCompletedProvider = Provider<bool>(
  (ref) {
    final session = ref.watch(sessionServiceProvider);
    return session.isOnboardingCompleted;
  },
  name: 'onboardingCompletedProvider',
);
