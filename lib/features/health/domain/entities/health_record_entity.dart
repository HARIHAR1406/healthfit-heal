/// Category/type of a medical record.
enum HealthRecordType {
  labReport,
  prescription,
  imaging,
  consultation,
  vaccination,
  other,
}

extension HealthRecordTypeX on HealthRecordType {
  String get label => switch (this) {
        HealthRecordType.labReport => 'Lab Report',
        HealthRecordType.prescription => 'Prescription',
        HealthRecordType.imaging => 'Imaging',
        HealthRecordType.consultation => 'Consultation',
        HealthRecordType.vaccination => 'Vaccination',
        HealthRecordType.other => 'Other',
      };
}

/// Pure domain entity for a single medical record.
class HealthRecordEntity {
  const HealthRecordEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.doctorName,
    this.hospitalName,
    this.tags = const [],
    this.hasAttachment = false,
    this.notes,
  });

  final String id;
  final String title;
  final HealthRecordType type;
  final DateTime date;
  final String? doctorName;
  final String? hospitalName;
  final List<String> tags;
  final bool hasAttachment;
  final String? notes;
}

/// A timeline event for the health history feed.
class HealthHistoryItem {
  const HealthHistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.note,
  });

  final String id;
  final HealthRecordType type;
  final String title;
  final String value;
  final String unit;
  final DateTime timestamp;
  final String? note;
}

