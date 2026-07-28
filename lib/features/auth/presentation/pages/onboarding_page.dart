import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';
import '../widgets/onboarding_indicator.dart';
import '../widgets/onboarding_page_item.dart';

/// Three-step onboarding screen with a [PageView].
///
/// Flow:
///   1. User swipes or taps Next through 3 slides.
///   2. On the last slide, "Get Started" replaces "Next".
///   3. Tapping Skip or Get Started calls [SessionService.completeOnboarding]
///      and navigates to [RouteNames.login].
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final sessionService = ref.read(sessionServiceProvider);
    await sessionService.completeOnboarding();

    if (mounted) context.go(RouteNames.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == onboardingPages.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip Button ──────────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),

            // ── PageView ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) => OnboardingPageItem(
                  data: onboardingPages[index],
                  pageIndex: index,
                ),
              ),
            ),

            // ── Bottom Controls ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  // Dot indicator
                  OnboardingIndicator(
                    pageCount: onboardingPages.length,
                    currentPage: _currentPage,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Next / Get Started button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      key: ValueKey<bool>(isLast),
                      width: double.infinity,
                      height: AppSpacing.buttonHeightLg,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: onboardingPages[_currentPage]
                              .gradientColors[1],
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Get Started' : 'Next',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              isLast
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              size: AppSpacing.iconSm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Already have account
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Log in',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
