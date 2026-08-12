import '../entities/notification_entity.dart';

abstract interface class NotificationRepository {
  /// Fetch all notifications (newest first).
  Future<List<NotificationEntity>> getAll();

  /// Fetch unread count only (cheap poll).
  Future<int> getUnreadCount();

  /// Mark a single notification as read.
  Future<NotificationEntity> markRead(String id);

  /// Mark all notifications as read.
  Future<void> markAllRead();

  /// Delete a single notification.
  Future<bool> delete(String id);

  /// Delete all notifications in [ids].
  Future<void> deleteMany(List<String> ids);

  /// Clear all notifications.
  Future<void> clearAll();

  /// Get / persist notification settings.
  Future<NotificationSettings> getSettings();
  Future<void> saveSettings(NotificationSettings settings);

  /// Insert a new notification (called from [NotificationService]).
  Future<NotificationEntity> add(NotificationEntity notification);
}

