import '../../../../core/network/token_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_logger.dart';
import 'firebase_auth_datasource.dart';

/// [TokenProvider] implementation backed by Firebase Authentication.
///
/// Firebase ID tokens (JWTs) are used as Bearer tokens for all API requests.
/// The Firebase SDK automatically refreshes tokens before expiry.
///
/// For API 401 responses, [refreshAccessToken] forces a token refresh via
/// `getIdToken(forceRefresh: true)`.
class FirebaseAuthTokenProvider implements TokenProvider {
  FirebaseAuthTokenProvider({
    required FirebaseAuthDatasource firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  final FirebaseAuthDatasource _firebaseAuth;

  @override
  Future<String?> getAccessToken() async {
    try {
      // Firebase SDK handles auto-refresh; forceRefresh=false is sufficient
      return await _firebaseAuth.getIdToken(forceRefresh: false);
    } catch (e) {
      log.warning('FirebaseAuthTokenProvider: failed to get token', error: e);
      return null;
    }
  }

  @override
  Future<String?> refreshAccessToken() async {
    try {
      // Force-refresh bypasses cache to get a guaranteed-fresh token
      final token = await _firebaseAuth.getIdToken(forceRefresh: true);
      log.info('FirebaseAuthTokenProvider: token force-refreshed');
      return token;
    } catch (e) {
      log.error('FirebaseAuthTokenProvider: force-refresh failed', error: e);
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    // Firebase tokens are managed by the SDK — sign out clears them.
    // Clear any locally cached token copies from SecureStorage.
    await SecureStorageService.instance.delete(AppConstants.secureKeyAccessToken);
    await SecureStorageService.instance.delete(AppConstants.secureKeyRefreshToken);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOCAL (CUSTOM BACKEND) TOKEN PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// [TokenProvider] implementation backed by [SecureStorageService].
///
/// Used when the backend issues its own JWT tokens (not Firebase tokens).
/// Token refresh is handled by [AuthInterceptor] via the `/auth/refresh` endpoint.
class SecureStorageTokenProvider implements TokenProvider {
  SecureStorageTokenProvider({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService.instance;

  final SecureStorageService _storage;

  @override
  Future<String?> getAccessToken() =>
      _storage.read(AppConstants.secureKeyAccessToken);

  @override
  Future<String?> refreshAccessToken() =>
      _storage.read(AppConstants.secureKeyAccessToken);

  @override
  Future<void> clearTokens() => _storage.deleteAll();
}
