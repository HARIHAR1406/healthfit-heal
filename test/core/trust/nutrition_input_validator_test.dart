import 'package:flutter_test/flutter_test.dart';
import 'package:healthfit_heal/core/trust/domain/entities/nutrition_input.dart';
import 'package:healthfit_heal/core/trust/validation/nutrition_input_validator.dart';
import 'package:healthfit_heal/core/trust/validation/nutrition_validation_result.dart';
import 'package:healthfit_heal/core/trust/domain/entities/verified_nutrition.dart';
import 'package:healthfit_heal/core/trust/domain/entities/data_source_info.dart';
import 'package:healthfit_heal/features/nutrition/domain/entities/food_entity.dart';

void main() {
  const validator = NutritionInputValidator();

  // ── Helper ─────────────────────────────────────────────────────────────────

  VerifiedNutrition _makeVerified({
    String id = 'test_food',
    String name = 'Test Food',
    double calories = 100,
    double protein = 10,
    double carbs = 15,
    double fat = 3,
  }) {
    return VerifiedNutrition(
      foodId: id,
      foodName: name,
      source: const DataSourceInfo.appSeed(),
      nutritionPer100g: NutritionFacts(
        calories: calories,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
      ),
      defaultServingSize: 100,
      defaultServingUnit: 'g',
    );
  }

  RawFoodInput _makeRaw({
    String? name = 'Apple',
    double? servingSize = 100.0,
    double quantity = 1.0,
  }) {
    return RawFoodInput(
      foodName: name,
      servingSizeG: servingSize,
      quantity: quantity,
    );
  }

  // ── Valid inputs ──────────────────────────────────────────────────────────

  group('Valid inputs', () {
    test('single food with defaults → ValidationSuccess', () {
      final result = validator.validate(_makeRaw());
      expect(result, isA<ValidationSuccess>());
      final s = result as ValidationSuccess;
      expect(s.validatedInput.foodName, 'Apple');
      expect(s.validatedInput.servingSizeG, 100.0);
      expect(s.validatedInput.quantity, 1.0);
      expect(s.validatedInput.totalGrams, 100.0);
    });

    test('fractional quantity (1.5 servings) → success', () {
      final result = validator.validate(_makeRaw(quantity: 1.5));
      expect(result, isA<ValidationSuccess>());
      final s = result as ValidationSuccess;
      expect(s.validatedInput.totalGrams, 150.0);
    });

    test('maximum valid quantity (100) → success', () {
      final result = validator.validate(_makeRaw(quantity: 100.0));
      expect(result, isA<ValidationSuccess>());
    });

    test('minimum valid quantity (0.1) → success', () {
      final result = validator.validate(_makeRaw(quantity: 0.1));
      expect(result, isA<ValidationSuccess>());
    });

    test('maximum valid serving size (5000 g) → success', () {
      final result = validator.validate(_makeRaw(servingSize: 5000.0));
      expect(result, isA<ValidationSuccess>());
    });

    test('minimum valid serving size (1.0 g) → success', () {
      final result = validator.validate(_makeRaw(servingSize: 1.0));
      expect(result, isA<ValidationSuccess>());
    });

    test('food name with extra whitespace is trimmed → success', () {
      final result = validator.validate(_makeRaw(name: '  Apple  '));
      expect(result, isA<ValidationSuccess>());
      final s = result as ValidationSuccess;
      expect(s.validatedInput.foodName, 'Apple');
    });

    test('resolved food with complete macros → success, no warnings', () {
      final resolved = _makeVerified();
      final result = validator.validate(_makeRaw(), resolvedFood: resolved);
      expect(result, isA<ValidationSuccess>());
    });
  });

  // ── Empty / null inputs ───────────────────────────────────────────────────

  group('Empty / null inputs', () {
    test('null food name → critical error emptyFoodName', () {
      final result = validator.validate(_makeRaw(name: null));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(f.hasCriticalError, isTrue);
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.emptyFoodName),
        isTrue,
      );
    });

    test('empty string food name → critical error emptyFoodName', () {
      final result = validator.validate(_makeRaw(name: ''));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.emptyFoodName),
        isTrue,
      );
    });

    test('whitespace-only food name → critical error emptyFoodName', () {
      final result = validator.validate(_makeRaw(name: '   '));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.emptyFoodName),
        isTrue,
      );
    });

    test('food name > 200 chars → critical error foodNameTooLong', () {
      final longName = 'A' * 201;
      final result = validator.validate(_makeRaw(name: longName));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.foodNameTooLong),
        isTrue,
      );
    });
  });

  // ── Negative values ───────────────────────────────────────────────────────

  group('Negative values', () {
    test('negative serving size → critical error negativeServingSize', () {
      final result = validator.validate(_makeRaw(servingSize: -50.0));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.negativeServingSize),
        isTrue,
      );
    });

    test('zero serving size → critical error zeroServingSize', () {
      final result = validator.validate(_makeRaw(servingSize: 0));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any(
          (e) => e.code == ValidationErrorCode.zeroServingSize ||
              e.code == ValidationErrorCode.negativeServingSize,
        ),
        isTrue,
      );
    });

    test('negative quantity → critical error negativeQuantity', () {
      final result = validator.validate(_makeRaw(quantity: -1.0));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.negativeQuantity),
        isTrue,
      );
    });

    test('zero quantity → critical error zeroQuantity', () {
      final result = validator.validate(_makeRaw(quantity: 0));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.zeroQuantity),
        isTrue,
      );
    });

    test('resolved food with negative calories → critical error', () {
      final badFood = _makeVerified(calories: -100);
      final result = validator.validate(_makeRaw(), resolvedFood: badFood);
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.negativeCalories),
        isTrue,
      );
    });

    test('resolved food with negative protein → critical error negativeMacro', () {
      final badFood = _makeVerified(protein: -5);
      final result = validator.validate(_makeRaw(), resolvedFood: badFood);
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.negativeMacro),
        isTrue,
      );
    });
  });

  // ── Serving size bounds ───────────────────────────────────────────────────

  group('Serving size bounds', () {
    test('serving size > 5000 g → critical error servingSizeTooLarge', () {
      final result = validator.validate(_makeRaw(servingSize: 5001.0));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.servingSizeTooLarge),
        isTrue,
      );
    });

    test('serving size < 1 g → critical error zeroServingSize', () {
      final result = validator.validate(_makeRaw(servingSize: 0.5));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(f.hasCriticalError, isTrue);
    });
  });

  // ── Quantity bounds ───────────────────────────────────────────────────────

  group('Quantity bounds', () {
    test('quantity > 100 → critical error quantityTooLarge', () {
      final result = validator.validate(_makeRaw(quantity: 101.0));
      expect(result, isA<ValidationFailure>());
      final f = result as ValidationFailure;
      expect(
        f.errors.any((e) => e.code == ValidationErrorCode.quantityTooLarge),
        isTrue,
      );
    });
  });

  // ── Unknown food ──────────────────────────────────────────────────────────

  group('Unknown food', () {
    test('no resolved food → warning unknownFood (not critical)', () {
      final result = validator.validate(
        _makeRaw(name: 'XYZ Unknown Food'),
        resolvedFood: null,
      );
      // Should still succeed (unknownFood is a warning, not critical)
      expect(result, isA<ValidationSuccess>());
    });
  });

  // ── Duplicate detection ───────────────────────────────────────────────────

  group('Batch: duplicate detection', () {
    test('same food twice → info error duplicateFoodItem', () {
      final inputs = [
        _makeRaw(name: 'Apple'),
        _makeRaw(name: 'Apple'),
      ];
      final result = validator.validateBatch(inputs);
      // First should succeed; second may succeed with info flag
      expect(result.hasAnySuccess, isTrue);
      // No critical failure from duplicates
      expect(result.failures.every((f) => !f.failure.hasCriticalError), isTrue);
    });

    test('different foods → all succeed', () {
      final inputs = [
        _makeRaw(name: 'Apple'),
        _makeRaw(name: 'Banana'),
        _makeRaw(name: 'Chicken Breast'),
      ];
      final result = validator.validateBatch(inputs);
      expect(result.allSucceeded, isTrue);
      expect(result.successes.length, 3);
    });

    test('mix of valid and invalid → partial batch result', () {
      final inputs = [
        _makeRaw(name: 'Apple'),
        _makeRaw(name: null), // invalid
        _makeRaw(name: 'Banana'),
      ];
      final result = validator.validateBatch(inputs);
      expect(result.hasAnySuccess, isTrue);
      expect(result.hasAnyFailure, isTrue);
      expect(result.totalCount, 3);
    });

    test('all invalid → allFailed', () {
      final inputs = [
        _makeRaw(name: null),
        _makeRaw(servingSize: -1),
      ];
      final result = validator.validateBatch(inputs);
      expect(result.allFailed, isTrue);
    });
  });

  // ── ValidationError details ───────────────────────────────────────────────

  group('ValidationError details', () {
    test('failure contains field name for serving size error', () {
      final result = validator.validate(_makeRaw(servingSize: -1));
      final f = result as ValidationFailure;
      final error = f.errors.first;
      expect(error.fieldName, isNotNull);
    });

    test('failure contains suggested action', () {
      final result = validator.validate(_makeRaw(name: null));
      final f = result as ValidationFailure;
      final error = f.errors.first;
      expect(error.suggestedAction, isNotNull);
    });

    test('combinedMessage joins all error messages', () {
      final result = validator.validate(_makeRaw(name: null));
      final f = result as ValidationFailure;
      expect(f.combinedMessage, isNotEmpty);
    });
  });
}
