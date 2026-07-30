import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Firebase Auth remote datasource for HealthFit Heal.
///
/// Replaces the mock [AuthRemoteDatasource] with production Firebase Auth.
/// Implements the same return types to maintain compatibility with
/// [AuthRepositoryImpl] — no changes to the repository layer required.
///
/// Token strategy: Firebase Auth issues ID tokens (JWTs) that expire after 1 hour.
/// The Firebase SDK auto-refreshes them in the background. We use ID tokens as
/// Bearer tokens for all API calls via [FirebaseAuthTokenProvider].
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // ── Current User ───────────────────────────────────────────────────────────

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in Firebase user, or null.
  User? get currentFirebaseUser => _auth.currentUser;

  // ── Email / Password ───────────────────────────────────────────────────────

  /// Signs in with email and password.
  Future<({UserModel user, AuthTokenModel token})> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw const UnauthorizedException();

      return _buildResult(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  /// Creates a new account with email and password.
  Future<({UserModel user, AuthTokenModel token})> createUserWithEmailPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw const UnknownException();

      // Set display name
      await user.updateDisplayName(fullName);
      await user.reload();
      final updatedUser = _auth.currentUser!;

      // Send verification email (non-blocking)
      unawaited(updatedUser.sendEmailVerification());

      return _buildResult(updatedUser);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Signs in with Google OAuth.
  Future<({UserModel user, AuthTokenModel token})> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const UnknownException(message: 'Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const UnknownException(
            message: 'Failed to obtain Google ID token.');
      }

      // Exchange Google credential for Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw const UnauthorizedException();

      return _buildResult(user);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Signs out from Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    log.info('FirebaseAuthDatasource: signed out');
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // ── Email Verification ─────────────────────────────────────────────────────

  /// Sends an email verification to the current user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const UnauthorizedException();
    await user.sendEmailVerification();
  }

  /// Returns true if the current user's email is verified.
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  /// Returns the current Firebase ID token.
  /// Pass [forceRefresh: true] after receiving a 401 from the API.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  // ── Update Profile ─────────────────────────────────────────────────────────

  /// Updates the authenticated user's display name.
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Updates the authenticated user's photo URL.
  Future<void> updatePhotoUrl(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
  }

  /// Changes the current user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const UnauthorizedException();

    try {
      // Re-authenticate before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<({UserModel user, AuthTokenModel token})> _buildResult(
    User firebaseUser,
  ) async {
    final idToken = await firebaseUser.getIdToken();
    final idTokenResult = await firebaseUser.getIdTokenResult();

    final userModel = UserModel(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber,
      avatarUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      provider: _resolveProvider(firebaseUser),
    );

    final tokenModel = AuthTokenModel(
      accessToken: idToken ?? '',
      refreshToken: '', // Firebase manages refresh internally
      expiresAt: idTokenResult.expirationTime ??
          DateTime.now().add(const Duration(hours: 1)),
      tokenType: 'Bearer',
    );

    return (user: userModel, token: tokenModel);
  }

  String _resolveProvider(User user) {
    if (user.providerData.isEmpty) return 'firebase';
    return user.providerData.first.providerId;
  }

  AppException _mapFirebaseException(FirebaseAuthException e) {
    log.warning(
        'FirebaseAuthException: code=${e.code} message=${e.message}');
    return switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        const UnauthorizedException(
          message: 'Invalid email or password.',
        ),
      'email-already-in-use' => const ConflictException(
          message: 'An account with this email already exists.',
        ),
      'weak-password' => const ValidationException(
          message: 'Password is too weak. Use at least 8 characters.',
        ),
      'invalid-email' => const ValidationException(
          message: 'The email address is not valid.',
        ),
      'user-disabled' => const ForbiddenException(
          message: 'This account has been disabled.',
        ),
      'too-many-requests' => const ServerException(
          message: 'Too many attempts. Please try again later.',
          statusCode: 429,
          code: 'RATE_LIMITED',
        ),
      'network-request-failed' => const NetworkException(
          message: 'Network error. Please check your connection.',
        ),
      'operation-not-allowed' => const ForbiddenException(
          message: 'This sign-in method is not enabled.',
        ),
      'requires-recent-login' => const UnauthorizedException(
          message: 'Please sign in again to perform this action.',
        ),
      _ => UnknownException(
          message: e.message ?? 'Authentication failed. Please try again.',
        ),
    };
  }
}

/// Convenience function to fire-and-forget async operations.
void unawaited(Future<void> future) {
  future.then((_) {}).catchError((Object e) {
    log.warning('unawaited error', error: e);
  });
}
