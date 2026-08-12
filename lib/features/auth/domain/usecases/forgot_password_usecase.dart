import '../repositories/auth_repository.dart';

/// Use-case: send a password-reset email to the provided address.
class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  /// Sends a reset link to [email].
  Future<void> call({required String email}) =>
      _repository.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
}

