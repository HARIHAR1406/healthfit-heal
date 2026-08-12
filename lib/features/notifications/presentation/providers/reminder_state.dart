import '../../domain/entities/reminder_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ReminderState {
  const ReminderState();
}

final class ReminderInitial extends ReminderState {
  const ReminderInitial();
}

final class ReminderLoading extends ReminderState {
  const ReminderLoading();
}

final class ReminderLoaded extends ReminderState {
  const ReminderLoaded({
    required this.reminders,
    required this.activeCount,
    required this.disabledCount,
  });

  final List<ReminderEntity> reminders;
  final int activeCount;
  final int disabledCount;

  ReminderLoaded copyWith({List<ReminderEntity>? reminders}) {
    final list = reminders ?? this.reminders;
    return ReminderLoaded(
      reminders: list,
      activeCount: list.where((r) => r.isEnabled).length,
      disabledCount: list.where((r) => !r.isEnabled).length,
    );
  }
}

final class ReminderError extends ReminderState {
  const ReminderError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// REMINDER HISTORY STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class ReminderHistoryState {
  const ReminderHistoryState();
}

final class ReminderHistoryInitial extends ReminderHistoryState {
  const ReminderHistoryInitial();
}

final class ReminderHistoryLoading extends ReminderHistoryState {
  const ReminderHistoryLoading();
}

final class ReminderHistoryLoaded extends ReminderHistoryState {
  const ReminderHistoryLoaded({
    required this.entries,
    required this.statistics,
    required this.activeFilter,
  });

  final List<ReminderHistoryEntry> entries;
  final ReminderStatistics statistics;
  final ReminderHistoryStatus? activeFilter;

  ReminderHistoryLoaded copyWith({
    List<ReminderHistoryEntry>? entries,
    ReminderStatistics? statistics,
    ReminderHistoryStatus? Function()? activeFilter,
  }) =>
      ReminderHistoryLoaded(
        entries: entries ?? this.entries,
        statistics: statistics ?? this.statistics,
        activeFilter: activeFilter != null ? activeFilter() : this.activeFilter,
      );
}

final class ReminderHistoryError extends ReminderHistoryState {
  const ReminderHistoryError(this.message);
  final String message;
}

