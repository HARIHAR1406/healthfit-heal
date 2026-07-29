import '../../domain/entities/notification_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class NotificationState {
  const NotificationState();
}

final class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

final class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

final class NotificationLoaded extends NotificationState {
  const NotificationLoaded({
    required this.all,
    required this.filtered,
    required this.activeCategory,
    required this.searchQuery,
    required this.settings,
    required this.unreadCount,
  });

  final List<NotificationEntity> all;
  final List<NotificationEntity> filtered;
  final NotificationCategory? activeCategory;
  final String searchQuery;
  final NotificationSettings settings;
  final int unreadCount;

  NotificationLoaded copyWith({
    List<NotificationEntity>? all,
    List<NotificationEntity>? filtered,
    NotificationCategory? Function()? activeCategory,
    String? searchQuery,
    NotificationSettings? settings,
    int? unreadCount,
  }) =>
      NotificationLoaded(
        all: all ?? this.all,
        filtered: filtered ?? this.filtered,
        activeCategory: activeCategory != null ? activeCategory() : this.activeCategory,
        searchQuery: searchQuery ?? this.searchQuery,
        settings: settings ?? this.settings,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

final class NotificationError extends NotificationState {
  const NotificationError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class SettingsSaveState {
  const SettingsSaveState();
}

final class SettingsSaveIdle extends SettingsSaveState {
  const SettingsSaveIdle();
}

final class SettingsSaving extends SettingsSaveState {
  const SettingsSaving();
}

final class SettingsSaved extends SettingsSaveState {
  const SettingsSaved();
}
