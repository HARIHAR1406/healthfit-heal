import '../../domain/entities/user_entity.dart';

/// Data model for User — extends [UserEntity] with JSON serialisation.
///
/// Maps between the API JSON payload and the domain entity.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    super.avatarUrl,
    super.isEmailVerified,
    super.createdAt,
    super.lastLoginAt,
  });

  /// Constructs a [UserModel] from a JSON map (API response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ??
          (json['name'] as String?) ??
          (json['fullName'] as String?) ??
          '',
      email: (json['email'] as String?) ?? '',
      phoneNumber: json['phone_number'] as String? ??
          json['phoneNumber'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      isEmailVerified: (json['email_verified'] as bool?) ??
          (json['emailVerified'] as bool?) ??
          false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
    );
  }

  /// Serialises the model to a JSON map (for local caching).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'email_verified': isEmailVerified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (lastLoginAt != null)
        'last_login_at': lastLoginAt!.toIso8601String(),
    };
  }

  /// Constructs from a [UserEntity] (e.g. for caching).
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      avatarUrl: entity.avatarUrl,
      isEmailVerified: entity.isEmailVerified,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
    );
  }
}
