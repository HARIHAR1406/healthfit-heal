import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use-case: retrieve the currently signed-in user.
///
/// Returns null if no active session exists.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the current [UserEntity] or null.
  Future<UserEntity?> call() => _repository.getCurrentUser();
}

