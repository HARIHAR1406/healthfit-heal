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
import '../providers/session_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_sign_in_button.dart';

/// Full login screen for HealthFit Heal.
///
/// Features:
///   - Email + Password with show/hide
///   - Remember Me checkbox
///   - Forgot Password link
///   - Login button with loading state
///   - Google Sign-In
///   - Inline form validation + error banner
///   - Auto-fills remembered email
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _obscurePassword = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Auto-fill remembered email
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = ref.read(rememberedEmailProvider);
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
        _rememberMe = true;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
  }

  Future<void> _googleSignIn() async {
    // TODO: Implement when Google Sign-In is configured
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void _handleAuthState(AuthState? previous, AuthState next) {
    if (next is AuthAuthenticated) {
      context.go(RouteNames.home);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen for state changes
    ref.listen<AuthState>(authNotifierProvider, _handleAuthState);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMsg =
        authState is AuthError ? (authState).message : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ── Top Hero Header ────────────────────────────────────────────
            AuthHeader(
              subtitle: 'Welcome back 👋',
              compact: true,
            ),

            // ── Scrollable Form ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section heading
                      Text(
                        'Sign in to your account',
                        style: AppTypography.titleLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Enter your credentials to continue.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Error Banner ─────────────────────────────────────
                      if (errorMsg != null) ...[
                        _ErrorBanner(message: errorMsg),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // ── Email ────────────────────────────────────────────
                      AppTextField(
                        label: 'Email address',
                        hint: 'you@example.com',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        prefixIcon: const Icon(Icons.email_outlined),
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (v) => AppValidators.email(v),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Password ─────────────────────────────────────────
                      AppTextField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                        ),
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Remember Me + Forgot Password row ────────────────
                      Row(
                        children: [
                          _RememberMeCheckbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                context.push(RouteNames.forgotPassword),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Login Button ─────────────────────────────────────
                      AppButton(
                        label: 'Sign In',
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                        height: AppSpacing.buttonHeightLg,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Divider ──────────────────────────────────────────
                      const OrDivider(),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Google Sign-In ───────────────────────────────────
                      SocialSignInButton(
                        label: 'Continue with Google',
                        onPressed: isLoading ? null : _googleSignIn,
                        isEnabled: !isLoading,
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // ── Register Link ────────────────────────────────────
                      _AuthNavRow(
                        question: "Don't have an account?",
                        actionLabel: 'Create account',
                        onTap: () => context.go(RouteNames.register),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _RememberMeCheckbox extends StatelessWidget {
  const _RememberMeCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Remember me',
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation row: "Question? Action"
class _AuthNavRow extends StatelessWidget {
  const _AuthNavRow({
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            children: [
              TextSpan(text: '$question '),
              TextSpan(
                text: actionLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
