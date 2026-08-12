import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/app_logger.dart';

/// Manages the FCM registration token lifecycle.
///
/// Responsibilities:
///   - Stores the FCM token in [SecureStorageService]
///   - Detects token changes and uploads to the backend
///   - Handles re-upload on login (token may have been issued before auth)
class FcmTokenManager {
  FcmTokenManager._();

  static final FcmTokenManager _instance = FcmTokenManager._();
  static FcmTokenManager get instance => _instance;

  static const String _tokenKey = 'fcm_token';

  // ── Store & Upload ─────────────────────────────────────────────────────────

  /// Stores the FCM token and uploads it to the backend if it changed.
  Future<void> updateToken(String? newToken) async {
    if (newToken == null || newToken.isEmpty) return;

    final stored = await _getStoredToken();

    if (stored == newToken) {
      log.debug('FcmTokenManager: token unchanged — skip upload');
      return;
    }

    await _storeToken(newToken);
    await _uploadToken(newToken);
  }

  /// Uploads the stored FCM token to the backend.
  /// Call this after successful login to ensure the token is associated with the user.
  Future<void> uploadStoredToken() async {
    final token = await _getStoredToken();
    if (token != null) await _uploadToken(token);
  }

  /// Clears the stored token (called on logout).
  Future<void> clearToken() async {
    await SecureStorageService.instance.delete(_tokenKey);
    log.info('FcmTokenManager: token cleared');
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<String?> _getStoredToken() =>
      SecureStorageService.instance.read(_tokenKey);

  Future<void> _storeToken(String token) =>
      SecureStorageService.instance.write(_tokenKey, token);

  Future<void> _uploadToken(String token) async {
    try {
      await DioClient.authenticated.post<void>(
        ApiConstants.updateFcmToken,
        data: {'fcm_token': token},
      );
      log.info('FcmTokenManager: token uploaded to backend');
    } on DioException catch (e) {
      // Non-fatal: token will be re-uploaded on next session
      log.warning(
        'FcmTokenManager: upload failed — will retry on next session',
        error: e,
      );
    }
  }
}

