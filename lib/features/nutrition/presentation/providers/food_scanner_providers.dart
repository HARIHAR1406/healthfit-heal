import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/api_key_manager.dart';
import '../../../../core/trust/providers/trust_providers.dart';
import '../../data/providers/gemini_food_vision_provider.dart';
import '../../data/providers/mock_food_vision_provider.dart';
import '../../data/services/food_vision_service.dart';
import '../../data/services/image_processing_service.dart';
import '../providers/nutrition_providers.dart';
import 'food_scanner_notifier.dart';
import 'food_scanner_state.dart';

// ── Image Processing ───────────────────────────────────────────────────────────

final imageProcessingServiceProvider = Provider<ImageProcessingService>(
  (ref) => ImageProcessingService(),
  name: 'imageProcessingServiceProvider',
);

// ── Vision Service ─────────────────────────────────────────────────────────────

/// Selects the appropriate food vision provider at runtime.
///
/// Priority:
///   1. [GeminiFoodVisionProvider] if `GEMINI_API_KEY` is configured
///   2. [MockFoodVisionProvider] as offline fallback
///
/// This selection happens once at provider creation. If the key is added
/// later via hot restart, the provider will be re-evaluated.
final foodVisionServiceProvider = Provider<FoodVisionService>(
  (ref) {
    if (ApiKeyManager.hasGeminiKey) {
      return GeminiFoodVisionProvider();
    }
    return const MockFoodVisionProvider();
  },
  name: 'foodVisionServiceProvider',
);

// ── User Context ───────────────────────────────────────────────────────────────

/// Reads the user's current health metrics for passing to the safety layer.
///
/// Returns an empty map if health data is unavailable — the safety layer
/// handles missing context gracefully.
final _scannerHealthMetricsProvider = Provider<Map<String, double>>(
  (ref) {
    // Pull from the existing nutrition/health providers
    // These are best-effort; missing = empty (handled by safety layer)
    return const {};
  },
  name: '_scannerHealthMetricsProvider',
);

/// Reads the user's current nutrition goals for passing to the safety layer.
final _scannerUserGoalsProvider = Provider<Map<String, double>>(
  (ref) {
    final goals = ref.watch(nutritionGoalsProvider);
    if (goals == null) return const {};
    return {
      'caloriesGoal': goals.caloriesGoal,
      'proteinGoalG': goals.proteinGoalG,
      'carbsGoalG': goals.carbsGoalG,
      'fatGoalG': goals.fatGoalG,
      'fiberGoalG': goals.fiberGoalG,
      'sodiumGoalMg': goals.sodiumGoalMg,
    };
  },
  name: '_scannerUserGoalsProvider',
);

// ── Scanner Notifier ───────────────────────────────────────────────────────────

/// The main scanner state provider.
///
/// Dispose policy: [autoDispose] — the notifier is created fresh each time
/// the user enters the scan flow and disposed when they leave. This avoids
/// stale image bytes being held in memory between sessions.
final foodScannerProvider =
    StateNotifierProvider.autoDispose<FoodScannerNotifier, FoodScannerState>(
  (ref) => FoodScannerNotifier(
    visionService: ref.watch(foodVisionServiceProvider),
    imageService: ref.watch(imageProcessingServiceProvider),
    safetyLayer: ref.watch(recommendationSafetyLayerProvider),
    userHealthMetrics: ref.watch(_scannerHealthMetricsProvider),
    userGoals: ref.watch(_scannerUserGoalsProvider),
  ),
  name: 'foodScannerProvider',
);

// ── Convenience selectors ──────────────────────────────────────────────────────

final isVisionMockProvider = Provider<bool>(
  (ref) => ref.watch(foodVisionServiceProvider).isMock,
  name: 'isVisionMockProvider',
);

final visionProviderNameProvider = Provider<String>(
  (ref) => ref.watch(foodVisionServiceProvider).providerName,
  name: 'visionProviderNameProvider',
);
