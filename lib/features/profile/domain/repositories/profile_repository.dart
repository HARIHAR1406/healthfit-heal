import '../entities/profile_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE REPOSITORY (Abstract)
// ══════════════════════════════════════════════════════════════════════════════

abstract interface class ProfileRepository {
  /// Fetch the current user's full profile.
  Future<UserProfileEntity> getProfile();

  /// Persist profile changes.
  Future<UserProfileEntity> updateProfile(UserProfileEntity updated);

  /// Update only the app settings section.
  Future<AppSettings> updateSettings(AppSettings settings);

  /// Update only health goals.
  Future<HealthGoals> updateGoals(HealthGoals goals);

  /// Delete the user account — returns true on success.
  Future<bool> deleteAccount();
}

