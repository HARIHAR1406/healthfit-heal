import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/detected_food.dart';
import '../providers/food_scanner_providers.dart';
import '../providers/food_scanner_state.dart';
import '../widgets/detected_food_card.dart';

/// Food confirmation and editing page.
///
/// Shows all detected foods as editable cards. The user must confirm,
/// edit, remove, or add items before the nutrition pipeline runs.
///
/// Only confirmed items proceed to [FoodScanResultPage].
///
/// Navigation flow:
///   [FoodScannerPage] → [FoodDetectionPage] → [FoodScanResultPage]
class FoodDetectionPage extends ConsumerStatefulWidget {
  const FoodDetectionPage({
    required this.detectedFoods,
    required this.imageBytes,
    required this.providerName,
    this.noFoodDetected = false,
    super.key,
  });

  final List<DetectedFood> detectedFoods;
  final Uint8List imageBytes;
  final String providerName;
  final bool noFoodDetected;

  @override
  ConsumerState<FoodDetectionPage> createState() => _FoodDetectionPageState();
}

class _FoodDetectionPageState extends ConsumerState<FoodDetectionPage> {
  @override
  void initState() {
    super.initState();
    // Initialize the confirming state with detected foods
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.noFoodDetected) {
        ref
            .read(foodScannerProvider.notifier)
            .proceedToConfirmationFromNoFood(widget.imageBytes);
      } else {
        ref
            .read(foodScannerProvider.notifier)
            .proceedToConfirmation(widget.detectedFoods, widget.imageBytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(foodScannerProvider);

    // Navigate to result page when calculation completes
    ref.listen<FoodScannerState>(foodScannerProvider, (prev, next) {
      if (!mounted) return;
      if (next is FoodScannerResult) {
        context.push(
          RouteNames.foodScanResult,
          extra: {
            'imageBytes': next.imageBytes,
            'confirmedItems': next.confirmedItems,
            'mealResult': next.mealResult,
            'recommendation': next.recommendation,
            'context': next.context,
          },
        );
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          onPressed: () {
            ref.read(foodScannerProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(
          'Detected Foods',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Retry analysis
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            tooltip: 'Retry scan',
            onPressed: () {
              ref.read(foodScannerProvider.notifier).retryRecognition();
              context.pop();
            },
          ),
        ],
      ),
      body: switch (state) {
        FoodScannerCalculating() => const _CalculatingOverlay(),
        FoodScannerError(:final userMessage, :final type) =>
          _ErrorBody(message: userMessage, type: type, isDark: isDark),
        _ => _Body(
            isDark: isDark,
            imageBytes: widget.imageBytes,
            noFoodDetected: widget.noFoodDetected,
            providerName: widget.providerName,
          ),
      },
    );
  }
}

// ── Main Body ──────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({
    required this.isDark,
    required this.imageBytes,
    required this.noFoodDetected,
    required this.providerName,
  });

  final bool isDark;
  final Uint8List imageBytes;
  final bool noFoodDetected;
  final String providerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodScannerProvider);
    final items = state is FoodScannerConfirming ? state.items : <ConfirmedFoodItem>[];
    final canProceed = items.isNotEmpty;

    return SafeArea(
      child: Column(
        children: [
          // ── Image thumbnail ──────────────────────────────────────────────
          _ImageThumbnail(imageBytes: imageBytes, isDark: isDark),

          // ── Scrollable food list ─────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // No food detected header
                      if (noFoodDetected)
                        _NoFoodBanner(isDark: isDark),

                      // Provider info
                      _ProviderRow(
                        providerName: providerName,
                        count: items.length,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Food cards
                      if (items.isEmpty && !noFoodDetected)
                        _EmptyState(isDark: isDark),

                      ...items.map((item) => DetectedFoodCard(
                            key: ValueKey(item.id),
                            item: item,
                            onNameChanged: (name) => ref
                                .read(foodScannerProvider.notifier)
                                .updateFoodName(item.id, name),
                            onQuantityChanged: (qty) => ref
                                .read(foodScannerProvider.notifier)
                                .updateQuantity(item.id, qty),
                            onUnitChanged: (unit) => ref
                                .read(foodScannerProvider.notifier)
                                .updateUnit(item.id, unit),
                            onRemove: () => ref
                                .read(foodScannerProvider.notifier)
                                .removeFood(item.id),
                          )),

                      const SizedBox(height: AppSpacing.sm),

                      // Add manually button
                      _AddManuallyButton(isDark: isDark),
                      const SizedBox(height: AppSpacing.md),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom action bar ────────────────────────────────────────────
          _BottomBar(
            canProceed: canProceed,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ── Image Thumbnail ────────────────────────────────────────────────────────────

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.imageBytes, required this.isDark});
  final Uint8List imageBytes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: const Icon(Icons.broken_image_outlined,
              size: 40, color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}

// ── Provider Row ───────────────────────────────────────────────────────────────

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.providerName,
    required this.count,
    required this.isDark,
  });

  final String providerName;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(
      children: [
        Icon(Icons.auto_awesome_outlined, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$count item${count != 1 ? 's' : ''} detected by $providerName',
            style: AppTypography.bodySmall.copyWith(color: secondaryColor),
          ),
        ),
      ],
    );
  }
}

// ── No Food Banner ─────────────────────────────────────────────────────────────

class _NoFoodBanner extends StatelessWidget {
  const _NoFoodBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.no_food_outlined, size: 24, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No food detected',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Try a clearer photo, or add foods manually below.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'All items removed',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            'Add foods manually below to continue.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Manually Button ────────────────────────────────────────────────────────

class _AddManuallyButton extends ConsumerWidget {
  const _AddManuallyButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Food Manually'),
      onPressed: () async {
        final result = await showModalBottomSheet<Map<String, dynamic>?>(
          context: context,
          isScrollControlled: true,
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const AddFoodManuallySheet(),
        );

        if (result != null && context.mounted) {
          ref.read(foodScannerProvider.notifier).addFoodManually(
                name: result['name'] as String,
                quantity: result['quantity'] as double,
                unit: result['unit'] as ServingUnit,
              );
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightMd),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── Bottom Bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.canProceed, required this.isDark});
  final bool canProceed;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeightMd,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calculate_outlined),
            label: Text(
              canProceed ? 'Calculate Nutrition' : 'Add foods to continue',
              style: AppTypography.buttonText,
            ),
            onPressed: canProceed
                ? () => ref.read(foodScannerProvider.notifier).calculateNutrition()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: isDark
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Calculating Overlay ────────────────────────────────────────────────────────

class _CalculatingOverlay extends StatelessWidget {
  const _CalculatingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Calculating nutrition...',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Checking trusted food database',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Body ─────────────────────────────────────────────────────────────────

class _ErrorBody extends ConsumerWidget {
  const _ErrorBody({
    required this.message,
    required this.type,
    required this.isDark,
  });

  final String message;
  final ScannerErrorType type;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            type.recoveryAction,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (type.isRecoverable)
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightMd,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(foodScannerProvider.notifier).reset();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
        ],
      ),
    );
  }
}
