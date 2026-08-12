/// Nutritional macros and micros per 100g or per serving.
class NutritionFacts {
  const NutritionFacts({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.sugarG = 0,
    this.sodiumMg = 0,
    this.saturatedFatG = 0,
    this.cholesterolMg = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.calcium = 0,
    this.iron = 0,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;
  final double saturatedFatG;
  final double cholesterolMg;

  // Vitamins/Minerals (% Daily Value)
  final double vitaminC;
  final double vitaminD;
  final double calcium;
  final double iron;

  /// Returns facts scaled by [factor] (e.g. 1.5 servings).
  NutritionFacts scale(double factor) => NutritionFacts(
        calories: calories * factor,
        proteinG: proteinG * factor,
        carbsG: carbsG * factor,
        fatG: fatG * factor,
        fiberG: fiberG * factor,
        sugarG: sugarG * factor,
        sodiumMg: sodiumMg * factor,
        saturatedFatG: saturatedFatG * factor,
        cholesterolMg: cholesterolMg * factor,
        vitaminC: vitaminC,
        vitaminD: vitaminD,
        calcium: calcium,
        iron: iron,
      );
}

/// Food category.
enum FoodCategory {
  all,
  grains,
  protein,
  dairy,
  fruits,
  vegetables,
  fats,
  beverages,
  snacks,
  sweets,
}

extension FoodCategoryX on FoodCategory {
  String get label => switch (this) {
        FoodCategory.all => 'All',
        FoodCategory.grains => 'Grains',
        FoodCategory.protein => 'Protein',
        FoodCategory.dairy => 'Dairy',
        FoodCategory.fruits => 'Fruits',
        FoodCategory.vegetables => 'Vegetables',
        FoodCategory.fats => 'Fats & Oils',
        FoodCategory.beverages => 'Beverages',
        FoodCategory.snacks => 'Snacks',
        FoodCategory.sweets => 'Sweets',
      };

  String get emoji => switch (this) {
        FoodCategory.all => '🍽️',
        FoodCategory.grains => '🌾',
        FoodCategory.protein => '🥩',
        FoodCategory.dairy => '🥛',
        FoodCategory.fruits => '🍎',
        FoodCategory.vegetables => '🥦',
        FoodCategory.fats => '🥑',
        FoodCategory.beverages => '💧',
        FoodCategory.snacks => '🥜',
        FoodCategory.sweets => '🍪',
      };
}

/// A food item in the database.
class FoodEntity {
  const FoodEntity({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.servingSize,
    required this.servingUnit,
    required this.nutritionPer100g,
    this.isFavorite = false,
    this.isRecent = false,
    this.ingredients,
    this.barcode,
  });

  final String id;
  final String name;
  final String brand;
  final FoodCategory category;

  /// Default serving size in grams/ml.
  final double servingSize;
  final String servingUnit;

  /// Nutrition per 100 g/ml.
  final NutritionFacts nutritionPer100g;

  final bool isFavorite;
  final bool isRecent;
  final String? ingredients;
  final String? barcode;

  /// Returns nutrition facts for a given [servings] count.
  NutritionFacts nutritionForServings(double servings) =>
      nutritionPer100g.scale((servingSize * servings) / 100.0);

  FoodEntity copyWith({bool? isFavorite, bool? isRecent}) => FoodEntity(
        id: id,
        name: name,
        brand: brand,
        category: category,
        servingSize: servingSize,
        servingUnit: servingUnit,
        nutritionPer100g: nutritionPer100g,
        isFavorite: isFavorite ?? this.isFavorite,
        isRecent: isRecent ?? this.isRecent,
        ingredients: ingredients,
        barcode: barcode,
      );
}

