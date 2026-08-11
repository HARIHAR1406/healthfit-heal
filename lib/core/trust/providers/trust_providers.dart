import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calculation/nutrition_calculation_engine.dart';
import '../data/datasources/local_nutrition_datasource.dart';
import '../data/repositories/trusted_nutrition_repository_impl.dart';
import '../domain/repositories/trusted_nutrition_repository.dart';
import '../health_rules/health_rule_engine.dart';
import '../recommendation/recommendation_safety_layer.dart';
import '../validation/nutrition_input_validator.dart';

// ── Infrastructure Providers ───────────────────────────────────────────────────

/// The local nutrition data source (in-memory session cache).
final localNutritionDataSourceProvider = Provider<LocalNutritionDataSource>(
  (_) => LocalNutritionDataSource(),
  name: 'localNutritionDataSourceProvider',
);

/// The trusted nutrition repository.
///
/// Swap [TrustedNutritionRepositoryImpl] for a remote-backed implementation
/// here — no domain or presentation changes required.
final trustedNutritionRepositoryProvider =
    Provider<TrustedNutritionRepository>(
  (ref) => TrustedNutritionRepositoryImpl(
    localDataSource: ref.watch(localNutritionDataSourceProvider),
  ),
  name: 'trustedNutritionRepositoryProvider',
);

// ── Core Engine Providers ──────────────────────────────────────────────────────

/// The nutrition input validator.
final nutritionInputValidatorProvider = Provider<NutritionInputValidator>(
  (_) => const NutritionInputValidator(),
  name: 'nutritionInputValidatorProvider',
);

/// The nutrition calculation engine.
final nutritionCalculationEngineProvider =
    Provider<NutritionCalculationEngine>(
  (ref) => NutritionCalculationEngine(
    repository: ref.watch(trustedNutritionRepositoryProvider),
    validator: ref.watch(nutritionInputValidatorProvider),
  ),
  name: 'nutritionCalculationEngineProvider',
);

/// The health rule engine (stateless, shared instance).
final healthRuleEngineProvider = Provider<HealthRuleEngine>(
  (_) => const HealthRuleEngine(),
  name: 'healthRuleEngineProvider',
);

/// The recommendation safety layer.
///
/// This is the primary entry point for features that need to build
/// AI-safe recommendation contexts.
final recommendationSafetyLayerProvider =
    Provider<RecommendationSafetyLayer>(
  (ref) => RecommendationSafetyLayer(
    repository: ref.watch(trustedNutritionRepositoryProvider),
    calculationEngine: ref.watch(nutritionCalculationEngineProvider),
    ruleEngine: ref.watch(healthRuleEngineProvider),
    validator: ref.watch(nutritionInputValidatorProvider),
  ),
  name: 'recommendationSafetyLayerProvider',
);

// ── Cache Status Provider ──────────────────────────────────────────────────────

/// Number of foods currently in the local nutrition cache.
/// Useful for debug/diagnostic screens.
final nutritionCacheCountProvider = FutureProvider<int>(
  (ref) async {
    final repo = ref.watch(trustedNutritionRepositoryProvider);
    return repo.getCachedCount();
  },
  name: 'nutritionCacheCountProvider',
);
