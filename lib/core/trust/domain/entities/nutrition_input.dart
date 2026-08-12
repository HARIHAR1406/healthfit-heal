import '../../../../features/nutrition/domain/entities/food_entity.dart';

/// A validated, ready-to-calculate food input.
///
/// Instances of [NutritionInput] can only be created through
/// [NutritionInputValidator.validate], which guarantees:
///   - foodName is non-empty and trimmed
///   - servingSizeG is positive and within [kMinServingSizeG]..[kMaxServingSizeG]
///   - quantity is positive and within [kMinQuantity]..[kMaxQuantity]
///   - The combination is not a known unsupported item
///
/// Construction outside of the validator is intentionally private to prevent
/// invalid inputs from reaching the calculation engine.
class NutritionInput {
  const NutritionInput._({
    required this.foodName,
    required this.servingSizeG,
    required this.quantity,
    this.unit = 'g',
    this.foodId,
    this.barcode,
    this.rawFoodEntity,
  });

  /// Name of the food item (trimmed, non-empty, max 200 chars).
  final String foodName;

  /// Serving size in grams or ml.
  final double servingSizeG;

  /// Number of servings (e.g. 2.5 apples = quantity 2.5).
  final double quantity;

  /// Unit label for display ("g", "ml", "piece", "cup", etc.)
  final String unit;

  /// Optional ID when the food was matched in the trusted database.
  final String? foodId;

  /// Optional barcode — for future Food Vision integration.
  final String? barcode;

  /// The original [FoodEntity] if this input was resolved from the database.
  final FoodEntity? rawFoodEntity;

  // ── Derived ────────────────────────────────────────────────────────────────

  /// Total grams to calculate nutrition for (servingSizeG × quantity).
  double get totalGrams => servingSizeG * quantity;

  /// Whether this input was matched to a known food in the database.
  bool get isResolved => foodId != null;

  // ── Constants ──────────────────────────────────────────────────────────────

  /// Minimum valid serving size (1 g).
  static const double kMinServingSizeG = 1.0;

  /// Maximum valid serving size (5 kg — catches accidental data entry errors).
  static const double kMaxServingSizeG = 5000.0;

  /// Minimum valid quantity (0.1 — smallest useful portion).
  static const double kMinQuantity = 0.1;

  /// Maximum valid quantity (100 — reasonable upper bound for a meal log).
  static const double kMaxQuantity = 100.0;

  // ── Package-private constructor for validator ──────────────────────────────

  /// Creates a validated [NutritionInput].
  ///
  /// Only the [NutritionInputValidator] should call this. External code should
  /// use [NutritionInputValidator.validate] to obtain a validated instance.
  factory NutritionInput.validated({
    required String foodName,
    required double servingSizeG,
    required double quantity,
    String unit = 'g',
    String? foodId,
    String? barcode,
    FoodEntity? rawFoodEntity,
  }) {
    return NutritionInput._(
      foodName: foodName,
      servingSizeG: servingSizeG,
      quantity: quantity,
      unit: unit,
      foodId: foodId,
      barcode: barcode,
      rawFoodEntity: rawFoodEntity,
    );
  }

  @override
  String toString() =>
      'NutritionInput(food=$foodName, '
      'serving=${servingSizeG}g × $quantity = ${totalGrams}g)';
}

/// Raw (unvalidated) food input from the UI or AI vision layer.
///
/// This is the object that enters the validation pipeline.
/// After validation it becomes a [NutritionInput].
class RawFoodInput {
  const RawFoodInput({
    required this.foodName,
    this.servingSizeG,
    this.quantity = 1.0,
    this.unit = 'g',
    this.foodId,
    this.barcode,
  });

  final String? foodName;
  final double? servingSizeG;
  final double quantity;
  final String unit;
  final String? foodId;
  final String? barcode;

  @override
  String toString() =>
      'RawFoodInput(food=$foodName, serving=$servingSizeG, qty=$quantity)';
}

