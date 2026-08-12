import '../entities/auth_token_entity.dart';
import '../entities/user_entity.dart';

/// Abstract contract for all authentication operations.
///
/// The data layer provides the concrete implementation.
/// All methods return [Future] to support async I/O.
abstract interface class AuthRepository {
  // ── Authentication ─────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  ///
  /// Returns the authenticated [UserEntity] on success.
  /// Throws [AppException] on failure.
  Future<UserEntity> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Registers a new account.
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  });

  /// Signs out the current user and clears all session data.
  Future<void> logout();

  /// Signs in using Google OAuth.
  ///
  /// [idToken] is obtained from the Google Sign-In SDK.
  /// TODO: Implement when Firebase is configured.
  Future<UserEntity> signInWithGoogle({required String idToken});

  // ── Session ────────────────────────────────────────────────────────────────

  /// Returns the current user if a valid session exists, or null.
  Future<UserEntity?> getCurrentUser();

  /// Returns the stored [AuthTokenEntity] or null if not logged in.
  Future<AuthTokenEntity?> getStoredToken();

  /// Checks whether a valid, non-expired session exists.
  Future<bool> isAuthenticated();

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Returns the new [AuthTokenEntity].
  Future<AuthTokenEntity> refreshToken();

  // ── Password ───────────────────────────────────────────────────────────────

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail({required String email});

  /// Confirms a password reset using the [token] from the email link.
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  });

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Updates the locally cached user entity.
  Future<void> updateCachedUser(UserEntity user);

  /// Clears all cached authentication data.
  Future<void> clearAuthData();
}

