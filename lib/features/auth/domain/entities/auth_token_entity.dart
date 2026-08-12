/// Pure domain entity representing an authentication token pair.
///
/// Holds the access + refresh token and their expiry information.
class AuthTokenEntity {
  const AuthTokenEntity({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
  });

  /// Short-lived JWT used to authenticate API requests.
  final String accessToken;

  /// Long-lived token used to obtain a new [accessToken].
  final String refreshToken;

  /// Token type prefix (e.g. "Bearer").
  final String tokenType;

  /// UTC expiry datetime of the [accessToken].
  final DateTime? expiresAt;

  /// Whether the access token has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Returns true when the token expires within [buffer] duration.
  bool isExpiringSoon({Duration buffer = const Duration(minutes: 5)}) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!.subtract(buffer));
  }

  /// The formatted authorization header value.
  String get authorizationHeader => '$tokenType $accessToken';

  AuthTokenEntity copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
  }) {
    return AuthTokenEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokenEntity &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken;

  @override
  int get hashCode => accessToken.hashCode;

  @override
  String toString() =>
      'AuthTokenEntity(type: $tokenType, expired: $isExpired)';
}

