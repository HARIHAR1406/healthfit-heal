import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/app_loading.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// GoRouter provider for HealthFit Heal.
///
/// Authentication redirect logic will be wired here once the auth feature
/// is implemented. For now, the router starts at [RouteNames.home] directly.
///
/// Usage: `ref.watch(appRouterProvider)`
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: true,

    // ── Error Page ──────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: AppErrorWidget(
        message: 'Page not found: ${state.uri.path}',
        onRetry: () => context.go(RouteNames.home),
        retryLabel: 'Go Home',
      ),
    ),

    // ── Redirect ─────────────────────────────────────────────────────────────
    // TODO: Wire auth state here.
    // redirect: (context, state) {
    //   final isLoggedIn = ref.read(authStateProvider).isAuthenticated;
    //   final isAuthRoute = state.matchedLocation.startsWith('/login') ||
    //       state.matchedLocation.startsWith('/register');
    //   if (!isLoggedIn && !isAuthRoute) return RouteNames.login;
    //   if (isLoggedIn && isAuthRoute) return RouteNames.home;
    //   return null;
    // },

    routes: [
      // ── Placeholder Home ───────────────────────────────────────────────
      GoRoute(
        path: RouteNames.home,
        name: RouteNames.home,
        builder: (context, state) => const _PlaceholderPage(title: 'Home'),
      ),

      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const _PlaceholderPage(title: 'Login'),
      ),

      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const _PlaceholderPage(title: 'Register'),
      ),

      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, state) => const _PlaceholderPage(title: 'Splash'),
      ),

      // ── Add feature routes here as features are implemented ────────────
    ],
  );
}

/// Temporary placeholder page used until feature screens are built.
///
/// DELETE this class once real pages are implemented.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(Feature coming soon)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
