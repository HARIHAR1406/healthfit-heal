import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION FREQUENCY
// ══════════════════════════════════════════════════════════════════════════════

enum MedicationFrequency {
  daily('Daily', 'Every day'),
  twiceDaily('Twice Daily', '2× per day'),
  thriceDaily('3× Daily', '3× per day'),
  weeklyOnce('Weekly', 'Once a week'),
  asNeeded('As Needed', 'When required');

  const MedicationFrequency(this.label, this.description);
  final String label;
  final String description;
}

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION FORM
// ══════════════════════════════════════════════════════════════════════════════

enum MedicationForm {
  tablet('Tablet', Icons.medication_rounded),
  capsule('Capsule', Icons.medication_liquid_rounded),
  liquid('Liquid', Icons.local_drink_rounded),
  injection('Injection', Icons.vaccines_rounded),
  topical('Topical', Icons.spa_rounded),
  inhaler('Inhaler', Icons.air_rounded),
  patch('Patch', Icons.square_rounded),
  drops('Drops', Icons.water_drop_rounded);

  const MedicationForm(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION ENTITY
// ══════════════════════════════════════════════════════════════════════════════

class MedicationEntity {
  const MedicationEntity({
    required this.id,
    required this.name,
    required this.dosage,
    required this.form,
    required this.frequency,
    required this.scheduledTimes,
    required this.color,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    this.prescribedBy,
  });

  final String id;
  final String name;
  final String dosage;
  final MedicationForm form;
  final MedicationFrequency frequency;

  /// Times of day this medication is scheduled (e.g., [8, 20] = 8 AM and 8 PM).
  final List<int> scheduledTimes;
  final Color color;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final String? prescribedBy;

  MedicationEntity copyWith({
    String? name,
    String? dosage,
    MedicationForm? form,
    MedicationFrequency? frequency,
    List<int>? scheduledTimes,
    Color? color,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    String? prescribedBy,
  }) =>
      MedicationEntity(
        id: id,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        form: form ?? this.form,
        frequency: frequency ?? this.frequency,
        scheduledTimes: scheduledTimes ?? this.scheduledTimes,
        color: color ?? this.color,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        prescribedBy: prescribedBy ?? this.prescribedBy,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// DOSE LOG ENTRY
// ══════════════════════════════════════════════════════════════════════════════

/// Records a single dose event (taken, skipped, or snoozed).
class DoseLogEntry {
  const DoseLogEntry({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
    this.note,
  });

  final String id;
  final String medicationId;
  final DateTime scheduledAt;
  final DoseStatus status;
  final DateTime? takenAt;
  final String? note;
}

// ══════════════════════════════════════════════════════════════════════════════
// DOSE STATUS
// ══════════════════════════════════════════════════════════════════════════════

enum DoseStatus {
  taken('Taken', Icons.check_circle_rounded),
  missed('Missed', Icons.cancel_rounded),
  upcoming('Upcoming', Icons.schedule_rounded),
  skipped('Skipped', Icons.remove_circle_rounded);

  const DoseStatus(this.label, this.icon);
  final String label;
  final IconData icon;

  Color get color => switch (this) {
        DoseStatus.taken => const Color(0xFF00C896),
        DoseStatus.missed => const Color(0xFFEF5350),
        DoseStatus.upcoming => const Color(0xFF2196F3),
        DoseStatus.skipped => const Color(0xFFFF9800),
      };
}

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION SUMMARY
// ══════════════════════════════════════════════════════════════════════════════

/// Aggregated stats for the medication dashboard.
class MedicationSummary {
  const MedicationSummary({
    required this.activeMedications,
    required this.todayDoses,
    required this.takenToday,
    required this.missedToday,
    required this.upcomingToday,
    required this.adherenceRate,
    required this.medications,
    required this.recentLogs,
  });

  final int activeMedications;
  final int todayDoses;
  final int takenToday;
  final int missedToday;
  final int upcomingToday;

  /// 0.0–1.0 30-day adherence rate
  final double adherenceRate;
  final List<MedicationEntity> medications;
  final List<DoseLogEntry> recentLogs;
}
