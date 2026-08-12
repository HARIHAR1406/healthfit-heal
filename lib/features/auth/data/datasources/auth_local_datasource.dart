import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Local data source for authentication data.
///
/// Manages:
/// - Tokens in [SecureStorageService] (encrypted)
/// - Cached user profile in [HiveService]
/// - Session flags (remember me, onboarding status)
class AuthLocalDatasource {
  AuthLocalDatasource({
    SecureStorageService? secureStorage,
    HiveService? hiveService,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        _hive = hiveService ?? HiveService.instance;

  final SecureStorageService _secureStorage;
  final HiveService _hive;

  // ── Token Operations ───────────────────────────────────────────────────────

  /// Persists the [AuthTokenModel] to secure storage.
  Future<void> saveToken(AuthTokenModel token) async {
    await Future.wait([
      _secureStorage.write(
        AppConstants.secureKeyAccessToken,
        token.accessToken,
      ),
      _secureStorage.write(
        AppConstants.secureKeyRefreshToken,
        token.refreshToken,
      ),
      if (token.expiresAt != null)
        _secureStorage.write(
          AppConstants.secureKeyTokenExpiry,
          token.expiresAt!.toIso8601String(),
        ),
    ]);
    log.debug('Auth token saved to secure storage.');
  }

  /// Retrieves the stored [AuthTokenModel] or null if none exists.
  Future<AuthTokenModel?> getStoredToken() async {
    final accessToken = await _secureStorage.read(
      AppConstants.secureKeyAccessToken,
    );
    if (accessToken == null || accessToken.isEmpty) return null;

    final refreshToken = await _secureStorage.read(
      AppConstants.secureKeyRefreshToken,
    );
    final expiryStr = await _secureStorage.read(
      AppConstants.secureKeyTokenExpiry,
    );

    return AuthTokenModel(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      expiresAt: expiryStr != null ? DateTime.tryParse(expiryStr) : null,
    );
  }

  /// Clears all stored tokens.
  Future<void> clearToken() async {
    await Future.wait([
      _secureStorage.delete(AppConstants.secureKeyAccessToken),
      _secureStorage.delete(AppConstants.secureKeyRefreshToken),
      _secureStorage.delete(AppConstants.secureKeyTokenExpiry),
    ]);
    log.debug('Auth tokens cleared.');
  }

  // ── User Cache ─────────────────────────────────────────────────────────────

  /// Caches the [UserModel] to Hive.
  Future<void> saveUser(UserModel user) async {
    try {
      final box = _hive.settingsBox;
      await box.put(AppConstants.hiveUserCacheKey, jsonEncode(user.toJson()));
      await _secureStorage.write(AppConstants.secureKeyUserId, user.id);
      log.debug('User cached: ${user.email}');
    } catch (e) {
      log.error('Failed to cache user', error: e);
      throw const StorageException(message: 'Failed to cache user profile.');
    }
  }

  /// Retrieves the cached [UserModel] or null.
  Future<UserModel?> getCachedUser() async {
    try {
      final box = _hive.settingsBox;
      final raw = box.get(AppConstants.hiveUserCacheKey) as String?;
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      log.error('Failed to read cached user', error: e);
      return null;
    }
  }

  /// Clears the cached user.
  Future<void> clearUser() async {
    final box = _hive.settingsBox;
    await box.delete(AppConstants.hiveUserCacheKey);
    await _secureStorage.delete(AppConstants.secureKeyUserId);
  }

  // ── Session Flags ──────────────────────────────────────────────────────────

  /// Saves the "remember me" email for auto-fill.
  Future<void> saveRememberedEmail(String email) async {
    final box = _hive.settingsBox;
    await box.put(AppConstants.hiveRememberMeEmailKey, email);
  }

  /// Retrieves the remembered email or null.
  String? getRememberedEmail() {
    final box = _hive.settingsBox;
    return box.get(AppConstants.hiveRememberMeEmailKey) as String?;
  }

  /// Clears the remembered email.
  Future<void> clearRememberedEmail() async {
    final box = _hive.settingsBox;
    await box.delete(AppConstants.hiveRememberMeEmailKey);
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  /// Marks onboarding as completed.
  Future<void> markOnboardingCompleted() async {
    final box = _hive.settingsBox;
    await box.put(AppConstants.hiveOnboardingCompletedKey, true);
    log.info('Onboarding marked as completed.');
  }

  /// Returns true if onboarding has been completed.
  bool isOnboardingCompleted() {
    final box = _hive.settingsBox;
    return (box.get(AppConstants.hiveOnboardingCompletedKey) as bool?) ?? false;
  }

  // ── Firebase Helpers ──────────────────────────────────────────────────────

  /// Builds an [AuthTokenModel] from a Firebase ID token.
  ///
  /// Firebase manages refresh internally — no refresh token is stored.
  AuthTokenModel buildTokenFromIdToken({
    required String idToken,
    required DateTime expiresAt,
  }) {
    return AuthTokenModel(
      accessToken: idToken,
      refreshToken: '', // Firebase SDK handles refresh
      expiresAt: expiresAt,
      tokenType: 'Bearer',
    );
  }

  // ── Full Clear ────────────────────────────────────────────────────────────

  /// Clears all auth-related local data (called on logout).
  Future<void> clearAll() async {
    await Future.wait([
      clearToken(),
      clearUser(),
    ]);
    log.info('All auth local data cleared.');
  }
}

