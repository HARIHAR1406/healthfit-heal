import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use-case: authenticate a user with email and password.
///
/// Single-responsibility — only handles credential-based login.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the login operation.
  ///
  /// [email] — validated email address.
  /// [password] — validated password string.
  /// [rememberMe] — persist session across app restarts.
  Future<UserEntity> call({
    required String email,
    required String password,
    bool rememberMe = false,
  }) =>
      _repository.login(
        email: email.trim().toLowerCase(),
        password: password,
        rememberMe: rememberMe,
      );
}
