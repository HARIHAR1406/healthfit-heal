import '../entities/medication_entity.dart';

abstract interface class MedicationRepository {
  Future<MedicationSummary> getSummary();
  Future<List<MedicationEntity>> getMedications();
  Future<MedicationEntity> addMedication(MedicationEntity medication);
  Future<MedicationEntity> updateMedication(MedicationEntity medication);
  Future<bool> deleteMedication(String id);
  Future<DoseLogEntry> logDose({
    required String medicationId,
    required DateTime scheduledAt,
    required DoseStatus status,
  });
  Future<List<DoseLogEntry>> getLogs({DateTime? from, DateTime? to});
}

