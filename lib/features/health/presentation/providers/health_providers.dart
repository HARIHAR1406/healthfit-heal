import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/health_mock_repository.dart';
import '../../domain/entities/bmi_entity.dart';
import '../../domain/entities/blood_pressure_entity.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../../domain/entities/health_dashboard_entity.dart';
import '../../domain/entities/health_record_entity.dart';
import '../../domain/entities/heart_rate_entity.dart';
import '../../domain/entities/spo2_entity.dart';
import '../../domain/repositories/health_repository.dart';
import 'health_notifier.dart';
import 'health_state.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Provides the Health repository implementation.
/// Swap [HealthMockRepository] → [HealthRepositoryImpl] when API is ready.
final healthRepositoryProvider = Provider<HealthRepository>(
  (_) => HealthMockRepository(),
  name: 'healthRepositoryProvider',
);

// ── Primary State ─────────────────────────────────────────────────────────────

/// Master Health state provider.
/// Watch this in all Health pages for loading / error gating.
final healthNotifierProvider =
    StateNotifierProvider<HealthNotifier, HealthState>(
  (ref) => HealthNotifier(
    repository: ref.watch(healthRepositoryProvider),
  ),
  name: 'healthNotifierProvider',
);

// ── Convenience Selectors ─────────────────────────────────────────────────────

/// Full health dashboard entity or null.
final healthDataProvider = Provider<HealthDashboardEntity?>(
  (ref) => ref.watch(healthNotifierProvider).data,
  name: 'healthDataProvider',
);

/// BMI entity.
final bmiProvider = Provider<BmiEntity?>(
  (ref) => ref.watch(healthDataProvider)?.bmi,
  name: 'bmiProvider',
);

/// Heart rate entity.
final heartRateProvider = Provider<HeartRateEntity?>(
  (ref) => ref.watch(healthDataProvider)?.heartRate,
  name: 'heartRateProvider',
);

/// Blood pressure entity.
final bloodPressureProvider = Provider<BloodPressureEntity?>(
  (ref) => ref.watch(healthDataProvider)?.bloodPressure,
  name: 'bloodPressureProvider',
);

/// Blood sugar entity.
final bloodSugarProvider = Provider<BloodSugarEntity?>(
  (ref) => ref.watch(healthDataProvider)?.bloodSugar,
  name: 'bloodSugarProvider',
);

/// SpO₂ entity.
final spo2Provider = Provider<Spo2Entity?>(
  (ref) => ref.watch(healthDataProvider)?.spo2,
  name: 'spo2Provider',
);

/// Recent medical records.
final recentMedicalRecordsProvider = Provider<List<HealthRecordEntity>>(
  (ref) => ref.watch(healthDataProvider)?.recentRecords ?? [],
  name: 'recentMedicalRecordsProvider',
);

/// All health history items (unfiltered).
final healthHistoryProvider = Provider<List<HealthHistoryItem>>(
  (ref) => ref.watch(healthDataProvider)?.historyItems ?? [],
  name: 'healthHistoryProvider',
);

/// Health score (0–100).
final healthScoreProvider = Provider<int>(
  (ref) => ref.watch(healthDataProvider)?.healthScore ?? 0,
  name: 'healthScoreProvider',
);

// ── BMI Calculator ────────────────────────────────────────────────────────────

/// Provides the local BMI calculator state — scoped to BmiPage lifecycle.
final bmiCalculatorProvider =
    StateNotifierProvider.autoDispose<BmiCalculatorNotifier, BmiCalculatorState>(
  (_) => BmiCalculatorNotifier(),
  name: 'bmiCalculatorProvider',
);

// ── Medical Records Search / Filter ──────────────────────────────────────────

/// Current search query for medical records.
final medicalRecordsSearchProvider = StateProvider<String>(
  (_) => '',
  name: 'medicalRecordsSearchProvider',
);

/// Currently selected record type filter (null = All).
final medicalRecordsFilterProvider = StateProvider<HealthRecordType?>(
  (_) => null,
  name: 'medicalRecordsFilterProvider',
);

/// Filtered + searched medical records list.
final filteredMedicalRecordsProvider = Provider<List<HealthRecordEntity>>(
  (ref) {
    final allRecords = ref.watch(healthDataProvider)?.recentRecords ?? [];
    final query = ref.watch(medicalRecordsSearchProvider).toLowerCase().trim();
    final filter = ref.watch(medicalRecordsFilterProvider);

    return allRecords.where((rec) {
      final matchesFilter = filter == null || rec.type == filter;
      final matchesSearch = query.isEmpty ||
          rec.title.toLowerCase().contains(query) ||
          (rec.doctorName?.toLowerCase().contains(query) ?? false) ||
          (rec.hospitalName?.toLowerCase().contains(query) ?? false) ||
          rec.tags.any((t) => t.toLowerCase().contains(query));
      return matchesFilter && matchesSearch;
    }).toList();
  },
  name: 'filteredMedicalRecordsProvider',
);
