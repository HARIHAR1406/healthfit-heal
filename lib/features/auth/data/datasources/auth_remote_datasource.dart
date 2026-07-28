import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/auth_request_models.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Remote data source — all HTTP calls to the auth API.
///
/// Maps network responses to typed models.
/// Throws [AppException] subclasses on failure.
class AuthRemoteDatasource {
  AuthRemoteDatasource({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Authenticates with email + password.
  Future<({UserModel user, AuthTokenModel token})> login(
    LoginRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: request.toJson(),
      );
      return _parseAuthResponse(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  /// Registers a new account.
  Future<({UserModel user, AuthTokenModel token})> register(
    RegisterRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: request.toJson(),
      );
      return _parseAuthResponse(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Signs out on the server (invalidates tokens).
  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.logout);
    } on DioException catch (e) {
      // Log but don't throw — local session must clear regardless
      log.warning('Server logout failed (local session will still clear)', error: e);
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  /// Exchanges a Google [idToken] for app tokens.
  ///
  /// TODO: Implement when Firebase / Google Sign-In is configured.
  Future<({UserModel user, AuthTokenModel token})> signInWithGoogle(
    GoogleSignInRequestModel request,
  ) async {
    try {
      // TODO: Replace with actual Google sign-in endpoint
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: request.toJson(),
      );
      return _parseAuthResponse(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Refresh Token ──────────────────────────────────────────────────────────

  /// Exchanges a refresh token for a new access token.
  Future<AuthTokenModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return AuthTokenModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(
    ForgotPasswordRequestModel request,
  ) async {
    try {
      await _dio.post<void>(
        ApiConstants.forgotPassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  /// Fetches the current user's profile from the server.
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.profile,
      );
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  ({UserModel user, AuthTokenModel token}) _parseAuthResponse(
    Map<String, dynamic> data,
  ) {
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    final tokenData = data['token'] as Map<String, dynamic>? ??
        data['tokens'] as Map<String, dynamic>? ??
        data;

    return (
      user: UserModel.fromJson(userData),
      token: AuthTokenModel.fromJson(tokenData),
    );
  }
}
