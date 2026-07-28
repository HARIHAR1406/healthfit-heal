import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/auth_token_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_request_models.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Concrete implementation of [AuthRepository].
///
/// Orchestrates between [AuthRemoteDatasource] (network) and
/// [AuthLocalDatasource] (local cache + secure storage).
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required AuthLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  // ── Login ──────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final result = await _remote.login(
        LoginRequestModel(email: email, password: password),
      );

      // Persist token and cache user
      await Future.wait([
        _local.saveToken(result.token),
        _local.saveUser(result.user),
      ]);

      // Handle "remember me"
      if (rememberMe) {
        await _local.saveRememberedEmail(email);
      } else {
        await _local.clearRememberedEmail();
      }

      log.info('Login successful: ${result.user.email}');
      return result.user;
    } on AppException {
      rethrow;
    } catch (e, st) {
      log.error('Login failed unexpectedly', error: e, stackTrace: st);
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
      final result = await _remote.register(
        RegisterRequestModel(
          fullName: fullName,
          email: email,
          password: password,
          phoneNumber: phoneNumber,
        ),
      );

      await Future.wait([
        _local.saveToken(result.token),
        _local.saveUser(result.user),
      ]);

      log.info('Registration successful: ${result.user.email}');
      return result.user;
    } on AppException {
      rethrow;
    } catch (e, st) {
      log.error('Registration failed unexpectedly', error: e, stackTrace: st);
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      // Fire-and-forget server logout; always clear local data
      await _remote.logout();
    } finally {
      await _local.clearAll();
      log.info('Logout completed.');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signInWithGoogle({required String idToken}) async {
    try {
      final result = await _remote.signInWithGoogle(
        GoogleSignInRequestModel(idToken: idToken),
      );
      await Future.wait([
        _local.saveToken(result.token),
        _local.saveUser(result.user),
      ]);
      log.info('Google sign-in successful: ${result.user.email}');
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
    final token = await _local.getStoredToken();
    if (token == null) return false;
    if (token.isExpired) {
      // Try silent refresh
      try {
        await refreshToken();
        return true;
      } catch (_) {
        await _local.clearAll();
        return false;
      }
    }
    return true;
  }

  @override
  Future<AuthTokenEntity> refreshToken() async {
    try {
      final stored = await _local.getStoredToken();
      if (stored == null || stored.refreshToken.isEmpty) {
        throw const UnauthorizedException();
      }
      final newToken = await _remote.refreshToken(stored.refreshToken);
      await _local.saveToken(newToken);
      log.info('Token refreshed successfully.');
      return newToken;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  // ── Password ───────────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _remote.sendPasswordResetEmail(
        ForgotPasswordRequestModel(email: email),
      );
      log.info('Password reset email sent to $email');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw UnknownException(message: e.toString(), stackTrace: st);
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    // TODO: Implement when backend supports it
    throw UnimplementedError('confirmPasswordReset not yet implemented.');
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
