import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_token_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/user_model.dart';

/// [AuthRepository] implementation backed by Firebase Authentication.
///
/// Orchestrates between [FirebaseAuthDatasource] (Firebase/Google auth)
/// and [AuthLocalDatasource] (local cache + secure storage).
///
/// Design:
///   - All auth operations go through Firebase Auth
///   - Tokens are Firebase ID tokens (managed by Firebase SDK)
///   - User data is cached locally for offline access
///   - Token refresh is handled by Firebase SDK automatically
class FirebaseAuthRepositoryImpl implements AuthRepository {
  const FirebaseAuthRepositoryImpl({
    required FirebaseAuthDatasource firebase,
    required AuthLocalDatasource local,
  })  : _firebase = firebase,
        _local = local;

  final FirebaseAuthDatasource _firebase;
  final AuthLocalDatasource _local;

  // ── Login ──────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final result = await _firebase.signInWithEmailPassword(
        email: email,
        password: password,
      );

      await Future.wait([
        _local.saveToken(result.token),
        _local.saveUser(result.user),
      ]);

      if (rememberMe) {
        await _local.saveRememberedEmail(email);
      } else {
        await _local.clearRememberedEmail();
      }

      log.info('FirebaseAuthRepo: login successful — ${result.user.email}');
      return result.user;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final result = await _firebase.createUserWithEmailPassword(
        fullName: fullName,
        email: email,
        password: password,
      );

      await Future.wait([
        _local.saveToken(result.token),
        _local.saveUser(result.user),
      ]);

      log.info('FirebaseAuthRepo: registration successful — ${result.user.email}');
      return result.user;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _firebase.signOut();
    } finally {
      await _local.clearAll();
      log.info('FirebaseAuthRepo: logout completed');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signInWithGoogle({required String idToken}) async {
    try {
      // Firebase datasource handles the full Google flow internally
      final result = await _firebase.signInWithGoogle();
      await Future.wait([
        _local.saveToken(result.token),
        _local.saveUser(result.user),
      ]);
      log.info('FirebaseAuthRepo: Google sign-in successful');
      return result.user;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _local.getCachedUser();
  }

  @override
  Future<AuthTokenEntity?> getStoredToken() async {
    return _local.getStoredToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    // Firebase auth state is authoritative — check current user
    final firebaseUser = _firebase.currentFirebaseUser;
    if (firebaseUser == null) return false;

    // Also verify local cache
    final cached = await _local.getCachedUser();
    return cached != null;
  }

  @override
  Future<AuthTokenEntity> refreshToken() async {
    try {
      final idToken = await _firebase.getIdToken(forceRefresh: true);
      if (idToken == null) throw const UnauthorizedException();

      // Build a new token entity and persist it
      final tokenModel = _local.buildTokenFromIdToken(
        idToken: idToken,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await _local.saveToken(tokenModel);
      return tokenModel;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Password ───────────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebase.sendPasswordResetEmail(email);
    log.info('FirebaseAuthRepo: password reset email sent to $email');
  }

  @override
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    // Firebase handles password reset via email link, not token-based.
    // The user clicks the email link → FirebaseAuth.confirmPasswordReset()
    // This is handled on the reset-password deep link screen.
    throw UnimplementedError(
      'Use FirebaseAuth.confirmPasswordReset(code, newPassword) '
      'in the password reset screen after receiving the deep link.',
    );
  }

  // ── Profile Cache ──────────────────────────────────────────────────────────

  @override
  Future<void> updateCachedUser(UserEntity user) async {
    await _local.saveUser(UserModel.fromEntity(user));
  }

  @override
  Future<void> clearAuthData() async {
    await _local.clearAll();
  }
}

