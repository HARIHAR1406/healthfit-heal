// ══════════════════════════════════════════════════════════════════════════════
// EXPORT FORMAT
// ══════════════════════════════════════════════════════════════════════════════

/// Supported export file formats.
enum ExportFormat {
  pdf('PDF Report', 'pdf', 'application/pdf'),
  csv('CSV Data', 'csv', 'text/csv'),
  excel('Excel Report', 'xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  const ExportFormat(this.label, this.extension, this.mimeType);
  final String label;
  final String extension;
  final String mimeType;
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT SCOPE
// ══════════════════════════════════════════════════════════════════════════════

/// Which module's data to include in the export.
enum ExportScope {
  health('Health Summary', '❤️'),
  fitness('Fitness Summary', '🏋️'),
  nutrition('Nutrition Summary', '🥗'),
  ai('AI Coach Summary', '🤖'),
  full('Full Report', '📊');

  const ExportScope(this.label, this.emoji);
  final String label;
  final String emoji;
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT REQUEST
// ══════════════════════════════════════════════════════════════════════════════

/// Describes a pending or completed export request.
class ExportRequestEntity {
  const ExportRequestEntity({
    required this.id,
    required this.format,
    required this.scope,
    required this.dateRangeLabel,
    required this.requestedAt,
    this.completedAt,
    this.filePath,
    this.isLoading = false,
    this.error,
  });

  final String id;
  final ExportFormat format;
  final ExportScope scope;
  final String dateRangeLabel;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String? filePath;
  final bool isLoading;
  final String? error;

  bool get isComplete => completedAt != null && filePath != null;
  bool get hasError => error != null;

  ExportRequestEntity copyWith({
    DateTime? completedAt,
    String? filePath,
    bool? isLoading,
    String? error,
  }) =>
      ExportRequestEntity(
        id: id,
        format: format,
        scope: scope,
        dateRangeLabel: dateRangeLabel,
        requestedAt: requestedAt,
        completedAt: completedAt ?? this.completedAt,
        filePath: filePath ?? this.filePath,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

