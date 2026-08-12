import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/datasources/auth_local_datasource.dart';

/// Manages session lifecycle: auto-login checks, token validation,
/// and session expiry handling.
///
/// Called during app startup (splash screen) to determine the initial
/// navigation destination.
class SessionService {
  SessionService({
    AuthLocalDatasource? localDatasource,
  }) : _local = localDatasource ??
            AuthLocalDatasource(
              secureStorage: SecureStorageService.instance,
              hiveService: HiveService.instance,
            );

  final AuthLocalDatasource _local;

  // ── Session Check ──────────────────────────────────────────────────────────

  /// Result of a session check.
  SessionStatus get currentStatus => _status;
  SessionStatus _status = SessionStatus.unknown;

  /// Checks whether a valid session exists.
  ///
  /// Returns the [SessionStatus] that determines where to navigate.
  Future<SessionStatus> checkSession() async {
    log.info('Checking session status…');

    // First launch — onboarding not completed
    if (!_local.isOnboardingCompleted()) {
      _status = SessionStatus.firstLaunch;
      log.info('Session: first launch (onboarding required)');
      return _status;
    }

    // Has stored token?
    final token = await _local.getStoredToken();
    if (token == null || token.accessToken.isEmpty) {
      _status = SessionStatus.unauthenticated;
      log.info('Session: no token found → unauthenticated');
      return _status;
    }

    // Token valid?
    if (!token.isExpired) {
      _status = SessionStatus.authenticated;
      log.info('Session: valid token → authenticated');
      return _status;
    }

    // Token expired — can we refresh?
    if (token.refreshToken.isNotEmpty) {
      _status = SessionStatus.tokenExpired;
      log.info('Session: access token expired, refresh available');
      return _status;
    }

    // No usable session
    _status = SessionStatus.unauthenticated;
    log.info('Session: token expired and no refresh token → unauthenticated');
    return _status;
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  /// Marks onboarding as completed and updates [currentStatus].
  Future<void> completeOnboarding() async {
    await _local.markOnboardingCompleted();
    _status = SessionStatus.unauthenticated;
    log.info('Onboarding completed.');
  }

  bool get isOnboardingCompleted => _local.isOnboardingCompleted();

  // ── Remember Me ────────────────────────────────────────────────────────────

  String? get rememberedEmail => _local.getRememberedEmail();
}

/// The result of a session validation check.
enum SessionStatus {
  /// Initial unknown state before the check runs.
  unknown,

  /// No previous session and onboarding has not been shown.
  firstLaunch,

  /// A valid session exists.
  authenticated,

  /// No valid session — user must log in.
  unauthenticated,

  /// Access token expired; a refresh attempt should be made.
  tokenExpired,
}

