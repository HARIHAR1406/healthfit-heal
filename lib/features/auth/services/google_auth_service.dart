import '../../../core/utils/app_logger.dart';

/// Google OAuth sign-in service for HealthFit Heal.
///
/// This is an architecture placeholder. Full implementation requires:
///   1. Add `google_sign_in: ^6.x` to pubspec.yaml
///   2. Configure Firebase project and `google-services.json`
///   3. Add SHA-1 certificate fingerprint to Firebase Console
///   4. Uncomment the implementation below
///
/// See: https://firebase.flutter.dev/docs/auth/social#google
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService _instance = GoogleAuthService._();

  /// Singleton instance.
  static GoogleAuthService get instance => _instance;

  // TODO: Uncomment when google_sign_in is added to pubspec.yaml
  // final GoogleSignIn _googleSignIn = GoogleSignIn(
  //   scopes: ['email', 'profile'],
  // );

  /// Initiates the Google Sign-In flow and returns a [GoogleSignInResult].
  ///
  /// Throws [GoogleAuthException] if the sign-in is cancelled or fails.
  Future<GoogleSignInResult> signIn() async {
    // TODO: Implement with google_sign_in package.
    //
    // final account = await _googleSignIn.signIn();
    // if (account == null) throw GoogleAuthException.cancelled();
    //
    // final auth = await account.authentication;
    // final idToken = auth.idToken;
    // if (idToken == null) throw GoogleAuthException.noToken();
    //
    // return GoogleSignInResult(
    //   idToken: idToken,
    //   email: account.email,
    //   displayName: account.displayName ?? '',
    //   photoUrl: account.photoUrl,
    // );

    log.warning('GoogleAuthService.signIn() — NOT YET IMPLEMENTED');
    throw UnimplementedError(
      'Google Sign-In is not yet configured. '
      'Add google_sign_in to pubspec.yaml and configure Firebase.',
    );
  }

  /// Signs out of Google.
  Future<void> signOut() async {
    // TODO: Uncomment when implemented.
    // await _googleSignIn.signOut();
    log.info('GoogleAuthService.signOut() called (no-op until implemented)');
  }

  /// Returns true if the user is currently signed in to Google.
  Future<bool> isSignedIn() async {
    // TODO: return await _googleSignIn.isSignedIn();
    return false;
  }
}

/// Result of a successful Google Sign-In.
class GoogleSignInResult {
  const GoogleSignInResult({
    required this.idToken,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  /// The Google ID token to exchange for app tokens.
  final String idToken;

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

  factory GoogleAuthException.noToken() => const GoogleAuthException(
        'Failed to obtain Google authentication token.',
      );

  @override
  String toString() => 'GoogleAuthException: $message';
}
