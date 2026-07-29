import 'package:flutter/material.dart';

import '../../domain/entities/medication_entity.dart';
import '../../domain/repositories/medication_repository.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MOCK MEDICATION REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

class MockMedicationRepository implements MedicationRepository {
  MockMedicationRepository();

  final List<MedicationEntity> _medications = [
    MedicationEntity(
      id: 'med_001',
      name: 'Vitamin D3',
      dosage: '1000 IU',
      form: MedicationForm.tablet,
      frequency: MedicationFrequency.daily,
      scheduledTimes: [8],
      color: const Color(0xFFFFBF00),
      startDate: DateTime(2024, 1, 1),
      notes: 'Take with breakfast',
      isActive: true,
    ),
    MedicationEntity(
      id: 'med_002',
      name: 'Omega-3 Fish Oil',
      dosage: '1000 mg',
      form: MedicationForm.capsule,
      frequency: MedicationFrequency.daily,
      scheduledTimes: [8, 20],
      color: const Color(0xFF2196F3),
      startDate: DateTime(2024, 2, 1),
      notes: 'Take with food',
      isActive: true,
    ),
    MedicationEntity(
      id: 'med_003',
      name: 'Magnesium Glycinate',
      dosage: '400 mg',
      form: MedicationForm.tablet,
      frequency: MedicationFrequency.daily,
      scheduledTimes: [21],
      color: const Color(0xFF6C63FF),
      startDate: DateTime(2024, 3, 1),
      notes: 'Take before bed for better sleep',
      isActive: true,
    ),
    MedicationEntity(
      id: 'med_004',
      name: 'Ashwagandha',
      dosage: '500 mg',
      form: MedicationForm.capsule,
      frequency: MedicationFrequency.twiceDaily,
      scheduledTimes: [8, 18],
      color: const Color(0xFF00C896),
      startDate: DateTime(2024, 4, 1),
      isActive: true,
    ),
    MedicationEntity(
      id: 'med_005',
      name: 'B-Complex',
      dosage: '1 tablet',
      form: MedicationForm.tablet,
      frequency: MedicationFrequency.daily,
      scheduledTimes: [8],
      color: const Color(0xFFFF6B6B),
      startDate: DateTime(2024, 1, 15),
      isActive: false, // Course completed
    ),
  ];

  final List<DoseLogEntry> _logs = [];

  @override
  Future<MedicationSummary> getSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    final active = _medications.where((m) => m.isActive).toList();

    // Build today's schedule
    final todayDoses = active.fold<int>(0, (sum, m) => sum + m.scheduledTimes.length);
    final taken = _logs
        .where((l) =>
            l.scheduledAt.year == now.year &&
            l.scheduledAt.month == now.month &&
            l.scheduledAt.day == now.day &&
            l.status == DoseStatus.taken)
        .length;
    final missed = _logs
        .where((l) =>
            l.scheduledAt.year == now.year &&
            l.scheduledAt.month == now.month &&
            l.scheduledAt.day == now.day &&
            l.status == DoseStatus.missed)
        .length;

    return MedicationSummary(
      activeMedications: active.length,
      todayDoses: todayDoses,
      takenToday: taken,
      missedToday: missed,
      upcomingToday: (todayDoses - taken - missed).clamp(0, todayDoses),
      adherenceRate: 0.87,
      medications: _medications,
      recentLogs: _logs.take(20).toList(),
    );
  }

  @override
  Future<List<MedicationEntity>> getMedications() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.from(_medications);
  }

  @override
  Future<MedicationEntity> addMedication(MedicationEntity medication) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _medications.add(medication);
    return medication;
  }

  @override
  Future<MedicationEntity> updateMedication(MedicationEntity medication) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final i = _medications.indexWhere((m) => m.id == medication.id);
    if (i != -1) _medications[i] = medication;
    return medication;
  }

  @override
  Future<bool> deleteMedication(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _medications.removeWhere((m) => m.id == id);
    return true;
  }

  @override
  Future<DoseLogEntry> logDose({
    required String medicationId,
    required DateTime scheduledAt,
    required DoseStatus status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final entry = DoseLogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      status: status,
      takenAt: status == DoseStatus.taken ? DateTime.now() : null,
    );
    _logs.insert(0, entry);
    return entry;
  }

  @override
  Future<List<DoseLogEntry>> getLogs({DateTime? from, DateTime? to}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.from(_logs);
  }
}
