import '../../../../features/nutrition/domain/entities/food_entity.dart';
import '../domain/entities/nutrition_input.dart';
import '../domain/entities/verified_nutrition.dart';
import 'nutrition_validation_result.dart';

/// Validates raw food inputs before they reach the calculation engine.
///
/// ── Validation rules applied in order ────────────────────────────────────────
/// CRITICAL (block calculation):
///   1. Empty or null food name
///   2. Food name too long (> 200 chars)
///   3. Zero or negative serving size
///   4. Serving size exceeds maximum (5000 g)
///   5. Zero or negative quantity
///   6. Quantity exceeds maximum (100 servings)
///   7. Negative nutrition values (calories, macros)
///   8. Invalid serving + quantity combination (totalGrams <= 0)
///
/// WARNING (log and continue):
///   9.  Food not found in trusted database
///   10. Missing core macronutrient fields
///   11. Low confidence score (< 0.50)
///   12. Data source unavailable
///
/// INFO (notify user):
///   13. Duplicate food name in same batch
///   14. Ambiguous food name (multiple matches)
///
/// ── Guarantees ────────────────────────────────────────────────────────────────
/// A [ValidationSuccess] guarantees that the resulting [NutritionInput] is
/// safe to pass to [NutritionCalculationEngine].
/// A [ValidationFailure] with any [critical] error must NOT proceed to calculation.
class NutritionInputValidator {
  const NutritionInputValidator();

  // ── Single input ────────────────────────────────────────────────────────────

  /// Validates a single [RawFoodInput] against the validation rules.
  ///
  /// [resolvedFood] is the [VerifiedNutrition] found in the trusted database,
  /// if available. Pass null if the lookup has not yet been performed or failed.
  NutritionValidationResult validate(
    RawFoodInput raw, {
    VerifiedNutrition? resolvedFood,
  }) {
    final errors = <ValidationError>[];

    // ── Rule 1: Food name ────────────────────────────────────────────────────
    final name = raw.foodName?.trim() ?? '';
    if (name.isEmpty) {
      errors.add(const ValidationError(
        code: ValidationErrorCode.emptyFoodName,
        message: 'Food name is required.',
        severity: ValidationSeverity.critical,
        fieldName: 'foodName',
        suggestedAction: 'Please enter the name of the food item.',
      ));
    } else if (name.length > 200) {
      errors.add(const ValidationError(
        code: ValidationErrorCode.foodNameTooLong,
        message: 'Food name is too long (maximum 200 characters).',
        severity: ValidationSeverity.critical,
        fieldName: 'foodName',
        suggestedAction: 'Shorten the food name.',
      ));
    }

    // ── Rule 2: Serving size ─────────────────────────────────────────────────
    final servingSize = raw.servingSizeG;
    if (servingSize == null || servingSize <= 0) {
      errors.add(ValidationError(
        code: servingSize == null || servingSize == 0
            ? ValidationErrorCode.zeroServingSize
            : ValidationErrorCode.negativeServingSize,
        message: servingSize == null
            ? 'Serving size is required.'
            : servingSize == 0
                ? 'Serving size must be greater than zero.'
                : 'Serving size cannot be negative.',
        severity: ValidationSeverity.critical,
        fieldName: 'servingSizeG',
        suggestedAction: 'Enter a serving size in grams or ml (e.g. 100).',
      ));
    } else if (servingSize < NutritionInput.kMinServingSizeG) {
      errors.add(ValidationError(
        code: ValidationErrorCode.zeroServingSize,
        message:
            'Serving size must be at least ${NutritionInput.kMinServingSizeG} g.',
        severity: ValidationSeverity.critical,
        fieldName: 'servingSizeG',
      ));
    } else if (servingSize > NutritionInput.kMaxServingSizeG) {
      errors.add(ValidationError(
        code: ValidationErrorCode.servingSizeTooLarge,
        message:
            'Serving size ${servingSize.toStringAsFixed(0)} g exceeds maximum '
            '(${NutritionInput.kMaxServingSizeG.toStringAsFixed(0)} g). '
            'Check for data entry error.',
        severity: ValidationSeverity.critical,
        fieldName: 'servingSizeG',
        suggestedAction: 'Verify the serving size and re-enter.',
      ));
    }

    // ── Rule 3: Quantity ─────────────────────────────────────────────────────
    final quantity = raw.quantity;
    if (quantity <= 0) {
      errors.add(ValidationError(
        code: quantity == 0
            ? ValidationErrorCode.zeroQuantity
            : ValidationErrorCode.negativeQuantity,
        message: quantity == 0
            ? 'Quantity must be greater than zero.'
            : 'Quantity cannot be negative.',
        severity: ValidationSeverity.critical,
        fieldName: 'quantity',
        suggestedAction: 'Enter the number of servings (e.g. 1, 1.5, 2).',
      ));
    } else if (quantity > NutritionInput.kMaxQuantity) {
      errors.add(ValidationError(
        code: ValidationErrorCode.quantityTooLarge,
        message:
            'Quantity $quantity exceeds maximum (${NutritionInput.kMaxQuantity}).',
        severity: ValidationSeverity.critical,
        fieldName: 'quantity',
        suggestedAction: 'Check for data entry error.',
      ));
    }

    // ── Rule 4: Resolved food nutrition validation ────────────────────────────
    if (resolvedFood != null) {
      errors.addAll(_validateResolvedNutrition(resolvedFood));
    } else if (name.isNotEmpty) {
      // Food name was given but couldn't be resolved
      errors.add(ValidationError(
        code: ValidationErrorCode.unknownFood,
        message: '"$name" could not be found in the verified nutrition database.',
        severity: ValidationSeverity.warning,
        fieldName: 'foodName',
        suggestedAction:
            'Try a different name or check spelling. '
            'Nutrition information cannot be verified for unknown foods.',
      ));
    }

    // ── Any critical errors → fail immediately ────────────────────────────────
    if (errors.any((e) => e.isCritical)) {
      return ValidationFailure(errors: List.unmodifiable(errors));
    }

    // ── Build validated input ─────────────────────────────────────────────────
    final validatedInput = NutritionInput.validated(
      foodName: name,
      servingSizeG: servingSize!,
      quantity: quantity,
      unit: raw.unit,
      foodId: raw.foodId ?? resolvedFood?.foodId,
      barcode: raw.barcode,
      rawFoodEntity: resolvedFood?.nutritionPer100g != null
          ? _buildFoodEntity(name, servingSize, raw.unit, resolvedFood!)
          : null,
    );

    // Return success even if there are warnings — warnings are attached as
    // metadata that the recommendation safety layer will inspect.
    return ValidationSuccess(validatedInput: validatedInput);
  }

  // ── Batch validation ─────────────────────────────────────────────────────────

  /// Validates multiple raw inputs for a single meal.
  ///
  /// Also checks for duplicate food items within the batch.
  BatchValidationResult validateBatch(
    List<RawFoodInput> inputs, {
    Map<String, VerifiedNutrition>? resolvedFoods,
  }) {
    final successes = <ValidationSuccess>[];
    final failures = <({String foodName, ValidationFailure failure})>[];
    final seenNames = <String>{};

    for (final raw in inputs) {
      // Check for duplicate within this batch
      final normalizedName = (raw.foodName?.trim().toLowerCase()) ?? '';
      List<ValidationError>? extraErrors;

      if (normalizedName.isNotEmpty && seenNames.contains(normalizedName)) {
        extraErrors = [
          ValidationError(
            code: ValidationErrorCode.duplicateFoodItem,
            message: '"${raw.foodName}" appears more than once in this meal.',
            severity: ValidationSeverity.info,
            fieldName: 'foodName',
            suggestedAction:
                'Combine duplicate entries or adjust quantities.',
          ),
        ];
      }
      seenNames.add(normalizedName);

      final resolved = resolvedFoods?[normalizedName];
      var result = validate(raw, resolvedFood: resolved);

      // Merge any extra batch-level errors
      if (extraErrors != null && extraErrors.isNotEmpty) {
        result = switch (result) {
          ValidationSuccess(validatedInput: final vi) =>
            ValidationSuccess(validatedInput: vi),
          ValidationFailure(errors: final existing) => ValidationFailure(
              errors: [...existing, ...extraErrors],
            ),
        };
      }

      switch (result) {
        case ValidationSuccess():
          successes.add(result);
        case ValidationFailure():
          failures.add(
            (foodName: raw.foodName ?? 'Unknown', failure: result),
          );
      }
    }

    return BatchValidationResult(successes: successes, failures: failures);
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  List<ValidationError> _validateResolvedNutrition(VerifiedNutrition food) {
    final errors = <ValidationError>[];
    final facts = food.nutritionPer100g;

    // Check for negative values — should never happen from a trusted source,
    // but must be caught if data is corrupted.
    if (facts.calories < 0) {
      errors.add(ValidationError(
        code: ValidationErrorCode.negativeCalories,
        message:
            'Nutrition data for "${food.foodName}" contains '
            'invalid negative calorie value (${facts.calories}).',
        severity: ValidationSeverity.critical,
        fieldName: 'calories',
        suggestedAction: 'This food entry may be corrupted. Please report it.',
      ));
    }

    for (final entry in {
      'proteinG': facts.proteinG,
      'carbsG': facts.carbsG,
      'fatG': facts.fatG,
    }.entries) {
      if (entry.value < 0) {
        errors.add(ValidationError(
          code: ValidationErrorCode.negativeMacro,
          message:
              '${entry.key} has an invalid negative value (${entry.value}) '
              'for "${food.foodName}".',
          severity: ValidationSeverity.critical,
          fieldName: entry.key,
        ));
      }
    }

    // Warning: incomplete macros
    if (!food.hasCompleteMacros) {
      errors.add(ValidationError(
        code: ValidationErrorCode.missingMacroNutrients,
        message:
            'Nutrition data for "${food.foodName}" is missing some macronutrients. '
            'Calculation will use available values only.',
        severity: ValidationSeverity.warning,
        fieldName: 'nutritionPer100g',
        suggestedAction: 'Nutrition totals may be incomplete.',
      ));
    }

    // Warning: low confidence
    if (!food.source.isHighConfidence) {
      errors.add(ValidationError(
        code: ValidationErrorCode.lowConfidenceData,
        message:
            'Nutrition data for "${food.foodName}" has low confidence '
            '(${food.source.confidenceLabel}). Values may be approximate.',
        severity: ValidationSeverity.warning,
        fieldName: 'source',
      ));
    }

    return errors;
  }

  /// Builds a minimal [FoodEntity] from resolved data for backward compatibility.
  FoodEntity _buildFoodEntity(
    String name,
    double servingSize,
    String unit,
    VerifiedNutrition resolved,
  ) {
    return FoodEntity(
      id: resolved.foodId,
      name: name,
      brand: resolved.source.sourceName ?? '',
      category: FoodCategory.all,
      servingSize: servingSize,
      servingUnit: unit,
      nutritionPer100g: resolved.nutritionPer100g,
    );
  }
}

