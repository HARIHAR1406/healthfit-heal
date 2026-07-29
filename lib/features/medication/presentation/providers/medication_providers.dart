import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/repositories/mock_medication_repository.dart';
import '../../domain/entities/medication_entity.dart';
import '../../domain/repositories/medication_repository.dart';
import 'medication_state.dart';

final _log = Logger();

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MockMedicationRepository();
});

// ══════════════════════════════════════════════════════════════════════════════
// MEDICATION NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class MedicationNotifier extends StateNotifier<MedicationState> {
  MedicationNotifier(this._repo) : super(const MedicationInitial());

  final MedicationRepository _repo;

  Future<void> load() async {
    state = const MedicationLoading();
    try {
      final summary = await _repo.getSummary();
      state = MedicationLoaded(summary);
    } catch (e, st) {
      _log.e('MedicationNotifier.load', error: e, stackTrace: st);
      state = MedicationError(e.toString());
    }
  }

  Future<void> deleteMedication(String id) async {
    await _repo.deleteMedication(id);
    await load();
  }

  Future<void> toggleActive(MedicationEntity medication) async {
    final updated = medication.copyWith(isActive: !medication.isActive);
    await _repo.updateMedication(updated);
    await load();
  }

  void reset() => state = const MedicationInitial();
}

// ══════════════════════════════════════════════════════════════════════════════
// DOSE LOG NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

class DoseLogNotifier extends StateNotifier<DoseLogState> {
  DoseLogNotifier(this._repo) : super(const DoseLogIdle());

  final MedicationRepository _repo;

  Future<void> logDose({
    required String medicationId,
    required DateTime scheduledAt,
    required DoseStatus status,
  }) async {
    state = DoseLogLogging(medicationId);
    try {
      final entry = await _repo.logDose(
        medicationId: medicationId,
        scheduledAt: scheduledAt,
        status: status,
      );
      state = DoseLogSuccess(entry);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (state is DoseLogSuccess) state = const DoseLogIdle();
    } catch (e, st) {
      _log.e('DoseLogNotifier.logDose', error: e, stackTrace: st);
      state = DoseLogError(e.toString());
    }
  }

  void reset() => state = const DoseLogIdle();
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final medicationNotifierProvider =
    StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  return MedicationNotifier(ref.watch(medicationRepositoryProvider));
});

final doseLogNotifierProvider =
    StateNotifierProvider<DoseLogNotifier, DoseLogState>((ref) {
  return DoseLogNotifier(ref.watch(medicationRepositoryProvider));
});

/// Active medications from loaded state, or empty list.
final activeMedicationsProvider = Provider<List<MedicationEntity>>((ref) {
  final state = ref.watch(medicationNotifierProvider);
  return state is MedicationLoaded
      ? state.summary.medications.where((m) => m.isActive).toList()
      : [];
});

/// Today's adherence stats (taken / total).
final todayAdherenceProvider = Provider<(int, int)>((ref) {
  final state = ref.watch(medicationNotifierProvider);
  if (state is MedicationLoaded) {
    return (state.summary.takenToday, state.summary.todayDoses);
  }
  return (0, 0);
});
