import '../../domain/entities/user_entity.dart';

/// Sealed auth state hierarchy for HealthFit Heal.
///
/// Used by [AuthNotifier] and observed by the router + UI.
sealed class AuthState {
  const AuthState();
}

/// Initial state before any auth check has been performed.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An async auth operation is in progress (login, register, logout, etc.).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A valid session exists — user is signed in.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  /// The currently signed-in user.
  final UserEntity user;

  @override
  String toString() => 'AuthAuthenticated(user: ${user.email})';
}

/// No valid session — user must log in.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed.
final class AuthError extends AuthState {
  const AuthError({required this.message, this.code});

  /// User-facing error message.
  final String message;

  /// Optional machine-readable error code.
  final String? code;

  @override
  String toString() => 'AuthError(code: $code, message: $message)';
}

/// Password reset email was sent successfully.
final class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent({required this.email});

  final String email;
}

// ── Extension helpers ─────────────────────────────────────────────────────────

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isLoading => this is AuthLoading;
  bool get isError => this is AuthError;
  bool get isUnauthenticated => this is AuthUnauthenticated;

  UserEntity? get user =>
      this is AuthAuthenticated ? (this as AuthAuthenticated).user : null;

  String? get errorMessage =>
      this is AuthError ? (this as AuthError).message : null;
}

