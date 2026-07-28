/// Pure domain entity representing an authenticated user.
///
/// This is the canonical model used across all domain use-cases.
/// No JSON serialization, no platform dependencies — pure Dart.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Unique user identifier.
  final String id;

  /// User's display name.
  final String fullName;

  /// User's email address.
  final String email;

  /// Optional phone number.
  final String? phoneNumber;

  /// Optional profile photo URL.
  final String? avatarUrl;

  /// Whether the email has been verified.
  final bool isEmailVerified;

  /// Account creation timestamp.
  final DateTime? createdAt;

  /// Last login timestamp.
  final DateTime? lastLoginAt;

  /// First name derived from [fullName].
  String get firstName => fullName.split(' ').first;

  /// Initials from [fullName] (up to 2 characters).
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, email: $email, fullName: $fullName)';
}
