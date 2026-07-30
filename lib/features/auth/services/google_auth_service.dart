import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/app_logger.dart';

/// Google OAuth sign-in service for HealthFit Heal.
///
/// Uses the `google_sign_in` package to handle the native Google Sign-In
/// flow on Android. The returned [GoogleSignInResult] contains the
/// Google ID token used to create a Firebase Auth credential.
///
/// ── Required setup ─────────────────────────────────────────────────────────
///   1. Add SHA-1 + SHA-256 fingerprints to Firebase Console → Android app
///   2. Download updated google-services.json → android/app/
///   3. Ensure android/app/build.gradle has google-services plugin applied
///
/// See: https://firebase.flutter.dev/docs/auth/social#google
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService _instance = GoogleAuthService._();

  /// Singleton instance.
  static GoogleAuthService get instance => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Server client ID from google-services.json
    // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );

  // ── Sign In ────────────────────────────────────────────────────────────────

  /// Initiates the Google Sign-In flow and returns a [GoogleSignInResult].
  ///
  /// Returns the Google ID token and access token for Firebase credential creation.
  /// Throws [GoogleAuthException] if the flow fails or is cancelled.
  Future<GoogleSignInResult> signIn() async {
    try {
      // Trigger the Google sign-in dialog
      final account = await _googleSignIn.signIn();

      if (account == null) {
        log.info('GoogleAuthService: user cancelled sign-in');
        throw GoogleAuthException.cancelled();
      }

      log.info('GoogleAuthService: account selected — ${account.email}');

      // Obtain auth tokens
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null) {
        log.error('GoogleAuthService: no ID token returned');
        throw GoogleAuthException.noToken();
      }

      return GoogleSignInResult(
        idToken: idToken,
        accessToken: accessToken,
        email: account.email,
        displayName: account.displayName ?? '',
        photoUrl: account.photoUrl,
      );
    } on GoogleAuthException {
      rethrow;
    } catch (e, st) {
      log.error('GoogleAuthService: sign-in failed', error: e, stackTrace: st);
      throw GoogleAuthException(e.toString());
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Signs out of Google (clears cached account).
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      log.info('GoogleAuthService: signed out');
    } catch (e) {
      log.warning('GoogleAuthService: sign-out error', error: e);
    }
  }

  // ── Silent Sign-In ────────────────────────────────────────────────────────

  /// Attempts a silent sign-in (no UI) to restore a previous session.
  Future<GoogleSignInResult?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null) return null;

      return GoogleSignInResult(
        idToken: idToken,
        accessToken: accessToken,
        email: account.email,
        displayName: account.displayName ?? '',
        photoUrl: account.photoUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the user is currently signed in to Google.
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();
}

// ══════════════════════════════════════════════════════════════════════════════
// VALUE OBJECTS
// ══════════════════════════════════════════════════════════════════════════════

/// Result of a successful Google Sign-In flow.
class GoogleSignInResult {
  const GoogleSignInResult({
    required this.idToken,
    this.accessToken,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  /// Google ID token — used to create a Firebase Auth credential.
  final String idToken;

  /// Google access token (optional — may be null on some platforms).
  final String? accessToken;

  final String email;
  final String displayName;
  final String? photoUrl;
}

/// Errors specific to Google Sign-In.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  factory GoogleAuthException.cancelled() =>
      const GoogleAuthException('Google sign-in was cancelled.');

  factory GoogleAuthException.noToken() =>
      const GoogleAuthException('Failed to obtain Google authentication token.');

  @override
  String toString() => 'GoogleAuthException: $message';
}
