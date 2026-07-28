import '../../domain/entities/auth_token_entity.dart';

/// Data model for [AuthTokenEntity] — adds JSON serialisation.
class AuthTokenModel extends AuthTokenEntity {
  const AuthTokenModel({
    required super.accessToken,
    required super.refreshToken,
    super.tokenType,
    super.expiresAt,
  });

  /// Constructs from a JSON API response.
  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    DateTime? expiresAt;

    // Support different API conventions for expiry
    if (json['expires_at'] != null) {
      expiresAt = DateTime.tryParse(json['expires_at'] as String);
    } else if (json['expires_in'] != null) {
      // expires_in is seconds from now
      final seconds = json['expires_in'] as int;
      expiresAt = DateTime.now().add(Duration(seconds: seconds));
    }

    return AuthTokenModel(
      accessToken: (json['access_token'] as String?) ??
          (json['accessToken'] as String?) ??
          '',
      refreshToken: (json['refresh_token'] as String?) ??
          (json['refreshToken'] as String?) ??
          '',
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
      expiresAt: expiresAt,
    );
  }

  /// Serialises for local caching.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }

  /// Constructs from an [AuthTokenEntity].
  factory AuthTokenModel.fromEntity(AuthTokenEntity entity) {
    return AuthTokenModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      tokenType: entity.tokenType,
      expiresAt: entity.expiresAt,
    );
  }
}
