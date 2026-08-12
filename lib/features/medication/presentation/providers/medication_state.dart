import '../../domain/entities/medication_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class MedicationState {
  const MedicationState();
}

final class MedicationInitial extends MedicationState {
  const MedicationInitial();
}

final class MedicationLoading extends MedicationState {
  const MedicationLoading();
}

final class MedicationLoaded extends MedicationState {
  const MedicationLoaded(this.summary);
  final MedicationSummary summary;
}

final class MedicationError extends MedicationState {
  const MedicationError(this.message);
  final String message;
}

// ══════════════════════════════════════════════════════════════════════════════
// DOSE LOG STATE
// ══════════════════════════════════════════════════════════════════════════════

sealed class DoseLogState {
  const DoseLogState();
}

final class DoseLogIdle extends DoseLogState {
  const DoseLogIdle();
}

final class DoseLogLogging extends DoseLogState {
  const DoseLogLogging(this.medicationId);
  final String medicationId;
}

final class DoseLogSuccess extends DoseLogState {
  const DoseLogSuccess(this.entry);
  final DoseLogEntry entry;
}

final class DoseLogError extends DoseLogState {
  const DoseLogError(this.message);
  final String message;
}

