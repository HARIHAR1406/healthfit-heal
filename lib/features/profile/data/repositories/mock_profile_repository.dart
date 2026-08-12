import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MOCK PROFILE REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

/// In-memory implementation with realistic seed data.
///
/// Swap with [ApiProfileRepository] or [FirestoreProfileRepository]
/// by replacing [profileRepositoryProvider] in profile_providers.dart.
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository();

  // Mutable in-memory profile
  UserProfileEntity _profile = UserProfileEntity(
    id: 'usr_001',
    firstName: 'Harihar',
    lastName: 'Kumar',
    email: 'harihar@healthfitheal.com',
    phone: '+91 98765 43210',
    bio: 'Fitness enthusiast & health optimizer. Running marathons since 2019.',
    dateOfBirth: DateTime(1995, 6, 15),
    gender: Gender.male,
    heightCm: 175.0,
    weightKg: 72.5,
    activityLevel: ActivityLevel.moderatelyActive,
    joinedAt: DateTime(2024, 1, 10),
    avatarUrl: null,
    goals: const HealthGoals(
      dailyCaloriesTarget: 2200,
      dailyWaterMlTarget: 3000,
      dailyStepsTarget: 10000,
      weeklyWorkoutsTarget: 5,
      targetWeightKg: 70.0,
      sleepHoursTarget: 8.0,
    ),
    settings: const AppSettings(
      themePreference: AppThemePreference.system,
      unitSystem: UnitSystem.metric,
      useBiometricAuth: false,
      shareAnonymousData: true,
    ),
  );

  @override
  Future<UserProfileEntity> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _profile;
  }

  @override
  Future<UserProfileEntity> updateProfile(UserProfileEntity updated) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _profile = updated;
    return _profile;
  }

  @override
  Future<AppSettings> updateSettings(AppSettings settings) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _profile = _profile.copyWith(settings: settings);
    return settings;
  }

  @override
  Future<HealthGoals> updateGoals(HealthGoals goals) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _profile = _profile.copyWith(goals: goals);
    return goals;
  }

  @override
  Future<bool> deleteAccount() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // In production: wipe remote data + local cache.
    return true;
  }
}

