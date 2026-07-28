import '../../domain/entities/food_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/nutrition_tracking_entity.dart';
import '../../domain/repositories/nutrition_repository.dart';

/// In-memory mock repository with realistic nutritional fixture data.
///
/// Swap for [NutritionRepositoryImpl] (Dio-backed) when API is ready.
class NutritionMockRepository implements NutritionRepository {
  // Mutable state
  final List<FoodEntity> _foods = _buildFoodDatabase();
  final Map<String, List<MealEntity>> _meals = {};
  final Map<String, WaterTrackerEntity> _water = {};
  final List<WeightEntry> _weightEntries = _buildWeightHistory();

  static const _goals = NutritionGoals(
    caloriesGoal: 2000,
    proteinGoalG: 120,
    carbsGoalG: 225,
    fatGoalG: 65,
    fiberGoalG: 30,
    waterGoalMl: 2500,
    sodiumGoalMg: 2300,
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<MealEntity> _ensureMeals(DateTime date) {
    final key = _dateKey(date);
    if (!_meals.containsKey(key)) {
      _meals[key] = _buildDefaultMeals(date);
    }
    return _meals[key]!;
  }

  // ── Daily Nutrition ────────────────────────────────────────────────────────

  @override
  Future<DailyNutritionEntity> getDailyNutrition(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final meals = _ensureMeals(date);
    final water = await getWaterTracker(date);
    return DailyNutritionEntity(
      date: date,
      meals: meals,
      goals: _goals,
      waterMl: water.totalMl,
      waterGoalMl: water.goalMl,
    );
  }

  @override
  Future<NutritionGoals> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _goals;
  }

  // ── Meals ──────────────────────────────────────────────────────────────────

  @override
  Future<List<MealEntity>> getMealsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _ensureMeals(date);
  }

  @override
  Future<void> addFoodToMeal({
    required DateTime date,
    required MealType mealType,
    required FoodEntity food,
    required double servings,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final meals = _ensureMeals(date);
    final idx = meals.indexWhere((m) => m.type == mealType);
    if (idx == -1) return;
    final entry = MealFoodEntry(
      id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
      food: food,
      servings: servings,
      loggedAt: DateTime.now(),
    );
    final meal = meals[idx];
    meals[idx] = MealEntity(
      id: meal.id,
      type: meal.type,
      date: meal.date,
      entries: [...meal.entries, entry],
    );
    // Mark food as recent
    final fi = _foods.indexWhere((f) => f.id == food.id);
    if (fi != -1) _foods[fi] = _foods[fi].copyWith(isRecent: true);
  }

  @override
  Future<void> removeFoodFromMeal({
    required DateTime date,
    required MealType mealType,
    required String entryId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final meals = _ensureMeals(date);
    final idx = meals.indexWhere((m) => m.type == mealType);
    if (idx == -1) return;
    final meal = meals[idx];
    meals[idx] = MealEntity(
      id: meal.id,
      type: meal.type,
      date: meal.date,
      entries: meal.entries.where((e) => e.id != entryId).toList(),
    );
  }

  // ── Food Database ──────────────────────────────────────────────────────────

  @override
  Future<List<FoodEntity>> searchFoods(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.trim().isEmpty) return List.unmodifiable(_foods);
    final q = query.toLowerCase();
    return _foods
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.brand.toLowerCase().contains(q) ||
            f.category.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<FoodEntity>> getFoodsByCategory(FoodCategory category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (category == FoodCategory.all) return List.unmodifiable(_foods);
    return _foods.where((f) => f.category == category).toList();
  }

  @override
  Future<List<FoodEntity>> getRecentFoods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _foods.where((f) => f.isRecent).take(10).toList();
  }

  @override
  Future<List<FoodEntity>> getFavoriteFoods() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _foods.where((f) => f.isFavorite).toList();
  }

  @override
  Future<FoodEntity?> getFoodById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _foods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FoodEntity> toggleFoodFavorite(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _foods.indexWhere((f) => f.id == id);
    if (idx == -1) throw ArgumentError('Food $id not found');
    _foods[idx] = _foods[idx].copyWith(isFavorite: !_foods[idx].isFavorite);
    return _foods[idx];
  }

  // ── Water ──────────────────────────────────────────────────────────────────

  @override
  Future<WaterTrackerEntity> getWaterTracker(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final key = _dateKey(date);
    if (!_water.containsKey(key)) {
      _water[key] = WaterTrackerEntity(
        date: date,
        entries: _buildDefaultWater(date),
        goalMl: _goals.waterGoalMl,
      );
    }
    return _water[key]!;
  }

  @override
  Future<void> addWaterIntake(DateTime date, int amountMl) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final key = _dateKey(date);
    final existing = _water[key] ??
        WaterTrackerEntity(date: date, entries: [], goalMl: _goals.waterGoalMl);
    final entry = WaterIntakeEntry(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      amountMl: amountMl,
      loggedAt: DateTime.now(),
    );
    _water[key] = WaterTrackerEntity(
      date: existing.date,
      entries: [...existing.entries, entry],
      goalMl: existing.goalMl,
    );
  }

  @override
  Future<void> removeWaterEntry(DateTime date, String entryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final key = _dateKey(date);
    final existing = _water[key];
    if (existing == null) return;
    _water[key] = WaterTrackerEntity(
      date: existing.date,
      entries: existing.entries.where((e) => e.id != entryId).toList(),
      goalMl: existing.goalMl,
    );
  }

  // ── Weight ─────────────────────────────────────────────────────────────────

  @override
  Future<WeightTrackerEntity> getWeightTracker() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return WeightTrackerEntity(
      entries: List.unmodifiable(_weightEntries),
      goalKg: 70.0,
      heightCm: 175.0,
    );
  }

  @override
  Future<void> logWeight(double kg, {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _weightEntries.insert(
      0,
      WeightEntry(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
        weightKg: kg,
        measuredAt: DateTime.now(),
        notes: notes,
      ),
    );
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  @override
  Future<NutritionAnalyticsEntity> getAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const NutritionAnalyticsEntity(
      weeklyCalories: [1820, 2100, 1750, 2240, 1980, 2380, 2050],
      weeklyProtein: [95, 120, 88, 130, 105, 145, 110],
      weeklyCarbs: [210, 240, 195, 260, 225, 285, 230],
      weeklyFat: [58, 72, 55, 78, 62, 88, 68],
      weeklyWaterMl: [1800, 2200, 1600, 2400, 2100, 2600, 2300],
      weeklyScores: [72, 85, 68, 88, 78, 92, 81],
      monthlyCalories: [
        1900, 2050, 1780, 2120, 1950, 2200, 1850, 2300, 2100, 1980,
        2150, 1820, 2250, 1900, 2080, 2350, 1750, 2180, 1920, 2090,
        2280, 1870, 2190, 2050, 1980, 2320, 2010, 1850, 2140, 1960,
      ],
      caloriesGoal: 2000,
    );
  }
}

// ── Fixture data builders ─────────────────────────────────────────────────────

List<MealEntity> _buildDefaultMeals(DateTime date) {
  final now = DateTime.now();
  final isToday = date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;

  final breakfastFood = _buildFoodDatabase();

  return [
    MealEntity(
      id: 'meal_bfast_${date.millisecondsSinceEpoch}',
      type: MealType.breakfast,
      date: date,
      entries: isToday
          ? [
              MealFoodEntry(
                id: 'e_bfast_01',
                food: breakfastFood.firstWhere((f) => f.id == 'f_oatmeal'),
                servings: 1.0,
                loggedAt: date.copyWith(hour: 7, minute: 30),
              ),
              MealFoodEntry(
                id: 'e_bfast_02',
                food: breakfastFood.firstWhere((f) => f.id == 'f_banana'),
                servings: 1.0,
                loggedAt: date.copyWith(hour: 7, minute: 35),
              ),
            ]
          : [],
    ),
    MealEntity(
      id: 'meal_msnack_${date.millisecondsSinceEpoch}',
      type: MealType.morningSnack,
      date: date,
      entries: isToday
          ? [
              MealFoodEntry(
                id: 'e_msnack_01',
                food: breakfastFood.firstWhere((f) => f.id == 'f_almonds'),
                servings: 0.5,
                loggedAt: date.copyWith(hour: 10, minute: 0),
              ),
            ]
          : [],
    ),
    MealEntity(
      id: 'meal_lunch_${date.millisecondsSinceEpoch}',
      type: MealType.lunch,
      date: date,
      entries: isToday
          ? [
              MealFoodEntry(
                id: 'e_lunch_01',
                food: breakfastFood.firstWhere((f) => f.id == 'f_chicken'),
                servings: 1.5,
                loggedAt: date.copyWith(hour: 13, minute: 0),
              ),
              MealFoodEntry(
                id: 'e_lunch_02',
                food: breakfastFood.firstWhere((f) => f.id == 'f_brown_rice'),
                servings: 1.0,
                loggedAt: date.copyWith(hour: 13, minute: 5),
              ),
              MealFoodEntry(
                id: 'e_lunch_03',
                food: breakfastFood.firstWhere((f) => f.id == 'f_broccoli'),
                servings: 1.0,
                loggedAt: date.copyWith(hour: 13, minute: 10),
              ),
            ]
          : [],
    ),
    MealEntity(
      id: 'meal_esnack_${date.millisecondsSinceEpoch}',
      type: MealType.eveningSnack,
      date: date,
      entries: [],
    ),
    MealEntity(
      id: 'meal_dinner_${date.millisecondsSinceEpoch}',
      type: MealType.dinner,
      date: date,
      entries: [],
    ),
  ];
}

List<WaterIntakeEntry> _buildDefaultWater(DateTime date) {
  final now = DateTime.now();
  final isToday = date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
  if (!isToday) return [];
  return [
    WaterIntakeEntry(
        id: 'w_d01',
        amountMl: 300,
        loggedAt: date.copyWith(hour: 7, minute: 0)),
    WaterIntakeEntry(
        id: 'w_d02',
        amountMl: 250,
        loggedAt: date.copyWith(hour: 9, minute: 30)),
    WaterIntakeEntry(
        id: 'w_d03',
        amountMl: 350,
        loggedAt: date.copyWith(hour: 12, minute: 0)),
    WaterIntakeEntry(
        id: 'w_d04',
        amountMl: 200,
        loggedAt: date.copyWith(hour: 15, minute: 0)),
  ];
}

List<WeightEntry> _buildWeightHistory() {
  final now = DateTime.now();
  final weights = [75.4, 75.1, 74.8, 74.5, 74.3, 74.0, 73.8, 73.6, 73.4, 73.2, 73.0, 72.8];
  return weights.asMap().entries.map((e) {
    return WeightEntry(
      id: 'weight_${e.key}',
      weightKg: e.value,
      measuredAt: now.subtract(Duration(days: e.key * 3)),
    );
  }).toList();
}

List<FoodEntity> _buildFoodDatabase() {
  return [
    // ── Grains ────────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_oatmeal',
      name: 'Rolled Oats',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 80,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 389,
        proteinG: 16.9,
        carbsG: 66.3,
        fatG: 6.9,
        fiberG: 10.6,
        sugarG: 1.1,
        sodiumMg: 6,
      ),
      isRecent: true,
      ingredients: 'Whole grain rolled oats.',
    ),
    const FoodEntity(
      id: 'f_brown_rice',
      name: 'Brown Rice (cooked)',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 195,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 112,
        proteinG: 2.6,
        carbsG: 23.5,
        fatG: 0.9,
        fiberG: 1.8,
        sugarG: 0.4,
        sodiumMg: 5,
      ),
      ingredients: 'Whole grain brown rice.',
    ),
    const FoodEntity(
      id: 'f_whole_wheat_bread',
      name: 'Whole Wheat Bread',
      brand: 'Generic',
      category: FoodCategory.grains,
      servingSize: 30,
      servingUnit: 'g (1 slice)',
      nutritionPer100g: NutritionFacts(
        calories: 247,
        proteinG: 13.0,
        carbsG: 41.3,
        fatG: 3.4,
        fiberG: 7.0,
        sugarG: 5.6,
        sodiumMg: 450,
      ),
      isRecent: true,
    ),

    // ── Protein ───────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_chicken',
      name: 'Chicken Breast (cooked)',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 165,
        proteinG: 31.0,
        carbsG: 0.0,
        fatG: 3.6,
        fiberG: 0,
        sugarG: 0,
        sodiumMg: 74,
        cholesterolMg: 85,
      ),
      isRecent: true,
      isFavorite: true,
      ingredients: 'Boneless skinless chicken breast.',
    ),
    const FoodEntity(
      id: 'f_eggs',
      name: 'Whole Eggs',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 50,
      servingUnit: 'g (1 large)',
      nutritionPer100g: NutritionFacts(
        calories: 155,
        proteinG: 12.6,
        carbsG: 1.1,
        fatG: 10.6,
        sugarG: 1.1,
        sodiumMg: 124,
        cholesterolMg: 422,
      ),
      isRecent: true,
      isFavorite: true,
    ),
    const FoodEntity(
      id: 'f_tuna',
      name: 'Tuna (canned in water)',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 85,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 84,
        proteinG: 19.0,
        carbsG: 0.0,
        fatG: 0.5,
        sodiumMg: 320,
        cholesterolMg: 38,
      ),
    ),
    const FoodEntity(
      id: 'f_salmon',
      name: 'Atlantic Salmon (cooked)',
      brand: 'Generic',
      category: FoodCategory.protein,
      servingSize: 150,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 208,
        proteinG: 20.4,
        carbsG: 0.0,
        fatG: 13.4,
        sodiumMg: 59,
        cholesterolMg: 63,
        vitaminD: 71,
      ),
      isFavorite: true,
    ),
    const FoodEntity(
      id: 'f_whey_protein',
      name: 'Whey Protein Powder',
      brand: 'Optimum Nutrition',
      category: FoodCategory.protein,
      servingSize: 31,
      servingUnit: 'g (1 scoop)',
      nutritionPer100g: NutritionFacts(
        calories: 380,
        proteinG: 77.4,
        carbsG: 6.4,
        fatG: 3.2,
        sodiumMg: 160,
      ),
    ),

    // ── Dairy ─────────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_greek_yogurt',
      name: 'Greek Yogurt (plain)',
      brand: 'Generic',
      category: FoodCategory.dairy,
      servingSize: 170,
      servingUnit: 'g',
      nutritionPer100g: NutritionFacts(
        calories: 59,
        proteinG: 10.0,
        carbsG: 3.6,
        fatG: 0.4,
        sugarG: 3.2,
        sodiumMg: 36,
        calcium: 11,
      ),
      isRecent: true,
      isFavorite: true,
    ),
    const FoodEntity(
      id: 'f_milk',
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
        sugarG: 5.1,
        sodiumMg: 44,
        calcium: 11,
        vitaminD: 10,
      ),
    ),

    // ── Fruits ────────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_banana',
      name: 'Banana',
      brand: 'Fresh',
      category: FoodCategory.fruits,
      servingSize: 118,
      servingUnit: 'g (1 medium)',
      nutritionPer100g: NutritionFacts(
        calories: 89,
        proteinG: 1.1,
        carbsG: 22.8,
        fatG: 0.3,
        fiberG: 2.6,
        sugarG: 12.2,
        sodiumMg: 1,
        vitaminC: 15,
      ),
      isRecent: true,
      isFavorite: true,
    ),
    const FoodEntity(
      id: 'f_apple',
      name: 'Apple',
      brand: 'Fresh',
      category: FoodCategory.fruits,
      servingSize: 182,
      servingUnit: 'g (1 medium)',
      nutritionPer100g: NutritionFacts(
        calories: 52,
        proteinG: 0.3,
        carbsG: 13.8,
        fatG: 0.2,
        fiberG: 2.4,
        sugarG: 10.4,
        sodiumMg: 1,
        vitaminC: 8,
      ),
    ),
    const FoodEntity(
      id: 'f_blueberries',
      name: 'Blueberries',
      brand: 'Fresh',
      category: FoodCategory.fruits,
      servingSize: 148,
      servingUnit: 'g (1 cup)',
      nutritionPer100g: NutritionFacts(
        calories: 57,
        proteinG: 0.7,
        carbsG: 14.5,
        fatG: 0.3,
        fiberG: 2.4,
        sugarG: 10.0,
        sodiumMg: 1,
        vitaminC: 16,
      ),
    ),

    // ── Vegetables ────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_broccoli',
      name: 'Broccoli (steamed)',
      brand: 'Fresh',
      category: FoodCategory.vegetables,
      servingSize: 156,
      servingUnit: 'g (1 cup)',
      nutritionPer100g: NutritionFacts(
        calories: 35,
        proteinG: 2.4,
        carbsG: 7.2,
        fatG: 0.4,
        fiberG: 2.6,
        sugarG: 1.7,
        sodiumMg: 41,
        vitaminC: 148,
        calcium: 4,
        iron: 4,
      ),
      isRecent: true,
    ),
    const FoodEntity(
      id: 'f_spinach',
      name: 'Baby Spinach',
      brand: 'Fresh',
      category: FoodCategory.vegetables,
      servingSize: 30,
      servingUnit: 'g (1 cup)',
      nutritionPer100g: NutritionFacts(
        calories: 23,
        proteinG: 2.9,
        carbsG: 3.6,
        fatG: 0.4,
        fiberG: 2.2,
        sugarG: 0.4,
        sodiumMg: 79,
        vitaminC: 47,
        iron: 15,
      ),
    ),
    const FoodEntity(
      id: 'f_sweet_potato',
      name: 'Sweet Potato (baked)',
      brand: 'Fresh',
      category: FoodCategory.vegetables,
      servingSize: 150,
      servingUnit: 'g (1 medium)',
      nutritionPer100g: NutritionFacts(
        calories: 103,
        proteinG: 2.3,
        carbsG: 23.6,
        fatG: 0.1,
        fiberG: 3.8,
        sugarG: 7.4,
        sodiumMg: 41,
        vitaminC: 33,
        calcium: 3,
      ),
    ),

    // ── Fats & Oils ───────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_avocado',
      name: 'Avocado',
      brand: 'Fresh',
      category: FoodCategory.fats,
      servingSize: 68,
      servingUnit: 'g (½ medium)',
      nutritionPer100g: NutritionFacts(
        calories: 160,
        proteinG: 2.0,
        carbsG: 8.5,
        fatG: 14.7,
        fiberG: 6.7,
        sugarG: 0.7,
        sodiumMg: 7,
      ),
      isFavorite: true,
    ),
    const FoodEntity(
      id: 'f_almonds',
      name: 'Almonds',
      brand: 'Generic',
      category: FoodCategory.fats,
      servingSize: 28,
      servingUnit: 'g (1 oz, ~23 nuts)',
      nutritionPer100g: NutritionFacts(
        calories: 579,
        proteinG: 21.2,
        carbsG: 21.6,
        fatG: 49.9,
        fiberG: 12.5,
        sugarG: 4.4,
        sodiumMg: 1,
        calcium: 26,
        iron: 20,
      ),
      isRecent: true,
    ),
    const FoodEntity(
      id: 'f_olive_oil',
      name: 'Olive Oil',
      brand: 'Generic',
      category: FoodCategory.fats,
      servingSize: 14,
      servingUnit: 'ml (1 tbsp)',
      nutritionPer100g: NutritionFacts(
        calories: 884,
        proteinG: 0.0,
        carbsG: 0.0,
        fatG: 100.0,
        sodiumMg: 2,
      ),
    ),

    // ── Beverages ─────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_orange_juice',
      name: 'Orange Juice (fresh)',
      brand: 'Generic',
      category: FoodCategory.beverages,
      servingSize: 240,
      servingUnit: 'ml',
      nutritionPer100g: NutritionFacts(
        calories: 45,
        proteinG: 0.7,
        carbsG: 10.4,
        fatG: 0.2,
        fiberG: 0.2,
        sugarG: 8.4,
        sodiumMg: 1,
        vitaminC: 50,
      ),
    ),
    const FoodEntity(
      id: 'f_coffee',
      name: 'Black Coffee',
      brand: 'Generic',
      category: FoodCategory.beverages,
      servingSize: 240,
      servingUnit: 'ml',
      nutritionPer100g: NutritionFacts(
        calories: 2,
        proteinG: 0.3,
        carbsG: 0.0,
        fatG: 0.0,
        sodiumMg: 5,
      ),
    ),

    // ── Snacks ────────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_protein_bar',
      name: 'Protein Bar',
      brand: 'Quest',
      category: FoodCategory.snacks,
      servingSize: 60,
      servingUnit: 'g (1 bar)',
      nutritionPer100g: NutritionFacts(
        calories: 390,
        proteinG: 33.3,
        carbsG: 40.0,
        fatG: 11.7,
        fiberG: 13.3,
        sugarG: 3.3,
        sodiumMg: 333,
      ),
    ),
    const FoodEntity(
      id: 'f_hummus',
      name: 'Hummus',
      brand: 'Generic',
      category: FoodCategory.snacks,
      servingSize: 60,
      servingUnit: 'g (4 tbsp)',
      nutritionPer100g: NutritionFacts(
        calories: 177,
        proteinG: 7.9,
        carbsG: 20.1,
        fatG: 8.6,
        fiberG: 6.0,
        sugarG: 3.0,
        sodiumMg: 430,
      ),
    ),

    // ── Sweets ────────────────────────────────────────────────────────────────
    const FoodEntity(
      id: 'f_dark_chocolate',
      name: 'Dark Chocolate (70%)',
      brand: 'Generic',
      category: FoodCategory.sweets,
      servingSize: 28,
      servingUnit: 'g (1 oz)',
      nutritionPer100g: NutritionFacts(
        calories: 598,
        proteinG: 7.8,
        carbsG: 45.8,
        fatG: 42.6,
        fiberG: 10.9,
        sugarG: 24.2,
        sodiumMg: 20,
        iron: 67,
        calcium: 7,
      ),
    ),
  ];
}
