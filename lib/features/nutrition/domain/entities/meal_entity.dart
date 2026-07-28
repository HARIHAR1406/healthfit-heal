import 'food_entity.dart';

/// Meal types within a day.
enum MealType {
  breakfast,
  morningSnack,
  lunch,
  eveningSnack,
  dinner,
}

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.morningSnack => 'Morning Snack',
        MealType.lunch => 'Lunch',
        MealType.eveningSnack => 'Evening Snack',
        MealType.dinner => 'Dinner',
      };

  String get emoji => switch (this) {
        MealType.breakfast => '🌅',
        MealType.morningSnack => '🍌',
        MealType.lunch => '🍱',
        MealType.eveningSnack => '🥜',
        MealType.dinner => '🍽️',
      };

  String get defaultTime => switch (this) {
        MealType.breakfast => '07:00',
        MealType.morningSnack => '10:00',
        MealType.lunch => '13:00',
        MealType.eveningSnack => '16:30',
        MealType.dinner => '19:00',
      };
}

/// A logged food item inside a meal.
class MealFoodEntry {
  const MealFoodEntry({
    required this.id,
    required this.food,
    required this.servings,
    required this.loggedAt,
  });

  final String id;
  final FoodEntity food;
  final double servings;
  final DateTime loggedAt;

  NutritionFacts get facts => food.nutritionForServings(servings);

  double get calories => facts.calories;
  double get proteinG => facts.proteinG;
  double get carbsG => facts.carbsG;
  double get fatG => facts.fatG;
}

/// One meal within a day plan.
class MealEntity {
  const MealEntity({
    required this.id,
    required this.type,
    required this.entries,
    required this.date,
  });

  final String id;
  final MealType type;
  final List<MealFoodEntry> entries;
  final DateTime date;

  double get totalCalories =>
      entries.fold(0, (s, e) => s + e.calories);
  double get totalProteinG =>
      entries.fold(0, (s, e) => s + e.proteinG);
  double get totalCarbsG =>
      entries.fold(0, (s, e) => s + e.carbsG);
  double get totalFatG =>
      entries.fold(0, (s, e) => s + e.fatG);

  bool get isEmpty => entries.isEmpty;
}

/// A full day's meal plan + nutrition totals.
class DailyNutritionEntity {
  const DailyNutritionEntity({
    required this.date,
    required this.meals,
    required this.goals,
    required this.waterMl,
    required this.waterGoalMl,
  });

  final DateTime date;
  final List<MealEntity> meals;
  final NutritionGoals goals;
  final int waterMl;
  final int waterGoalMl;

  double get totalCalories =>
      meals.fold(0, (s, m) => s + m.totalCalories);
  double get totalProteinG =>
      meals.fold(0, (s, m) => s + m.totalProteinG);
  double get totalCarbsG =>
      meals.fold(0, (s, m) => s + m.totalCarbsG);
  double get totalFatG =>
      meals.fold(0, (s, m) => s + m.totalFatG);

  double get caloriesRemaining =>
      (goals.caloriesGoal - totalCalories).clamp(0, goals.caloriesGoal);
  double get calorieFraction =>
      (totalCalories / goals.caloriesGoal).clamp(0.0, 1.0);
  double get proteinFraction =>
      (totalProteinG / goals.proteinGoalG).clamp(0.0, 1.0);
  double get carbsFraction =>
      (totalCarbsG / goals.carbsGoalG).clamp(0.0, 1.0);
  double get fatFraction =>
      (totalFatG / goals.fatGoalG).clamp(0.0, 1.0);
  double get waterFraction =>
      (waterMl / waterGoalMl).clamp(0.0, 1.0);

  /// Overall nutrition score 0–100.
  int get nutritionScore {
    final protein = (proteinFraction * 25).clamp(0, 25);
    final carbs = (carbsFraction * 25).clamp(0, 25);
    final fat = (fatFraction * 25).clamp(0, 25);
    final water = (waterFraction * 25).clamp(0, 25);
    return (protein + carbs + fat + water).round();
  }
}

/// Daily nutrition goals.
class NutritionGoals {
  const NutritionGoals({
    required this.caloriesGoal,
    required this.proteinGoalG,
    required this.carbsGoalG,
    required this.fatGoalG,
    this.fiberGoalG = 30,
    this.waterGoalMl = 2500,
    this.sodiumGoalMg = 2300,
  });

  final double caloriesGoal;
  final double proteinGoalG;
  final double carbsGoalG;
  final double fatGoalG;
  final double fiberGoalG;
  final int waterGoalMl;
  final double sodiumGoalMg;
}
