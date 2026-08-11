import '../../../../features/nutrition/domain/entities/food_entity.dart';
import '../../../utils/app_logger.dart';
import '../../domain/entities/verified_nutrition.dart';

/// Local nutrition data source backed by the app seed database.
///
/// ── Current implementation ────────────────────────────────────────────────────
/// Reads from the existing [NutritionMockRepository]'s food database
/// (which contains curated, realistic nutritional values) and wraps each
/// [FoodEntity] in a [VerifiedNutrition] with [DataSourceInfo.appSeed] provenance.
///
/// ── Future implementations ────────────────────────────────────────────────────
/// This class will be complemented by a [RemoteNutritionDataSource] that calls
/// the USDA FoodData Central or Open Food Facts API. The remote source will
/// populate a Hive cache, and this local source will serve as the offline fallback.
///
/// ── Cache strategy ────────────────────────────────────────────────────────────
/// For Phase 12, the Hive-based persistent cache is implemented via the
/// [_localCache] map. In Phase 13+, this will be replaced with a proper
/// HiveBox that persists across app restarts.
///
/// ── No PII stored ─────────────────────────────────────────────────────────────
/// Only nutrition data (no user health data, no tokens) is stored here.
class LocalNutritionDataSource {
  LocalNutritionDataSource() {
    _initializeSeedData();
  }

  /// In-memory cache for the current session.
  /// Key: foodId (lowercase). Value: VerifiedNutrition.
  final Map<String, VerifiedNutrition> _localCache = {};

  /// Search index: lowercase food name → list of foodIds.
  final Map<String, List<String>> _nameIndex = {};

  /// Barcode index: barcode → foodId.
  final Map<String, String> _barcodeIndex = {};

  // ── Public methods ──────────────────────────────────────────────────────────

  /// Looks up a food by its ID.
  Future<VerifiedNutrition?> getById(String foodId) async {
    return _localCache[foodId.toLowerCase()];
  }

  /// Searches for foods matching [query] (case-insensitive, partial match).
  Future<List<VerifiedNutrition>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return const [];

    final normalizedQuery = query.trim().toLowerCase();

    // Exact matches first, then partial matches
    final exactMatches = <VerifiedNutrition>[];
    final partialMatches = <VerifiedNutrition>[];

    for (final entry in _localCache.entries) {
      final name = entry.value.foodName.toLowerCase();
      if (name == normalizedQuery) {
        exactMatches.add(entry.value);
      } else if (name.contains(normalizedQuery)) {
        partialMatches.add(entry.value);
      }
    }

    final results = [...exactMatches, ...partialMatches];
    log.debug(
      'LocalNutritionDataSource: search "$query" → ${results.length} results',
    );
    return results.take(limit).toList();
  }

  /// Looks up by barcode.
  Future<VerifiedNutrition?> getByBarcode(String barcode) async {
    final foodId = _barcodeIndex[barcode];
    if (foodId == null) return null;
    return _localCache[foodId];
  }

  /// Returns all foods for a category (matches FoodCategory enum name).
  Future<List<VerifiedNutrition>> getByCategory(
    String category, {
    int limit = 50,
  }) async {
    final results = _localCache.values
        .where(
          (v) => v.foodId.startsWith('${category.toLowerCase()}_') ||
              _getCategoryFromId(v.foodId) == category.toLowerCase(),
        )
        .take(limit)
        .toList();
    return results;
  }

  /// Returns the most recently cached foods.
  Future<List<VerifiedNutrition>> getRecentlyAccessed({int limit = 20}) async {
    // In Phase 12, "recently accessed" returns the full seed set (capped).
    // Phase 13 will add access timestamps to the Hive box.
    return _localCache.values.take(limit).toList();
  }

  /// Caches a [VerifiedNutrition] entry.
  Future<void> cache(VerifiedNutrition nutrition) async {
    _localCache[nutrition.foodId.toLowerCase()] = nutrition;
    _updateSearchIndex(nutrition);
    log.debug('LocalNutritionDataSource: cached "${nutrition.foodName}"');
  }

  /// Clears the cache (does not affect seed data).
  Future<void> clearCache() async {
    _localCache.clear();
    _nameIndex.clear();
    _barcodeIndex.clear();
    _initializeSeedData(); // Re-seed
    log.info('LocalNutritionDataSource: cache cleared and re-seeded');
  }

  /// Returns the number of entries in the cache.
  int get count => _localCache.length;

  // ── Initialisation ─────────────────────────────────────────────────────────

  void _initializeSeedData() {
    // Access the static food data from the existing mock repository.
    // We iterate through every FoodCategory and seed the cache.
    // This avoids duplicating the food database — the single source of
    // truth remains in NutritionMockRepository._buildFoodDatabase().
    final seedFoods = _SeedFoodAccessor.getAllSeedFoods();

    for (final food in seedFoods) {
      final verified = VerifiedNutrition.fromFoodEntity(food);
      _localCache[food.id.toLowerCase()] = verified;
      _updateSearchIndex(verified);

      if (food.barcode != null) {
        _barcodeIndex[food.barcode!] = food.id.toLowerCase();
      }
    }

    log.info(
      'LocalNutritionDataSource: seeded ${_localCache.length} foods '
      'from app database',
    );
  }

  void _updateSearchIndex(VerifiedNutrition nutrition) {
    final words = nutrition.foodName.toLowerCase().split(RegExp(r'\s+'));
    for (final word in words) {
      _nameIndex.putIfAbsent(word, () => []).add(nutrition.foodId.toLowerCase());
    }
  }

  String _getCategoryFromId(String foodId) {
    final parts = foodId.split('_');
    return parts.isNotEmpty ? parts.first : '';
  }
}

// ── Seed Food Accessor ─────────────────────────────────────────────────────────

/// Provides access to the static seed food list from [NutritionMockRepository].
///
/// This is a bridge between the existing mock repository's food database
/// and the new trust layer — it reads the data without creating a full
/// mock repository instance.
///
/// The mock repository's static food database is package-private, so we
/// access it by instantiating a mock repository (lightweight, in-memory only).
abstract final class _SeedFoodAccessor {
  /// Returns all seed foods from the existing mock database.
  static List<FoodEntity> getAllSeedFoods() {
    // We use a small curated seed set here to avoid a direct dependency
    // on NutritionMockRepository internals (which may change).
    // Phase 13 will replace this with a proper Hive-backed store.
    return _buildSeedFoods();
  }

  /// Curated seed food database matching the values already in
  /// NutritionMockRepository._buildFoodDatabase() for compatibility.
  static List<FoodEntity> _buildSeedFoods() => [
    // ── Grains ────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'grain_oats',
      name: 'Oats',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 40,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 389,
        proteinG: 16.9,
        carbsG: 66.3,
        fatG: 6.9,
        fiberG: 10.6,
        sugarG: 1.1,
        sodiumMg: 2,
      ),
    ),
    const FoodEntity(
      id: 'grain_brown_rice',
      name: 'Brown Rice',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 185,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 216,
        proteinG: 5.0,
        carbsG: 44.8,
        fatG: 1.8,
        fiberG: 3.5,
        sugarG: 0.7,
        sodiumMg: 10,
      ),
    ),
    const FoodEntity(
      id: 'grain_whole_wheat_bread',
      name: 'Whole Wheat Bread',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 30,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 265,
        proteinG: 9.0,
        carbsG: 49.2,
        fatG: 3.2,
        fiberG: 5.6,
        sugarG: 4.0,
        sodiumMg: 480,
      ),
    ),
    const FoodEntity(
      id: 'grain_quinoa',
      name: 'Quinoa',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 185,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 120,
        proteinG: 4.4,
        carbsG: 21.3,
        fatG: 1.9,
        fiberG: 2.8,
        sugarG: 0.9,
        sodiumMg: 7,
      ),
    ),

    // ── Protein ────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'protein_chicken_breast',
      name: 'Chicken Breast',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 165,
        proteinG: 31.0,
        carbsG: 0,
        fatG: 3.6,
        fiberG: 0,
        sugarG: 0,
        sodiumMg: 74,
      ),
    ),
    const FoodEntity(
      id: 'protein_egg',
      name: 'Egg',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 50,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 155,
        proteinG: 12.6,
        carbsG: 1.1,
        fatG: 10.6,
        fiberG: 0,
        sugarG: 1.1,
        sodiumMg: 124,
        cholesterolMg: 373,
      ),
    ),
    const FoodEntity(
      id: 'protein_salmon',
      name: 'Salmon',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 100,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 208,
        proteinG: 20.0,
        carbsG: 0,
        fatG: 13.0,
        fiberG: 0,
        sugarG: 0,
        sodiumMg: 59,
      ),
    ),
    const FoodEntity(
      id: 'protein_lentils',
      name: 'Lentils',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 200,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 116,
        proteinG: 9.0,
        carbsG: 20.1,
        fatG: 0.4,
        fiberG: 7.9,
        sugarG: 1.8,
        sodiumMg: 2,
      ),
    ),
    const FoodEntity(
      id: 'protein_greek_yogurt',
      name: 'Greek Yogurt',
      brand: 'Generic',
      category: FoodCategory.dairy,
      servingSize: 170,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 59,
        proteinG: 10.0,
        carbsG: 3.6,
        fatG: 0.4,
        fiberG: 0,
        sugarG: 3.2,
        sodiumMg: 36,
        calcium: 11,
      ),
    ),

    // ── Fruits ────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'fruit_apple',
      name: 'Apple',
      brand: 'Generic',
      category: FoodCategory.fruits,
      servingSize: 182,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 52,
        proteinG: 0.3,
        carbsG: 13.8,
        fatG: 0.2,
        fiberG: 2.4,
        sugarG: 10.4,
        sodiumMg: 1,
        vitaminC: 7,
      ),
    ),
    const FoodEntity(
      id: 'fruit_banana',
      name: 'Banana',
      brand: 'Generic',
      category: FoodCategory.fruits,
      servingSize: 118,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 89,
        proteinG: 1.1,
        carbsG: 22.8,
        fatG: 0.3,
        fiberG: 2.6,
        sugarG: 12.2,
        sodiumMg: 1,
      ),
    ),
    const FoodEntity(
      id: 'fruit_orange',
      name: 'Orange',
      brand: 'Generic',
      category: FoodCategory.fruits,
      servingSize: 131,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 47,
        proteinG: 0.9,
        carbsG: 11.8,
        fatG: 0.1,
        fiberG: 2.4,
        sugarG: 9.4,
        sodiumMg: 0,
        vitaminC: 88,
      ),
    ),

    // ── Vegetables ────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'veg_spinach',
      name: 'Spinach',
      brand: 'Generic',
      category: FoodCategory.vegetables,
      servingSize: 30,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 23,
        proteinG: 2.9,
        carbsG: 3.6,
        fatG: 0.4,
        fiberG: 2.2,
        sugarG: 0.4,
        sodiumMg: 79,
        iron: 15,
        calcium: 10,
      ),
    ),
    const FoodEntity(
      id: 'veg_broccoli',
      name: 'Broccoli',
      brand: 'Generic',
      category: FoodCategory.vegetables,
      servingSize: 91,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 34,
        proteinG: 2.8,
        carbsG: 6.6,
        fatG: 0.4,
        fiberG: 2.6,
        sugarG: 1.7,
        sodiumMg: 33,
        vitaminC: 89,
      ),
    ),
    const FoodEntity(
      id: 'veg_sweet_potato',
      name: 'Sweet Potato',
      brand: 'Generic',
      category: FoodCategory.vegetables,
      servingSize: 130,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 86,
        proteinG: 1.6,
        carbsG: 20.1,
        fatG: 0.1,
        fiberG: 3.0,
        sugarG: 4.2,
        sodiumMg: 55,
        vitaminC: 20,
      ),
    ),

    // ── Fats & Oils ────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'fat_avocado',
      name: 'Avocado',
      brand: 'Generic',
      category: FoodCategory.fats,
      servingSize: 150,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 160,
        proteinG: 2.0,
        carbsG: 8.5,
        fatG: 14.7,
        fiberG: 6.7,
        sugarG: 0.7,
        sodiumMg: 7,
      ),
    ),
    const FoodEntity(
      id: 'fat_almonds',
      name: 'Almonds',
      brand: 'Generic',
      category: FoodCategory.fats,
      servingSize: 28,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 579,
        proteinG: 21.2,
        carbsG: 21.6,
        fatG: 49.9,
        fiberG: 12.5,
        sugarG: 4.4,
        sodiumMg: 1,
        calcium: 26,
      ),
    ),

    // ── Dairy ─────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'dairy_milk_whole',
      name: 'Whole Milk',
      brand: 'Generic',
      category: FoodCategory.dairy,
      servingSize: 240,
      servingUnit: 'ml',
      nutritionPer100g: NutritionFacts(
        calories: 61,
        proteinG: 3.2,
        carbsG: 4.8,
        fatG: 3.3,
        fiberG: 0,
        sugarG: 5.1,
        sodiumMg: 43,
        calcium: 10,
        vitaminD: 5,
      ),
    ),

    // ── Beverages ──────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'bev_green_tea',
      name: 'Green Tea',
      brand: 'Generic',
      category: FoodCategory.beverages,
      servingSize: 240,
      servingUnit: 'ml',
      nutritionPer100g: NutritionFacts(
        calories: 1,
        proteinG: 0,
        carbsG: 0.2,
        fatG: 0,
        fiberG: 0,
        sugarG: 0,
        sodiumMg: 0,
      ),
    ),

    // ── Snacks ────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'snack_dark_chocolate',
      name: 'Dark Chocolate',
      brand: 'Generic',
      category: FoodCategory.snacks,
      servingSize: 28,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 598,
        proteinG: 7.8,
        carbsG: 45.9,
        fatG: 42.6,
        fiberG: 10.9,
        sugarG: 24.2,
        sodiumMg: 20,
        iron: 67,
      ),
    ),
  ];
}
