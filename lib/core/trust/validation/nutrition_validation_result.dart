import '../domain/entities/nutrition_input.dart';

/// The result of validating a [RawFoodInput].
///
/// Validation is total: the result is always either [ValidationSuccess]
/// or [ValidationFailure] — never a mix of partial results.
///
/// After a [ValidationSuccess], the [validatedInput] field is guaranteed
/// to be non-null and safe to pass to the calculation engine.
sealed class NutritionValidationResult {
  const NutritionValidationResult();
}

/// Validation passed. [validatedInput] is ready for the calculation engine.
final class ValidationSuccess extends NutritionValidationResult {
  const ValidationSuccess({required this.validatedInput});

  final NutritionInput validatedInput;
}

/// Validation failed. [errors] contains at least one [ValidationError].
final class ValidationFailure extends NutritionValidationResult {
  const ValidationFailure({required this.errors});

  final List<ValidationError> errors;

  /// True when any error is a critical data integrity issue.
  bool get hasCriticalError =>
      errors.any((e) => e.severity == ValidationSeverity.critical);

  /// Returns all error messages joined by newline.
  String get combinedMessage => errors.map((e) => e.message).join('\n');
}

// ── Error Types ────────────────────────────────────────────────────────────────

enum ValidationSeverity {
  /// Must fix before proceeding (e.g. negative calories).
  critical,

  /// Should fix but calculation can partially proceed (e.g. missing fiber).
  warning,

  /// Informational only (e.g. duplicate food in same meal).
  info,
}

enum ValidationErrorCode {
  // Input errors — critical
  emptyFoodName,
  foodNameTooLong,
  negativeServingSize,
  zeroServingSize,
  servingSizeTooLarge,
  negativeQuantity,
  zeroQuantity,
  quantityTooLarge,

  // Data integrity — critical
  negativeCalories,
  negativeMacro,
  invalidNutritionValues,

  // Availability — warnings
  unknownFood,
  missingMacroNutrients,
  lowConfidenceData,
  dataSourceUnavailable,

  // Ambiguity — info
  duplicateFoodItem,
  ambiguousFoodName,
  missingBarcode,
}

class ValidationError {
  const ValidationError({
    required this.code,
    required this.message,
    required this.severity,
    this.fieldName,
    this.suggestedAction,
  });

  final ValidationErrorCode code;
  final String message;
  final ValidationSeverity severity;

  /// Which field caused this error (e.g. "servingSizeG", "quantity").
  final String? fieldName;

  /// A suggestion to fix the error, shown in the UI.
  final String? suggestedAction;

  bool get isCritical => severity == ValidationSeverity.critical;
  bool get isWarning => severity == ValidationSeverity.warning;
  bool get isInfo => severity == ValidationSeverity.info;

  @override
  String toString() =>
      'ValidationError(${code.name}: $message [${severity.name}])';
}

// ── Batch result ────────────────────────────────────────────────────────────────

/// Result of validating multiple [RawFoodInput]s for a meal.
class BatchValidationResult {
  const BatchValidationResult({
    required this.successes,
    required this.failures,
  });

  /// Successfully validated inputs.
  final List<ValidationSuccess> successes;

  /// Failed validations keyed by the original food name.
  final List<({String foodName, ValidationFailure failure})> failures;

  bool get hasAnySuccess => successes.isNotEmpty;
  bool get hasAnyFailure => failures.isNotEmpty;
  bool get allSucceeded => failures.isEmpty;
  bool get allFailed => successes.isEmpty;

  int get totalCount => successes.length + failures.length;
}
