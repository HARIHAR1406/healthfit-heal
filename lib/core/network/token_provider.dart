import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract token provider — decouples [AuthInterceptor] from Firebase.
///
/// Implementations:
///   - [FirebaseTokenProvider] — uses Firebase ID tokens (JWT)
///   - [LocalTokenProvider]   — reads access token from SecureStorage
///   - [NoOpTokenProvider]    — always returns null (public endpoints)
abstract class TokenProvider {
  /// Returns a valid access token, or null if unauthenticated.
  ///
  /// Implementations must handle token refresh internally if needed.
  Future<String?> getAccessToken();

  /// Forces a token refresh and returns the new token.
  Future<String?> refreshAccessToken();

  /// Clears any cached tokens (called on logout).
  Future<void> clearTokens();
}

// ══════════════════════════════════════════════════════════════════════════════
// FIREBASE TOKEN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Token provider backed by Firebase Authentication.
///
/// Firebase ID tokens expire after 1 hour. This provider automatically
/// refreshes them via `getIdToken(forceRefresh: false)` — Firebase SDK
/// handles refresh internally. Use `forceRefresh: true` after a 401.
class FirebaseTokenProvider implements TokenProvider {
  @override
  Future<String?> getAccessToken() async {
    // import firebase_auth at call site to avoid circular imports
    // FirebaseAuth.instance.currentUser?.getIdToken()
    // Implemented via dynamic import pattern — injected by auth module.
    throw UnimplementedError(
      'FirebaseTokenProvider requires injection from auth module. '
      'Use FirebaseAuthTokenProvider from firebase_auth_datasource.dart.',
    );
  }

  @override
  Future<String?> refreshAccessToken() async {
    throw UnimplementedError('See FirebaseAuthTokenProvider.');
  }

  @override
  Future<void> clearTokens() async {
    // Firebase handles token invalidation through signOut()
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOCAL TOKEN PROVIDER (Custom Backend Fallback)
// ══════════════════════════════════════════════════════════════════════════════

/// Token provider backed by [SecureStorageService] for custom backend tokens.
///
/// Used when not using Firebase Auth as the token source.
class LocalTokenProvider implements TokenProvider {
  const LocalTokenProvider({required this.readToken, required this.clearAll});

  /// Function that reads the access token from secure storage.
  final Future<String?> Function() readToken;

  /// Function to clear all stored tokens on logout.
  final Future<void> Function() clearAll;

  @override
  Future<String?> getAccessToken() => readToken();

  @override
  Future<String?> refreshAccessToken() => readToken(); // Handled by interceptor

  @override
  Future<void> clearTokens() => clearAll();
}

// ══════════════════════════════════════════════════════════════════════════════
// NO-OP TOKEN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Token provider that always returns null — for public/unauthenticated Dio instances.
class NoOpTokenProvider implements TokenProvider {
  const NoOpTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> refreshAccessToken() async => null;

  @override
  Future<void> clearTokens() async {}
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

/// The active token provider — overridden per environment in injection_container.dart.
final tokenProviderProvider = Provider<TokenProvider>(
  (ref) => const NoOpTokenProvider(),
  name: 'tokenProviderProvider',
);

