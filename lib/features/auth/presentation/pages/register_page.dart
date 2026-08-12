import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/social_sign_in_button.dart';
import '../widgets/terms_checkbox.dart';
import 'login_page.dart' show _AuthNavRow, _ErrorBanner;

/// Full registration screen for HealthFit Heal.
///
/// Features:
///   - Full Name, Email, Mobile, Password, Confirm Password
///   - Show/Hide toggles on password fields
///   - Terms & Conditions checkbox
///   - Register button with loading state
///   - Google Sign-In option
///   - Field-level validation
///   - Error banner
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _termsError = false;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;

    if (!_acceptedTerms) {
      setState(() => _termsError = true);
    }

    if (!formValid || !_acceptedTerms) return;

    setState(() => _termsError = false);

    await ref.read(authNotifierProvider.notifier).register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
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

  void _handleAuthState(AuthState? previous, AuthState next) {
    if (next is AuthAuthenticated) {
      context.go(RouteNames.home);
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ── Top Header ─────────────────────────────────────────────────
            AuthHeader(
              subtitle: 'Create account ✨',
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
                      Text(
                        'Join HealthFit Heal',
                        style: AppTypography.titleLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Start your wellness journey today.',
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

                      // ── Full Name ────────────────────────────────────────
                      AppTextField(
                        label: 'Full name',
                        hint: 'John Doe',
                        controller: _nameController,
                        focusNode: _nameFocus,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          if (v.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

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
                        onSubmitted: (_) => _phoneFocus.requestFocus(),
                        validator: (v) => AppValidators.email(v),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Phone Number ─────────────────────────────────────
                      AppTextField(
                        label: 'Mobile number (optional)',
                        hint: '+91 98765 43210',
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        prefixIcon: const Icon(Icons.phone_outlined),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\- ]'),
                          ),
                        ],
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return AppValidators.phone(v);
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Password ─────────────────────────────────────────
                      AppTextField(
                        label: 'Password',
                        hint: 'Min. 8 characters',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                        ),
                        onSubmitted: (_) => _confirmFocus.requestFocus(),
                        validator: (v) => AppValidators.password(v),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Confirm Password ──────────────────────────────────
                      AppTextField(
                        label: 'Confirm password',
                        hint: '••••••••',
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                        ),
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Terms Checkbox ───────────────────────────────────
                      TermsCheckbox(
                        value: _acceptedTerms,
                        onChanged: (v) =>
                            setState(() {
                              _acceptedTerms = v;
                              if (v) _termsError = false;
                            }),
                        hasError: _termsError,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Register Button ──────────────────────────────────
                      AppButton(
                        label: 'Create Account',
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

                      // ── Login Link ───────────────────────────────────────
                      _AuthNavRow(
                        question: 'Already have an account?',
                        actionLabel: 'Sign in',
                        onTap: () => context.go(RouteNames.login),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
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

