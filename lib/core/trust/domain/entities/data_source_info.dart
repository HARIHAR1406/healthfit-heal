/// Identifies where a piece of nutrition data came from
/// and how trustworthy it is.
///
/// Used across all Trust layer entities to enable the UI and AI
/// to clearly distinguish measured vs. estimated vs. cached data.

// ── Source Type ────────────────────────────────────────────────────────────────

/// The origin of a nutrition data point.
enum DataSourceType {
  /// USDA FoodData Central — highly authoritative.
  usdaFoodData,

  /// Open Food Facts crowd-sourced database.
  openFoodFacts,

  /// Nutritionix commercial database.
  nutritionix,

  /// Manually entered by the user.
  userEntered,

  /// Derived by calculation from other verified values.
  calculated,

  /// Internal application seed data (curated, reviewed).
  appSeedData,

  /// External API not yet categorised.
  externalApi,

  /// Source is unknown — low confidence.
  unknown,
}

extension DataSourceTypeX on DataSourceType {
  /// Human-readable label safe to display in the UI.
  String get label => switch (this) {
        DataSourceType.usdaFoodData => 'USDA FoodData Central',
        DataSourceType.openFoodFacts => 'Open Food Facts',
        DataSourceType.nutritionix => 'Nutritionix',
        DataSourceType.userEntered => 'User Entered',
        DataSourceType.calculated => 'Calculated',
        DataSourceType.appSeedData => 'Verified App Database',
        DataSourceType.externalApi => 'External Database',
        DataSourceType.unknown => 'Unknown Source',
      };

  /// Whether this source is considered authoritative enough for
  /// health-critical recommendations.
  bool get isAuthoritative => switch (this) {
        DataSourceType.usdaFoodData => true,
        DataSourceType.openFoodFacts => true,
        DataSourceType.nutritionix => true,
        DataSourceType.appSeedData => true,
        DataSourceType.calculated => true,
        DataSourceType.userEntered => false,
        DataSourceType.externalApi => false,
        DataSourceType.unknown => false,
      };
}

// ── Verification Status ────────────────────────────────────────────────────────

/// Whether the data has been verified against a trusted source.
enum VerificationStatus {
  /// Verified against an authoritative data source.
  verified,

  /// Data exists but has not been cross-checked.
  unverified,

  /// Pending verification — submitted but not yet confirmed.
  pending,

  /// Data was present but is now stale (cache too old).
  stale,

  /// Data could not be verified — source was unavailable.
  unavailable,
}

extension VerificationStatusX on VerificationStatus {
  bool get isUsable =>
      this == VerificationStatus.verified ||
      this == VerificationStatus.unverified;

  String get label => switch (this) {
        VerificationStatus.verified => 'Verified',
        VerificationStatus.unverified => 'Unverified',
        VerificationStatus.pending => 'Pending Verification',
        VerificationStatus.stale => 'Stale Data',
        VerificationStatus.unavailable => 'Data Unavailable',
      };
}

// ── Data Source Info ───────────────────────────────────────────────────────────

/// Provenance metadata attached to any trusted data value.
///
/// This is immutable — updating provenance requires creating a new instance.
class DataSourceInfo {
  const DataSourceInfo({
    required this.sourceType,
    required this.verificationStatus,
    required this.confidenceScore,
    this.sourceName,
    this.sourceUrl,
    this.lastUpdated,
    this.externalId,
  })  : assert(
          confidenceScore >= 0.0 && confidenceScore <= 1.0,
          'confidenceScore must be between 0.0 and 1.0',
        );

  /// The type of data source.
  final DataSourceType sourceType;

  /// Verification status of this data point.
  final VerificationStatus verificationStatus;

  /// Confidence in the data accuracy: 0.0 (none) → 1.0 (fully verified).
  final double confidenceScore;

  /// Human-readable source name (e.g. "USDA SR Legacy").
  final String? sourceName;

  /// URL or URI pointing to the original source record.
  final String? sourceUrl;

  /// When the data was last fetched / verified.
  final DateTime? lastUpdated;

  /// ID in the external system (e.g. USDA fdcId).
  final String? externalId;

  // ── Convenience constructors ────────────────────────────────────────────────

  /// Creates provenance for app seed data — high confidence, no external URL.
  const DataSourceInfo.appSeed()
      : sourceType = DataSourceType.appSeedData,
        verificationStatus = VerificationStatus.verified,
        confidenceScore = 0.90,
        sourceName = 'HealthFit Heal Verified Database',
        sourceUrl = null,
        lastUpdated = null,
        externalId = null;

  /// Creates provenance for user-entered data — low confidence, unverified.
  const DataSourceInfo.userEntered()
      : sourceType = DataSourceType.userEntered,
        verificationStatus = VerificationStatus.unverified,
        confidenceScore = 0.50,
        sourceName = 'User Input',
        sourceUrl = null,
        lastUpdated = null,
        externalId = null;

  /// Creates provenance for a calculated value.
  const DataSourceInfo.calculated()
      : sourceType = DataSourceType.calculated,
        verificationStatus = VerificationStatus.verified,
        confidenceScore = 1.0,
        sourceName = 'Derived by Calculation',
        sourceUrl = null,
        lastUpdated = null,
        externalId = null;

  /// Creates provenance for unknown/missing data — lowest confidence.
  const DataSourceInfo.unknown()
      : sourceType = DataSourceType.unknown,
        verificationStatus = VerificationStatus.unavailable,
        confidenceScore = 0.0,
        sourceName = null,
        sourceUrl = null,
        lastUpdated = null,
        externalId = null;

  // ── Derived ────────────────────────────────────────────────────────────────

  /// Whether this data is trustworthy enough to use in a recommendation.
  bool get isTrustworthy =>
      verificationStatus.isUsable &&
      confidenceScore >= 0.50 &&
      sourceType.isAuthoritative;

  /// Whether this data is high-confidence (≥ 0.80).
  bool get isHighConfidence => confidenceScore >= 0.80;

  /// Formatted confidence percentage for display (e.g. "90%").
  String get confidenceLabel =>
      '${(confidenceScore * 100).toStringAsFixed(0)}%';

  @override
  String toString() =>
      'DataSourceInfo(source=${sourceType.name}, '
      'status=${verificationStatus.name}, '
      'confidence=$confidenceLabel)';
}
