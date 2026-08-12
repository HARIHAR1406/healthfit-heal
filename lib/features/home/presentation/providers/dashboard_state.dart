import '../../domain/entities/dashboard_entity.dart';

/// Sealed state hierarchy for the Home Dashboard.
sealed class DashboardState {
  const DashboardState();
}

/// Initial state before any load has been triggered.
final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// First-load skeleton is showing.
final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Dashboard fully loaded — [data] is ready to display.
final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({required this.data});
  final DashboardEntity data;
}

/// Pull-to-refresh in progress while stale [data] is still shown.
final class DashboardRefreshing extends DashboardState {
  const DashboardRefreshing({required this.data});
  final DashboardEntity data;
}

/// Failed to load — [message] is user-facing.
final class DashboardError extends DashboardState {
  const DashboardError({required this.message});
  final String message;
}

// ── Extension helpers ─────────────────────────────────────────────────────────

extension DashboardStateX on DashboardState {
  bool get isLoading =>
      this is DashboardLoading || this is DashboardRefreshing;

  bool get hasData =>
      this is DashboardLoaded || this is DashboardRefreshing;

  DashboardEntity? get data => switch (this) {
        DashboardLoaded(:final data) => data,
        DashboardRefreshing(:final data) => data,
        _ => null,
      };

  String? get errorMessage =>
      this is DashboardError ? (this as DashboardError).message : null;
}

