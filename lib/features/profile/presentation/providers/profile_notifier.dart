import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repo) : super(const ProfileInitial());

  final ProfileRepository _repo;

  Future<void> load() async {
    state = const ProfileLoading();
    try {
      final profile = await _repo.getProfile();
      state = ProfileLoaded(profile);
    } catch (e, st) {
      _log.e('ProfileNotifier.load', error: e, stackTrace: st);
      state = ProfileError(e.toString());
    }
  }

  Future<void> updateProfile(UserProfileEntity updated) async {
    final current = state;
    if (current is! ProfileLoaded && current is! ProfileSaved) return;

    final prev =
        current is ProfileLoaded ? current.profile : (current as ProfileSaved).profile;
    state = ProfileSaving(prev);

    try {
      final saved = await _repo.updateProfile(updated);
      state = ProfileSaved(saved);
      // Flip back to Loaded after brief feedback window
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (state is ProfileSaved) state = ProfileLoaded(saved);
    } catch (e, st) {
      _log.e('ProfileNotifier.updateProfile', error: e, stackTrace: st);
      state = ProfileError(e.toString());
    }
  }

  void reset() => state = const ProfileInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repo, AppSettings initial) : super(initial);

  final ProfileRepository _repo;

  Future<void> updateTheme(AppThemePreference theme) async {
    state = state.copyWith(themePreference: theme);
    await _repo.updateSettings(state);
  }

  Future<void> updateUnits(UnitSystem units) async {
    state = state.copyWith(unitSystem: units);
    await _repo.updateSettings(state);
  }

  Future<void> updateBiometric(bool enabled) async {
    state = state.copyWith(useBiometricAuth: enabled);
    await _repo.updateSettings(state);
  }

  Future<void> updateAnonymousSharing(bool enabled) async {
    state = state.copyWith(shareAnonymousData: enabled);
    await _repo.updateSettings(state);
  }

  Future<void> updateNotifPref(NotificationPrefs prefs) async {
    state = state.copyWith(notificationPrefs: prefs);
    await _repo.updateSettings(state);
  }

  void toggleWorkoutReminders() {
    updateNotifPref(state.notificationPrefs.copyWith(
      workoutReminders: !state.notificationPrefs.workoutReminders,
    ));
  }

  void toggleMealReminders() {
    updateNotifPref(state.notificationPrefs.copyWith(
      mealReminders: !state.notificationPrefs.mealReminders,
    ));
  }

  void toggleWaterReminders() {
    updateNotifPref(state.notificationPrefs.copyWith(
      waterReminders: !state.notificationPrefs.waterReminders,
    ));
  }

  void toggleMedicationReminders() {
    updateNotifPref(state.notificationPrefs.copyWith(
      medicationReminders: !state.notificationPrefs.medicationReminders,
    ));
  }

  void toggleAiInsights() {
    updateNotifPref(state.notificationPrefs.copyWith(
      aiInsights: !state.notificationPrefs.aiInsights,
    ));
  }

  void toggleWeeklyReports() {
    updateNotifPref(state.notificationPrefs.copyWith(
      weeklyReports: !state.notificationPrefs.weeklyReports,
    ));
  }
}
