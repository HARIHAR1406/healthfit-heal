import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_header.dart';
import '../../services/session_service.dart';

/// Animated splash screen for HealthFit Heal.
///
/// Shows the brand logo with a scale + fade animation, then checks
/// the session status and navigates to the appropriate screen:
///   - First launch → [RouteNames.onboarding]
///   - Authenticated → [RouteNames.home]
///   - Unauthenticated / expired → [RouteNames.login]
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
  }

  Future<void> _startSplashSequence() async {
    // Logo entrance
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // Text entrance
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textController.forward();

    // Session check delay
    await Future.delayed(
      const Duration(milliseconds: AppConstants.splashDelayMs),
    );
    if (!mounted) return;

    _navigate();
  }

  Future<void> _navigate() async {
    final sessionService = ref.read(sessionServiceProvider);
    final status = await sessionService.checkSession();

    if (!mounted) return;

    switch (status) {
      case SessionStatus.firstLaunch:
        context.go(RouteNames.onboarding);
      case SessionStatus.authenticated:
        // Restore user into auth state
        await ref.read(authNotifierProvider.notifier).checkAuthStatus();
        if (mounted) context.go(RouteNames.home);
      case SessionStatus.tokenExpired:
        // Try silent refresh, fall back to login
        await ref.read(authNotifierProvider.notifier).checkAuthStatus();
        if (mounted) {
          final isAuth = ref.read(isAuthenticatedProvider);
          context.go(isAuth ? RouteNames.home : RouteNames.login);
        }
      case SessionStatus.unauthenticated:
      case SessionStatus.unknown:
        context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundDark,
              AppColors.surfaceDark,
              Color(0xFF0A1F18),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Logo ──────────────────────────────────────────────────────────
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: const AuthLogo(size: 100),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── App Name & Tagline ─────────────────────────────────────────────
            FadeTransition(
              opacity: _textOpacity,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    Text(
                      'HealthFit Heal',
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your complete health companion',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary.withOpacity(0.9),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.massive),

            // ── Loading Indicator ─────────────────────────────────────────────
            FadeTransition(
              opacity: _textOpacity,
              child: _PulsingDots(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three pulsing dots loading indicator.
class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _controllers.add(ctrl);
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return FadeTransition(
          opacity: _controllers[i],
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
