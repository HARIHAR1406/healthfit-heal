import 'package:flutter_test/flutter_test.dart';

import 'package:health_fit_heal/core/trust/domain/entities/nutrition_input.dart';
import 'package:health_fit_heal/features/nutrition/domain/entities/detected_food.dart';

/// Tests for the ConfirmedFoodItem → RawFoodInput conversion logic.
///
/// This validates that the bridge between the Phase 13 vision layer and the
/// Phase 12 nutrition pipeline preserves data integrity. The conversion is
/// done inside [FoodScannerNotifier._toRawFoodInput], but since that is a
/// private method we test the underlying entity logic directly.
void main() {
  group('ConfirmedFoodItem → RawFoodInput conversion logic', () {
    test('gram-based item produces correct RawFoodInput', () {
      const item = ConfirmedFoodItem(
        id: 'test_1',
        name: 'Oatmeal',
        quantity: 100.0,
        unit: ServingUnit.grams,
      );

      // Simulate what the notifier does
      final servingSizeG = item.servingSizeG ?? item.unit.gramsEquivalent;
      final input = RawFoodInput(
        foodName: item.name,
        servingSizeG: servingSizeG,
        quantity: item.quantity,
        unit: item.unit.label,
      );

      expect(input.foodName, 'Oatmeal');
      expect(input.servingSizeG, 1.0); // 1 g per g
      expect(input.quantity, 100.0);
      expect(input.unit, 'g');
    });

    test('cup-based item resolves to 240 g per cup', () {
      const item = ConfirmedFoodItem(
        id: 'test_2',
        name: 'Rice',
        quantity: 1.5,
        unit: ServingUnit.cups,
      );

      final servingSizeG = item.servingSizeG ?? item.unit.gramsEquivalent;
      final input = RawFoodInput(
        foodName: item.name,
        servingSizeG: servingSizeG,
        quantity: item.quantity,
        unit: item.unit.label,
      );

      expect(input.servingSizeG, 240.0);
      expect(input.quantity, 1.5);
    });

    test('piece-based item passes null servingSizeG (food-DB default)', () {
      const item = ConfirmedFoodItem(
        id: 'test_3',
        name: 'Apple',
        quantity: 2.0,
        unit: ServingUnit.pieces,
      );

      final servingSizeG = item.servingSizeG ?? item.unit.gramsEquivalent;
      // pieces returns null → RawFoodInput.servingSizeG will be null
      final input = RawFoodInput(
        foodName: item.name,
        servingSizeG: servingSizeG,
        quantity: item.quantity,
        unit: item.unit.label,
      );

      expect(input.servingSizeG, isNull);
      expect(input.quantity, 2.0);
      expect(input.unit, 'piece(s)');
    });

    test('item with explicit servingSizeG overrides unit-based calculation', () {
      const item = ConfirmedFoodItem(
        id: 'test_4',
        name: 'Banana',
        quantity: 1.0,
        unit: ServingUnit.pieces,
        servingSizeG: 118.0, // user-specified size
      );

      final servingSizeG = item.servingSizeG ?? item.unit.gramsEquivalent;
      final input = RawFoodInput(
        foodName: item.name,
        servingSizeG: servingSizeG,
        quantity: item.quantity,
        unit: item.unit.label,
      );

      // servingSizeG takes precedence over null gramsEquivalent
      expect(input.servingSizeG, 118.0);
    });

    test('food name from ConfirmedFoodItem is preserved in RawFoodInput', () {
      const item = ConfirmedFoodItem(
        id: 'test_5',
        name: '  Chicken Breast  ', // with spaces — trim expected upstream
        quantity: 1.0,
        unit: ServingUnit.servings,
      );

      final input = RawFoodInput(
        foodName: item.name,
        servingSizeG: item.unit.gramsEquivalent,
        quantity: item.quantity,
        unit: item.unit.label,
      );

      // No trimming in the conversion itself; notifier trims before creating item
      expect(input.foodName, '  Chicken Breast  ');
    });

    test('RawFoodInput default quantity is 1.0', () {
      final input = RawFoodInput(
        foodName: 'Test',
      );
      expect(input.quantity, 1.0);
    });

    test('RawFoodInput default unit is g', () {
      final input = RawFoodInput(
        foodName: 'Test',
      );
      expect(input.unit, 'g');
    });
  });

  group('ConfirmedFoodItem.totalGramsIfKnown', () {
    test('returns null for pieces', () {
      const item = ConfirmedFoodItem(
        id: '1', name: 'Egg', quantity: 3.0, unit: ServingUnit.pieces);
      expect(item.totalGramsIfKnown, isNull);
    });

    test('returns quantity × 240 for cups', () {
      const item = ConfirmedFoodItem(
        id: '2', name: 'Milk', quantity: 2.0, unit: ServingUnit.cups);
      expect(item.totalGramsIfKnown, 480.0); // 2 × 240
    });

    test('returns quantity × 15 for tablespoons', () {
      const item = ConfirmedFoodItem(
        id: '3', name: 'Oil', quantity: 2.0, unit: ServingUnit.tablespoons);
      expect(item.totalGramsIfKnown, 30.0); // 2 × 15
    });
  });
}
