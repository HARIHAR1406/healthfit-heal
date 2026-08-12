import 'app_exception.dart';

/// Represents the failure result of a use-case or repository operation.
///
/// [Failure] maps [AppException] subtypes into a user-facing model.
/// Features should catch [AppException] and convert to [Failure] at
/// the repository/data-source boundary using [Failure.fromException].
sealed class Failure {
  const Failure({
    required this.message,
    this.code,
  });

  /// User-facing message suitable for display in error widgets.
  final String message;

  /// Optional error code for logging or analytics.
  final String? code;

  /// Converts any [AppException] into the appropriate [Failure] subtype.
  factory Failure.fromException(AppException exception) =>
      switch (exception) {
        NetworkException() => const NetworkFailure(),
        TimeoutException() => const TimeoutFailure(),
        UnauthorizedException() => const AuthFailure(),
        ForbiddenException() => const PermissionFailure(),
        NotFoundException() => const NotFoundFailure(),
        ConflictException(message: final msg) =>
          ConflictFailure(message: msg),
        ValidationException(message: final msg, fieldErrors: final fields) =>
          ValidationFailure(message: msg, fieldErrors: fields),
        ServerException(message: final msg, statusCode: final code) =>
          ServerFailure(message: msg, statusCode: code),
        ParseException() => const ServerFailure(
            message: 'Failed to process server response.',
          ),
        StorageException() => const StorageFailure(),
        UnknownException() => const UnknownFailure(),
      };

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

// ── Concrete Failures ─────────────────────────────────────────────────────────

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
  });
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'The request timed out. Please try again.',
    super.code = 'TIMEOUT',
  });
}

final class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Your session has expired. Please log in again.',
    super.code = 'UNAUTHORIZED',
  });
}

final class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'FORBIDDEN',
  });
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
  });
}

final class ConflictFailure extends Failure {
  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
  });
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
    super.code = 'VALIDATION_ERROR',
  });

  final Map<String, String> fieldErrors;
}

final class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'A server error occurred. Please try again later.',
    this.statusCode,
    super.code = 'SERVER_ERROR',
  });

  final int? statusCode;
}

final class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'A local data error occurred. Please restart the app.',
    super.code = 'STORAGE_ERROR',
  });
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNKNOWN',
  });
}

