import '../../domain/entities/profile_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile);
  final UserProfileEntity profile;
}

final class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

final class ProfileSaving extends ProfileState {
  const ProfileSaving(this.profile);
  final UserProfileEntity profile;
}

final class ProfileSaved extends ProfileState {
  const ProfileSaved(this.profile);
  final UserProfileEntity profile;
}

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class SettingsState {
  const SettingsState();
}

final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

final class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.settings);
  final AppSettings settings;
}

final class SettingsSaving extends SettingsState {
  const SettingsSaving(this.settings);
  final AppSettings settings;
}
