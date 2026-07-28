/// Type of health activity logged.
enum ActivityType {
  workout,
  meal,
  medication,
  healthUpdate,
  sleep,
  water,
  vitals,
}

/// Pure domain entity representing a single item in the recent-activity feed.
class ActivityItemEntity {
  const ActivityItemEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.value,
    this.unit,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;

  /// Optional numeric value, e.g. "45" (minutes), "350" (kcal).
  final String? value;
  final String? unit;

  /// Human-readable relative time label.
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
