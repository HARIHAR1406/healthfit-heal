import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

/// Manages the global authentication state for HealthFit Heal.
///
/// All auth operations go through this notifier.
/// The router and UI observe [AuthState] changes.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
  })  : _login = loginUseCase,
        _register = registerUseCase,
        _logout = logoutUseCase,
        _forgotPassword = forgotPasswordUseCase,
        _getCurrentUser = getCurrentUserUseCase,
        _checkAuthStatus = checkAuthStatusUseCase,
        super(const AuthInitial());

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final ForgotPasswordUseCase _forgotPassword;
  final GetCurrentUserUseCase _getCurrentUser;
  final CheckAuthStatusUseCase _checkAuthStatus;

  // ── Auth Check ─────────────────────────────────────────────────────────────

  /// Checks session on app startup.
  ///
  /// Emits [AuthAuthenticated] or [AuthUnauthenticated].
  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final isAuthenticated = await _checkAuthStatus();
      if (isAuthenticated) {
        final user = await _getCurrentUser();
        if (user != null) {
          state = AuthAuthenticated(user: user);
          log.info('AuthNotifier: session restored for ${user.email}');
        } else {
          state = const AuthUnauthenticated();
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      log.error('AuthNotifier: checkAuthStatus failed', error: e);
      state = const AuthUnauthenticated();
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Signs in with email + password.
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      state = AuthAuthenticated(user: user);
      log.info('AuthNotifier: login successful');
    } on AppException catch (e) {
      final failure = Failure.fromException(e);
      state = AuthError(message: failure.message, code: failure.code);
      log.warning('AuthNotifier: login failed — ${e.message}');
    } catch (e) {
      state = const AuthError(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// Creates a new account.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _register(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      state = AuthAuthenticated(user: user);
      log.info('AuthNotifier: registration successful');
    } on AppException catch (e) {
      final failure = Failure.fromException(e);
      state = AuthError(message: failure.message, code: failure.code);
      log.warning('AuthNotifier: registration failed — ${e.message}');
    } catch (e) {
      state = const AuthError(
        message: 'Registration failed. Please try again.',
      );
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Signs out and clears session data.
  Future<void> logout() async {
    try {
      await _logout();
      state = const AuthUnauthenticated();
      log.info('AuthNotifier: logout successful');
    } catch (e) {
      log.error('AuthNotifier: logout error (forcing local clear)', error: e);
      // Always transition to unauthenticated even if server call fails
      state = const AuthUnauthenticated();
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  /// Sends a password reset email.
  Future<void> sendPasswordReset({required String email}) async {
    state = const AuthLoading();
    try {
      await _forgotPassword(email: email);
      state = AuthPasswordResetSent(email: email);
      log.info('AuthNotifier: password reset email sent to $email');
    } on AppException catch (e) {
      final failure = Failure.fromException(e);
      state = AuthError(message: failure.message, code: failure.code);
    } catch (e) {
      state = const AuthError(
        message: 'Failed to send reset email. Please try again.',
      );
    }
  }

  // ── Reset Error ────────────────────────────────────────────────────────────

  /// Clears the current error state back to unauthenticated.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

