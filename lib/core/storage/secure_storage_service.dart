import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_logger.dart';

/// Wrapper around [FlutterSecureStorage] for sensitive data storage.
///
/// All secrets (tokens, user credentials, biometric flags) must be
/// stored via this service. Never use [SharedPreferences] for secrets.
class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService _instance = SecureStorageService._();

  /// The singleton [SecureStorageService] instance.
  static SecureStorageService get instance => _instance;

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iOsOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iOsOptions,
  );

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Reads a value for [key]. Returns null if not found.
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      log.error('SecureStorage read failed for key "$key"', error: e);
      return null;
    }
  }

  /// Reads all stored key-value pairs.
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      log.error('SecureStorage readAll failed', error: e);
      return {};
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Writes [value] for [key].
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      log.error('SecureStorage write failed for key "$key"', error: e);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Deletes the value for [key].
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      log.error('SecureStorage delete failed for key "$key"', error: e);
    }
  }

  /// Deletes all stored key-value pairs (full logout / wipe).
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      log.info('SecureStorage cleared.');
    } catch (e) {
      log.error('SecureStorage deleteAll failed', error: e);
    }
  }

  // ── Contains ──────────────────────────────────────────────────────────────

  /// Returns true if [key] exists in secure storage.
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      log.error('SecureStorage containsKey failed for "$key"', error: e);
      return false;
    }
  }
}

