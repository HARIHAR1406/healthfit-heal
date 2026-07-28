import '../entities/dashboard_entity.dart';

/// Abstract contract for the Home dashboard data source.
///
/// The mock implementation provides in-memory fixture data.
/// A real implementation will call the REST API via Dio.
abstract interface class DashboardRepository {
  /// Returns the full dashboard aggregate for the current user.
  Future<DashboardEntity> getDashboard();

  /// Refreshes dashboard data (typically pull-to-refresh).
  Future<DashboardEntity> refresh();
}
