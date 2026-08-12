import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_profile_repository.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_notifier.dart';
import 'profile_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Swap implementation here when moving to real API/Firestore.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE NOTIFIER PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider));
});

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS NOTIFIER PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

/// Seeded from the loaded profile; updates persist via [ProfileRepository].
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final profileState = ref.watch(profileNotifierProvider);
  final defaultSettings = const AppSettings();
  final initial = profileState is ProfileLoaded
      ? profileState.profile.settings
      : defaultSettings;
  return SettingsNotifier(ref.watch(profileRepositoryProvider), initial);
});

// ══════════════════════════════════════════════════════════════════════════════
// DERIVED PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

/// Current user profile, or null if not yet loaded.
final currentProfileProvider = Provider<UserProfileEntity?>((ref) {
  final state = ref.watch(profileNotifierProvider);
  return switch (state) {
    ProfileLoaded(:final profile) => profile,
    ProfileSaved(:final profile) => profile,
    ProfileSaving(:final profile) => profile,
    _ => null,
  };
});

/// Current app theme preference.
final appThemePreferenceProvider = Provider<AppThemePreference>((ref) {
  return ref.watch(settingsNotifierProvider).themePreference;
});

/// Current unit system.
final unitSystemProvider = Provider<UnitSystem>((ref) {
  return ref.watch(settingsNotifierProvider).unitSystem;
});

/// Notification preferences.
final notifPrefsProvider = Provider<NotificationPrefs>((ref) {
  return ref.watch(settingsNotifierProvider).notificationPrefs;
});

/// True while profile is loading or saving.
final isProfileBusyProvider = Provider<bool>((ref) {
  final state = ref.watch(profileNotifierProvider);
  return state is ProfileLoading || state is ProfileSaving;
});

