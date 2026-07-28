import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../shared/widgets/app_error_widget.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// GoRouter provider for HealthFit Heal.
///
/// Auth guard redirects:
///   - Unauthenticated on a protected route → [RouteNames.login]
///   - Authenticated on an auth route (login/register) → [RouteNames.home]
///   - Splash handles its own navigation — no redirect applied there.
@riverpod
GoRouter appRouter(Ref ref) {
  // Trigger router rebuild when auth state changes
  final authListenable = _AuthChangeNotifier(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,

    // ── Global Error Page ────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: AppErrorWidget(
        message: 'Page not found: ${state.uri.path}',
        onRetry: () => context.go(RouteNames.home),
        retryLabel: 'Go Home',
      ),
    ),

    // ── Auth Guard ────────────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // Public routes — no redirect applied
      final isPublicRoute = location == RouteNames.splash ||
          location == RouteNames.onboarding;
      if (isPublicRoute) return null;

      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.forgotPassword;

      final isAuthenticated = authState is AuthAuthenticated;
      final isInitialOrLoading =
          authState is AuthInitial || authState is AuthLoading;

      // Loading — let splash handle it, don't redirect
      if (isInitialOrLoading) return null;

      // Unauthenticated user trying to reach a protected page
      if (!isAuthenticated && !isAuthRoute) {
        return RouteNames.login;
      }

      // Authenticated user landing on an auth page
      if (isAuthenticated && isAuthRoute) {
        return RouteNames.home;
      }

      return null;
    },

    routes: [
      // ── Auth Routes ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ── Protected Routes ────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const _PlaceholderHomePage(),
      ),

      // ── Additional feature routes will be added here ─────────────────────
    ],
  );
}

/// [ChangeNotifier] that notifies GoRouter whenever [authNotifierProvider]
/// emits a new state, triggering the redirect guard to re-evaluate.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Temporary home placeholder until the Home feature is implemented.
///
/// DELETE and replace with the real HomeShellPage when implementing the Home module.
class _PlaceholderHomePage extends ConsumerWidget {
  const _PlaceholderHomePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthFit Heal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 64,
              color: Color(0xFF00C896),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.firstName ?? 'User'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Auth module is working correctly.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF00C896),
                  ),
            ),
            const SizedBox(height: 32),
            const Text(
              '(Home feature coming next)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
