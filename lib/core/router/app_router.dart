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
import '../../features/health/presentation/pages/bmi_page.dart';
import '../../features/health/presentation/pages/blood_pressure_page.dart';
import '../../features/health/presentation/pages/blood_sugar_page.dart';
import '../../features/health/presentation/pages/health_dashboard_page.dart';
import '../../features/health/presentation/pages/health_history_page.dart';
import '../../features/health/presentation/pages/heart_rate_page.dart';
import '../../features/health/presentation/pages/medical_records_page.dart';
import '../../features/health/presentation/pages/spo2_page.dart';
import '../../features/fitness/presentation/pages/achievements_page.dart';
import '../../features/fitness/presentation/pages/active_session_page.dart';
import '../../features/fitness/presentation/pages/fitness_analytics_page.dart';
import '../../features/fitness/presentation/pages/fitness_dashboard_page.dart';
import '../../features/fitness/presentation/pages/session_summary_page.dart';
import '../../features/fitness/presentation/pages/workout_detail_page.dart';
import '../../features/fitness/presentation/pages/workout_history_page.dart';
import '../../features/fitness/presentation/pages/workout_library_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/placeholder_pages.dart';
import '../../features/home/presentation/shell/main_shell_page.dart';
import '../../shared/widgets/app_error_widget.dart';
import 'route_names.dart';

part 'app_router.g.dart';

/// GoRouter provider for HealthFit Heal.
///
/// Navigation structure:
///   - Public routes: /splash, /onboarding
///   - Auth routes:   /login, /register, /forgot-password
///   - Shell routes:  StatefulShellRoute wrapping 5 bottom-nav tabs
///   - Modal routes:  /ai-assistant (pushed over the shell)
///
/// Auth guard:
///   - Unauthenticated on a protected route → [RouteNames.login]
///   - Authenticated on an auth route       → [RouteNames.home]
///   - Splash/Onboarding: no redirect applied (self-managed)
@riverpod
GoRouter appRouter(Ref ref) {
  final authListenable = _AuthChangeNotifier(ref);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,

    // ── Global Error Page ──────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: AppErrorWidget(
        message: 'Page not found: ${state.uri.path}',
        onRetry: () => context.go(RouteNames.home),
        retryLabel: 'Go Home',
      ),
    ),

    // ── Auth Guard ─────────────────────────────────────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // Public routes — never redirected
      if (location == RouteNames.splash ||
          location == RouteNames.onboarding) {
        return null;
      }

      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.forgotPassword;

      final isAuthenticated = authState is AuthAuthenticated;
      final isInitialOrLoading =
          authState is AuthInitial || authState is AuthLoading;

      if (isInitialOrLoading) return null;

      if (!isAuthenticated && !isAuthRoute) return RouteNames.login;
      if (isAuthenticated && isAuthRoute) return RouteNames.home;

      return null;
    },

    routes: [
      // ── Public / Auth Routes ─────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // ── AI Assistant (modal — presented over the shell) ──────────────────
      GoRoute(
        path: RouteNames.aiAssistant,
        name: 'ai-assistant',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: AiAssistantPlaceholderPage(),
        ),
      ),

      // ── Insights (modal — presented over the shell) ──────────────────────
      GoRoute(
        path: RouteNames.insights,
        name: 'insights',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: AiAssistantPlaceholderPage(), // Reuse until Insights feature is built
        ),
      ),

      // ── Main Shell (tabs + bottom nav + FAB) ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShellPage(
          navigationShell: navigationShell,
        ),
        branches: [
          // ── Tab 0: Home ──────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                name: 'home',
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),

          // ── Tab 1: Health ────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.healthDashboard,
                name: 'health',
                builder: (_, __) => const HealthDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'bmi',
                    name: 'bmi',
                    builder: (_, __) => const BmiPage(),
                  ),
                  GoRoute(
                    path: 'heart-rate',
                    name: 'heart-rate',
                    builder: (_, __) => const HeartRatePage(),
                  ),
                  GoRoute(
                    path: 'blood-pressure',
                    name: 'blood-pressure',
                    builder: (_, __) => const BloodPressurePage(),
                  ),
                  GoRoute(
                    path: 'blood-sugar',
                    name: 'blood-sugar',
                    builder: (_, __) => const BloodSugarPage(),
                  ),
                  GoRoute(
                    path: 'spo2',
                    name: 'spo2',
                    builder: (_, __) => const Spo2Page(),
                  ),
                  GoRoute(
                    path: 'medical-records',
                    name: 'medical-records',
                    builder: (_, __) => const MedicalRecordsPage(),
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'health-history',
                    builder: (_, __) => const HealthHistoryPage(),
                  ),
                  // Legacy stub routes
                  GoRoute(
                    path: 'steps',
                    name: 'steps',
                    builder: (_, __) => const HealthDashboardPage(),
                  ),
                  GoRoute(
                    path: 'sleep',
                    name: 'sleep',
                    builder: (_, __) => const HealthDashboardPage(),
                  ),
                  GoRoute(
                    path: 'water',
                    name: 'water',
                    builder: (_, __) => const HealthDashboardPage(),
                  ),
                  GoRoute(
                    path: 'calories',
                    name: 'calories',
                    builder: (_, __) => const HealthDashboardPage(),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 2: Fitness ───────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.workouts,
                name: 'fitness',
                builder: (_, __) => const FitnessDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'library',
                    name: 'workout-library',
                    builder: (context, state) {
                      final cat = state.uri.queryParameters['category'];
                      return WorkoutLibraryPage(initialCategory: cat);
                    },
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    name: 'workout-detail',
                    builder: (_, state) => WorkoutDetailPage(
                      workoutId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'session',
                    name: 'active-session',
                    builder: (_, __) => const ActiveSessionPage(),
                    routes: [
                      GoRoute(
                        path: 'summary',
                        name: 'session-summary',
                        builder: (_, __) => const SessionSummaryPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'history',
                    name: 'workout-history',
                    builder: (_, __) => const WorkoutHistoryPage(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    name: 'fitness-analytics',
                    builder: (_, __) => const FitnessAnalyticsPage(),
                  ),
                  GoRoute(
                    path: 'achievements',
                    name: 'achievements',
                    builder: (_, __) => const AchievementsPage(),
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 3: Nutrition ─────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.nutrition,
                name: 'nutrition',
                builder: (_, __) => const NutritionPlaceholderPage(),
              ),
            ],
          ),

          // ── Tab 4: Profile ───────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                name: 'profile',
                builder: (_, __) => const ProfilePlaceholderPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ── Auth Change Notifier ──────────────────────────────────────────────────────

/// Listens to [authNotifierProvider] and notifies GoRouter to re-evaluate
/// the redirect guard whenever the auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    _sub = ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
