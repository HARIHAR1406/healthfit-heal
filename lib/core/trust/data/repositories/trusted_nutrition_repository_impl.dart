import '../../../utils/app_logger.dart';
import '../../domain/entities/verified_nutrition.dart';
import '../../domain/repositories/trusted_nutrition_repository.dart';
import '../datasources/local_nutrition_datasource.dart';

/// Production implementation of [TrustedNutritionRepository].
///
/// ── Data source strategy ──────────────────────────────────────────────────────
/// Phase 12: Local-only (in-memory seed + session cache via [LocalNutritionDataSource]).
/// Phase 13+: Will add a [RemoteNutritionDataSource] with the following priority:
///
///   1. Check local Hive cache (< 24 hours old → use cached)
///   2. Fetch from remote API (USDA / Open Food Facts)
///   3. Fall back to local seed data
///   4. Return null if all fail — NEVER return fabricated data
///
/// ── Null contract ─────────────────────────────────────────────────────────────
/// All methods return null when data is genuinely unavailable.
/// Callers MUST treat null as "data unavailable" — never as zero.
///
/// ── No PII ────────────────────────────────────────────────────────────────────
/// Only nutrition data (no user health data, no tokens) flows through this class.
class TrustedNutritionRepositoryImpl implements TrustedNutritionRepository {
  TrustedNutritionRepositoryImpl({
    LocalNutritionDataSource? localDataSource,
  }) : _local = localDataSource ?? LocalNutritionDataSource();

  final LocalNutritionDataSource _local;

  @override
  Future<VerifiedNutrition?> getById(String foodId) async {
    try {
      return await _local.getById(foodId);
    } catch (e, st) {
      log.error(
        'TrustedNutritionRepository: getById("$foodId") failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<List<VerifiedNutrition>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return const [];
    try {
      return await _local.search(query, limit: limit);
    } catch (e, st) {
      log.error(
        'TrustedNutritionRepository: search("$query") failed',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  @override
  Future<VerifiedNutrition?> getByBarcode(String barcode) async {
    try {
      return await _local.getByBarcode(barcode);
    } catch (e, st) {
      log.error(
        'TrustedNutritionRepository: getByBarcode("$barcode") failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<List<VerifiedNutrition>> getByCategory(
    String category, {
    int limit = 50,
  }) async {
    try {
      return await _local.getByCategory(category, limit: limit);
    } catch (e, st) {
      log.error(
        'TrustedNutritionRepository: getByCategory("$category") failed',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  @override
  Future<List<VerifiedNutrition>> getRecentlyAccessed({int limit = 20}) async {
    try {
      return await _local.getRecentlyAccessed(limit: limit);
    } catch (e, st) {
      log.error(
        'TrustedNutritionRepository: getRecentlyAccessed failed',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  @override
  Future<void> cache(VerifiedNutrition nutrition) async {
    try {
      await _local.cache(nutrition);
    } catch (e, st) {
      log.warning(
        'TrustedNutritionRepository: cache("${nutrition.foodName}") failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _local.clearCache();
    } catch (e, st) {
      log.warning(
        'TrustedNutritionRepository: clearCache failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<int> getCachedCount() async {
    try {
      return _local.count;
    } catch (e) {
      return 0;
    }
  }
}
