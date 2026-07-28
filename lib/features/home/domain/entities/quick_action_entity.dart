/// Categories for the quick-action shortcut grid.
enum QuickActionType {
  health,
  fitness,
  nutrition,
  aiAssistant,
  reports,
  medication,
}

/// Pure domain entity for a single quick-action shortcut.
class QuickActionEntity {
  const QuickActionEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String id;
  final QuickActionType type;
  final String title;
  final String subtitle;

  /// GoRouter path this action navigates to.
  final String route;
}
