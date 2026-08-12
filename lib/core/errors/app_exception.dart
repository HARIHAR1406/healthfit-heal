/// Sealed hierarchy of application exceptions for HealthFit Heal.
///
/// All errors thrown within the app should be of type [AppException]
/// or one of its subclasses. This enables pattern-matched error handling
/// throughout the features without leaking raw [Exception] types.
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  /// Human-readable error message (safe for logging, NOT for display).
  final String message;

  /// Optional machine-readable error code from the server.
  final String? code;

  /// Optional stack trace for debugging.
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

// ── Network Exceptions ────────────────────────────────────────────────────────

/// Thrown when there is no internet connectivity.
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
    super.stackTrace,
  });
}

/// Thrown when the server returns a non-2xx HTTP response.
final class ServerException extends AppException {
  const ServerException({
    required super.message,
    required this.statusCode,
    super.code,
    super.stackTrace,
  });

  /// The HTTP status code (e.g. 400, 401, 404, 500).
  final int statusCode;

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, code: $code, message: $message)';
}

/// Thrown when the request times out.
final class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'The request timed out. Please try again.',
    super.code = 'TIMEOUT',
    super.stackTrace,
  });
}

/// Thrown when the server response cannot be parsed.
final class ParseException extends AppException {
  const ParseException({
    super.message = 'Failed to parse server response.',
    super.code = 'PARSE_ERROR',
    super.stackTrace,
  });
}

// ── Authentication Exceptions ─────────────────────────────────────────────────

/// Thrown when the user is not authenticated (401).
final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Your session has expired. Please log in again.',
    super.code = 'UNAUTHORIZED',
    super.stackTrace,
  });
}

/// Thrown when the user does not have permission to access a resource (403).
final class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'FORBIDDEN',
    super.stackTrace,
  });
}

// ── Resource Exceptions ───────────────────────────────────────────────────────

/// Thrown when a requested resource does not exist (404).
final class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.stackTrace,
  });
}

/// Thrown when there is a conflict (409 — e.g. duplicate email).
final class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.code = 'CONFLICT',
    super.stackTrace,
  });
}

// ── Validation Exceptions ─────────────────────────────────────────────────────

/// Thrown when client-side validation fails before making a network call.
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    this.fieldErrors = const {},
    super.code = 'VALIDATION_ERROR',
    super.stackTrace,
  });

  /// Field-specific validation errors keyed by field name.
  final Map<String, String> fieldErrors;
}

// ── Storage Exceptions ────────────────────────────────────────────────────────

/// Thrown when a local storage operation fails.
final class StorageException extends AppException {
  const StorageException({
    super.message = 'A local storage error occurred.',
    super.code = 'STORAGE_ERROR',
    super.stackTrace,
  });
}

// ── Unknown Exceptions ────────────────────────────────────────────────────────

/// Fallback for any unhandled exception.
final class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNKNOWN',
    super.stackTrace,
  });
}

