import '../repositories/auth_repository.dart';

/// Use-case: sign out the current user and clear all session data.
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the logout operation.
  Future<void> call() => _repository.logout();
}
