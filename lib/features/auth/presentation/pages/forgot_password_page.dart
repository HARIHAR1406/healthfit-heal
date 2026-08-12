import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_header.dart';

/// Forgot password screen with email input and animated success state.
///
/// States:
///   1. Input: User enters email → taps "Send Reset Link"
///   2. Loading: Button shows spinner
///   3. Success: Animated checkmark + instructions shown
///   4. Error: Inline error banner
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final AnimationController _successController;
  late final Animation<double> _successScale;
  late final Animation<double> _successOpacity;

  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _successOpacity = CurvedAnimation(
      parent: _successController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authNotifierProvider.notifier).sendPasswordReset(
          email: _emailController.text.trim(),
        );
  }

  void _handleAuthState(AuthState? previous, AuthState next) {
    if (next is AuthPasswordResetSent && !_isSuccess) {
      setState(() => _isSuccess = true);
      _successController.forward();
    }
    // Reset to unauthenticated if user navigates away and comes back
    if (next is AuthUnauthenticated && _isSuccess) {
      setState(() => _isSuccess = false);
      _successController.reset();
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, _handleAuthState);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMsg = authState is AuthError ? (authState).message : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            // Clear any auth error before navigating back
            ref.read(authNotifierProvider.notifier).clearError();
            context.pop();
          },
        ),
        title: Text(
          'Forgot Password',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isSuccess
            ? _SuccessView(
                email: _emailController.text.trim(),
                scaleAnimation: _successScale,
                opacityAnimation: _successOpacity,
                onBackToLogin: () {
                  ref.read(authNotifierProvider.notifier).clearError();
                  context.go(RouteNames.login);
                },
              )
            : _InputView(
                formKey: _formKey,
                emailController: _emailController,
                isLoading: isLoading,
                errorMsg: errorMsg,
                onSubmit: _submit,
                onBackToLogin: () {
                  ref.read(authNotifierProvider.notifier).clearError();
                  context.pop();
                },
              ),
      ),
    );
  }
}

// ── Input View ────────────────────────────────────────────────────────────────

class _InputView extends StatelessWidget {
  const _InputView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.errorMsg,
    required this.onSubmit,
    required this.onBackToLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onSubmit;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      key: const ValueKey('input'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ────────────────────────────────────────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: AppSpacing.iconXl,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Reset your password',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            "Enter the email address associated with your account. We'll send you a link to reset your password.",
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Error Banner ─────────────────────────────────────────────────
          if (errorMsg != null) ...[
            _ForgotErrorBanner(message: errorMsg!),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Form ─────────────────────────────────────────────────────────
          Form(
            key: formKey,
            child: AppTextField(
              label: 'Email address',
              hint: 'you@example.com',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              prefixIcon: const Icon(Icons.email_outlined),
              onSubmitted: (_) => onSubmit(),
              validator: (v) => AppValidators.email(v),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Submit Button ────────────────────────────────────────────────
          AppButton(
            label: 'Send Reset Link',
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            height: AppSpacing.buttonHeightLg,
            leadingIcon: isLoading ? null : Icons.send_rounded,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Back to Login ────────────────────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: onBackToLogin,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Back to Sign In',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.email,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onBackToLogin,
  });

  final String email;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animated Checkmark ────────────────────────────────────────────
          ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            'Check your inbox!',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            "We've sent a password reset link to",
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            email,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            "Didn't receive it? Check your spam folder or wait a few minutes.",
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.massive),

          // ── Back to Login ────────────────────────────────────────────────
          AppButton(
            label: 'Back to Sign In',
            onPressed: onBackToLogin,
            leadingIcon: Icons.arrow_back_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ForgotErrorBanner extends StatelessWidget {
  const _ForgotErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

