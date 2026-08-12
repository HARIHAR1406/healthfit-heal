import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use-case: register a new user account.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the registration operation.
  Future<UserEntity> call({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) =>
      _repository.register(
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
        password: password,
        phoneNumber: phoneNumber?.trim(),
      );
}

