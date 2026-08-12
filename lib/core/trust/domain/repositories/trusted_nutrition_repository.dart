import '../entities/verified_nutrition.dart';

/// Abstract repository for trusted nutrition data lookups.
///
/// ── Implementation strategy ───────────────────────────────────────────────────
/// This interface is the ONLY point of contact between the domain layer and any
/// external or cached nutrition data. The domain layer never knows whether data
/// comes from USDA, Open Food Facts, a local Hive cache, or a mock.
///
/// Current implementation: [TrustedNutritionRepositoryImpl]
///   → backed by [LocalNutritionDataSource] (Hive cache of app seed data)
///
/// Future implementation: RemoteNutritionRepositoryImpl
///   → backed by USDA FoodData Central / Open Food Facts API
///   → zero domain layer changes required
///
/// ── Null semantics ────────────────────────────────────────────────────────────
/// All lookup methods return null when data is genuinely unavailable.
/// Callers MUST handle null — they must NOT silently substitute zero values.
abstract interface class TrustedNutritionRepository {
  /// Looks up a food by its ID in the trusted database.
  ///
  /// Returns null if the food ID is not in the database.
  Future<VerifiedNutrition?> getById(String foodId);

  /// Searches for foods matching [query] in the trusted database.
  ///
  /// Returns an empty list if no matches are found — never throws on empty.
  /// The list is ordered by relevance (exact matches first).
  Future<List<VerifiedNutrition>> search(String query, {int limit = 20});

  /// Looks up a food by its barcode (EAN/UPC).
  ///
  /// Returns null if the barcode is not in the database.
  /// This will be used by the Food Vision feature.
  Future<VerifiedNutrition?> getByBarcode(String barcode);

  /// Returns all foods in the trusted database for a given category.
  Future<List<VerifiedNutrition>> getByCategory(String category, {int limit = 50});

  /// Returns the most recently accessed / cached foods (for offline use).
  Future<List<VerifiedNutrition>> getRecentlyAccessed({int limit = 20});

  /// Caches a [VerifiedNutrition] record locally for offline use.
  ///
  /// Implementations must store the full provenance metadata,
  /// not just the nutrition values.
  Future<void> cache(VerifiedNutrition nutrition);

  /// Clears the local cache (e.g. on app reset).
  Future<void> clearCache();

  /// Returns the number of records available in the local cache.
  Future<int> getCachedCount();
}

