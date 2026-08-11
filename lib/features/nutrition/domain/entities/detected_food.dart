import 'dart:typed_data';

// ── Recognition Status ─────────────────────────────────────────────────────────

/// The status of an individual food item's recognition.
enum RecognitionStatus {
  /// High-confidence identification (≥ 80%).
  identified,

  /// Medium-confidence identification (50–79%).
  uncertain,

  /// Low-confidence identification (< 50%).
  lowConfidence,

  /// Food-like object detected, but specific food could not be identified.
  unknownFood,
}

extension RecognitionStatusX on RecognitionStatus {
  String get label => switch (this) {
        RecognitionStatus.identified => 'High Confidence',
        RecognitionStatus.uncertain => 'Medium Confidence',
        RecognitionStatus.lowConfidence => 'Low Confidence',
        RecognitionStatus.unknownFood => 'Unknown Food',
      };

  String get emoji => switch (this) {
        RecognitionStatus.identified => '✓',
        RecognitionStatus.uncertain => '~',
        RecognitionStatus.lowConfidence => '?',
        RecognitionStatus.unknownFood => '✗',
      };

  bool get isUsable =>
      this == RecognitionStatus.identified ||
      this == RecognitionStatus.uncertain;
}

// ── Bounding Box ───────────────────────────────────────────────────────────────

/// Normalized bounding box [0.0 – 1.0] for a detected food region.
class BoundingBox {
  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  double get centerX => left + width / 2;
  double get centerY => top + height / 2;
}

// ── Quantity Estimation ────────────────────────────────────────────────────────

/// Standard serving units supported by the quantity estimator.
enum ServingUnit {
  grams,
  milliliters,
  cups,
  tablespoons,
  teaspoons,
  pieces,
  servings,
}

extension ServingUnitX on ServingUnit {
  String get label => switch (this) {
        ServingUnit.grams => 'g',
        ServingUnit.milliliters => 'ml',
        ServingUnit.cups => 'cup',
        ServingUnit.tablespoons => 'tbsp',
        ServingUnit.teaspoons => 'tsp',
        ServingUnit.pieces => 'piece(s)',
        ServingUnit.servings => 'serving(s)',
      };

  String get fullLabel => switch (this) {
        ServingUnit.grams => 'Grams',
        ServingUnit.milliliters => 'Milliliters',
        ServingUnit.cups => 'Cups',
        ServingUnit.tablespoons => 'Tablespoons',
        ServingUnit.teaspoons => 'Teaspoons',
        ServingUnit.pieces => 'Pieces',
        ServingUnit.servings => 'Servings',
      };

  /// Approximate gram equivalent for unit conversion.
  /// Returns null for units that are food-dependent (pieces, servings).
  double? get gramsEquivalent => switch (this) {
        ServingUnit.grams => 1.0,
        ServingUnit.milliliters => 1.0, // ~1 g/ml for water-based foods
        ServingUnit.cups => 240.0,
        ServingUnit.tablespoons => 15.0,
        ServingUnit.teaspoons => 5.0,
        ServingUnit.pieces => null, // food-dependent
        ServingUnit.servings => null, // food-dependent
      };
}

/// Parse a unit label string to a [ServingUnit].
ServingUnit parseServingUnit(String raw) {
  final normalized = raw.trim().toLowerCase();
  return switch (normalized) {
    'g' || 'gram' || 'grams' => ServingUnit.grams,
    'ml' || 'milliliter' || 'milliliters' => ServingUnit.milliliters,
    'cup' || 'cups' => ServingUnit.cups,
    'tbsp' || 'tablespoon' || 'tablespoons' => ServingUnit.tablespoons,
    'tsp' || 'teaspoon' || 'teaspoons' => ServingUnit.teaspoons,
    'piece' || 'pieces' || 'pcs' => ServingUnit.pieces,
    _ => ServingUnit.servings,
  };
}

// ── Detected Food ──────────────────────────────────────────────────────────────

/// A single food item detected by the vision recognition system.
///
/// ── Separation of concerns ────────────────────────────────────────────────────
/// This model contains ONLY recognition-layer information:
///   - Food name (what the AI thinks it is)
///   - Confidence score (how sure the AI is)
///   - Estimated quantity (rough visual estimate)
///   - Position in the image
///
/// This model does NOT contain:
///   - Nutrition values (those come from [TrustedNutritionRepository])
///   - Calculated calories (those come from [NutritionCalculationEngine])
///   - Health classifications (those come from [HealthRuleEngine])
///
/// Recognition confidence ≠ nutrition data confidence.
/// They are tracked separately throughout the pipeline.
class DetectedFood {
  const DetectedFood({
    required this.id,
    required this.name,
    required this.confidenceScore,
    required this.status,
    required this.providerName,
    this.estimatedQuantity = 1.0,
    this.estimatedUnit = ServingUnit.servings,
    this.estimatedServingSizeG,
    this.isQuantityReliable = false,
    this.alternativeSuggestions = const [],
    this.boundingBox,
  });

  /// Unique identifier for this detection (used in lists).
  final String id;

  /// Food name as identified by the recognition system.
  /// This is NOT a guaranteed nutrition data key — it must be looked up
  /// in [TrustedNutritionRepository].
  final String name;

  /// Confidence score from 0.0 to 1.0.
  /// This is the vision model's confidence in the identification —
  /// it is NOT the nutrition data confidence.
  final double confidenceScore;

  /// Derived status based on [confidenceScore].
  final RecognitionStatus status;

  /// Name of the vision provider that produced this result.
  final String providerName;

  /// Visually estimated quantity (e.g., 2 for "2 apples").
  final double estimatedQuantity;

  /// Estimated unit for the quantity.
  final ServingUnit estimatedUnit;

  /// Visually estimated serving size in grams, if determinable.
  /// Null when the portion size cannot be reliably estimated from the image.
  final double? estimatedServingSizeG;

  /// Whether the quantity estimate is considered reliable.
  /// If false, the UI must prompt the user to confirm.
  final bool isQuantityReliable;

  /// Alternative name suggestions if confidence is not high.
  final List<String> alternativeSuggestions;

  /// Image region where the food was detected. May be null.
  final BoundingBox? boundingBox;

  // ── Derived ────────────────────────────────────────────────────────────────

  bool get isHighConfidence => confidenceScore >= 0.80;
  bool get isMediumConfidence =>
      confidenceScore >= 0.50 && confidenceScore < 0.80;
  bool get isLowConfidence => confidenceScore < 0.50;

  bool get hasAlternatives => alternativeSuggestions.isNotEmpty;
  bool get hasBoundingBox => boundingBox != null;
  bool get needsQuantityConfirmation => !isQuantityReliable;

  /// Confidence percentage string for display (e.g., "87%").
  String get confidencePercent =>
      '${(confidenceScore * 100).toStringAsFixed(0)}%';

  // ── Copy-with ──────────────────────────────────────────────────────────────

  DetectedFood copyWith({
    String? name,
    double? estimatedQuantity,
    ServingUnit? estimatedUnit,
    double? estimatedServingSizeG,
    bool? isQuantityReliable,
    double? confidenceScore,
  }) {
    final newConfidence = confidenceScore ?? this.confidenceScore;
    return DetectedFood(
      id: id,
      name: name ?? this.name,
      confidenceScore: newConfidence,
      status: _statusFromConfidence(newConfidence),
      providerName: providerName,
      estimatedQuantity: estimatedQuantity ?? this.estimatedQuantity,
      estimatedUnit: estimatedUnit ?? this.estimatedUnit,
      estimatedServingSizeG:
          estimatedServingSizeG ?? this.estimatedServingSizeG,
      isQuantityReliable: isQuantityReliable ?? this.isQuantityReliable,
      alternativeSuggestions: alternativeSuggestions,
      boundingBox: boundingBox,
    );
  }

  static RecognitionStatus _statusFromConfidence(double score) {
    if (score >= 0.80) return RecognitionStatus.identified;
    if (score >= 0.50) return RecognitionStatus.uncertain;
    if (score > 0) return RecognitionStatus.lowConfidence;
    return RecognitionStatus.unknownFood;
  }

  @override
  String toString() =>
      'DetectedFood(name=$name, confidence=${confidencePercent}, '
      'qty=$estimatedQuantity ${estimatedUnit.label})';
}

// ── Recognition Result ─────────────────────────────────────────────────────────

/// Overall status of a recognition attempt.
enum OverallRecognitionStatus {
  /// One or more foods identified with ≥ medium confidence.
  success,

  /// Foods detected but all are low confidence or uncertain.
  partialDetection,

  /// Image was valid but no food was found.
  noFoodDetected,

  /// Recognition failed due to an error.
  failed,

  /// Image quality was too low for recognition.
  imageTooLow,
}

/// The complete result of a food vision recognition attempt.
///
/// Always check [status] before using [detectedFoods].
class RecognitionResult {
  const RecognitionResult({
    required this.status,
    required this.detectedFoods,
    required this.providerName,
    required this.processingTimeMs,
    this.failureReason,
    this.rawProviderResponse,
  });

  final OverallRecognitionStatus status;
  final List<DetectedFood> detectedFoods;
  final String providerName;
  final int processingTimeMs;

  /// Human-readable failure reason (for logging — never show raw to user).
  final String? failureReason;

  /// Raw JSON from provider (debug mode only, never logged in production).
  final String? rawProviderResponse;

  // ── Derived ────────────────────────────────────────────────────────────────

  bool get isSuccess => status == OverallRecognitionStatus.success;
  bool get isPartial => status == OverallRecognitionStatus.partialDetection;
  bool get hasFoods => detectedFoods.isNotEmpty;
  bool get isFailed => status == OverallRecognitionStatus.failed;

  int get highConfidenceCount =>
      detectedFoods.where((f) => f.isHighConfidence).length;
  int get lowConfidenceCount =>
      detectedFoods.where((f) => f.isLowConfidence).length;

  List<DetectedFood> get usableFoods =>
      detectedFoods.where((f) => f.status.isUsable).toList();

  /// User-facing summary message.
  String get summaryMessage => switch (status) {
        OverallRecognitionStatus.success =>
          '${detectedFoods.length} food${detectedFoods.length == 1 ? '' : 's'} detected',
        OverallRecognitionStatus.partialDetection =>
          'Foods detected with low confidence — please review',
        OverallRecognitionStatus.noFoodDetected =>
          'No food found in the image',
        OverallRecognitionStatus.imageTooLow =>
          'Image quality is too low for food recognition',
        OverallRecognitionStatus.failed =>
          'Recognition failed. Please try again.',
      };

  // ── Named constructors ─────────────────────────────────────────────────────

  factory RecognitionResult.failed({
    required String reason,
    required String providerName,
  }) =>
      RecognitionResult(
        status: OverallRecognitionStatus.failed,
        detectedFoods: const [],
        providerName: providerName,
        processingTimeMs: 0,
        failureReason: reason,
      );

  factory RecognitionResult.noFood({required String providerName}) =>
      RecognitionResult(
        status: OverallRecognitionStatus.noFoodDetected,
        detectedFoods: const [],
        providerName: providerName,
        processingTimeMs: 0,
      );
}

// ── Confirmed Food Item (post-user-edit) ───────────────────────────────────────

/// A food item after the user has confirmed or edited it.
///
/// This is what gets passed to the nutrition pipeline.
/// Derived from [DetectedFood] but may have user-edited name/quantity.
class ConfirmedFoodItem {
  const ConfirmedFoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.servingSizeG,
    this.originalDetection,
  });

  final String id;
  final String name;
  final double quantity;
  final ServingUnit unit;

  /// User-specified or estimated serving size in grams.
  /// Null means "use food database default".
  final double? servingSizeG;

  /// The original detection this was confirmed from.
  /// Null for manually-added items.
  final DetectedFood? originalDetection;

  bool get isManuallyAdded => originalDetection == null;

  /// Converts quantity + unit to total grams for the nutrition pipeline.
  ///
  /// Returns null for food-dependent units (pieces, servings) where
  /// the caller must use the food database's default serving size.
  double? get totalGramsIfKnown {
    final equiv = unit.gramsEquivalent;
    if (equiv == null) return null;
    return quantity * equiv;
  }

  /// Returns the effective serving size in grams.
  /// Uses [servingSizeG] if set, then unit-based conversion, then null.
  double? get effectiveServingSizeG => servingSizeG ?? unit.gramsEquivalent;

  @override
  String toString() => 'ConfirmedFoodItem(name=$name, qty=$quantity ${unit.label})';
}

// ── Image info ─────────────────────────────────────────────────────────────────

/// Metadata about the image being processed (no raw bytes stored here).
class FoodImageInfo {
  const FoodImageInfo({
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.source,
  });

  final int sizeBytes;
  final int width;
  final int height;
  final String mimeType;
  final ImageSource source;

  bool get isValid => sizeBytes > 0 && width > 0 && height > 0;

  String get sizeMb => '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

enum ImageSource { camera, gallery }
