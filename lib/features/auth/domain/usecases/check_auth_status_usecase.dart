import '../repositories/auth_repository.dart';

/// Use-case: check whether a valid, unexpired session currently exists.
///
/// Used by the splash screen to decide the initial navigation destination.
class CheckAuthStatusUseCase {
  const CheckAuthStatusUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns true if a valid session is found.
  Future<bool> call() => _repository.isAuthenticated();
}

