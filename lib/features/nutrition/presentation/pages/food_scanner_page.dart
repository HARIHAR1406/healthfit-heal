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

/// Entry point for the Food Scanner feature.
///
/// Provides two paths to the recognition pipeline:
///   1. Camera — captures a new photo
///   2. Gallery — selects an existing image
///
/// Navigation:
///   - On successful detection → [FoodDetectionPage]
///   - On no food found → [FoodDetectionPage] (with empty list + retry)
///   - On permission denied → shows in-page error with settings guidance
///   - On other errors → in-page error with retry button
class FoodScannerPage extends ConsumerStatefulWidget {
  const FoodScannerPage({super.key});

  @override
  ConsumerState<FoodScannerPage> createState() => _FoodScannerPageState();
}

class _FoodScannerPageState extends ConsumerState<FoodScannerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(foodScannerProvider);

    // Listen for state changes and navigate
    ref.listen<FoodScannerState>(foodScannerProvider, (prev, next) {
      if (!mounted) return;

      switch (next) {
        case FoodScannerDetected(
            :final detectedFoods,
            :final imageBytes,
            :final providerName
          ):
          context.push(
            RouteNames.foodDetection,
            extra: {
              'detectedFoods': detectedFoods,
              'imageBytes': imageBytes,
              'providerName': providerName,
            },
          );

        case FoodScannerNoFoodFound(:final imageBytes, :final providerName):
          context.push(
            RouteNames.foodDetection,
            extra: {
              'detectedFoods': <DetectedFood>[],
              'imageBytes': imageBytes,
              'providerName': providerName,
              'noFoodDetected': true,
            },
          );

        default:
          break;
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
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scan Food',
          style: AppTypography.titleLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (state) {
        FoodScannerInitial() => _IdleBody(
            isDark: isDark,
            pulseAnimation: _pulseAnimation,
          ),
        FoodScannerSelectingSource() => const _LoadingBody(
            message: 'Opening...',
          ),
        FoodScannerProcessingImage() => const _LoadingBody(
            message: 'Processing image...',
          ),
        FoodScannerRecognizing() => const _LoadingBody(
            message: 'Analyzing food...',
            showProgress: true,
          ),
        FoodScannerError(:final userMessage, :final type) => _ErrorBody(
            message: userMessage,
            type: type,
            isDark: isDark,
          ),
        _ => const _LoadingBody(message: 'Working...'),
      },
    );
  }
}

// ── Idle Body ──────────────────────────────────────────────────────────────────

class _IdleBody extends ConsumerWidget {
  const _IdleBody({
    required this.isDark,
    required this.pulseAnimation,
  });

  final bool isDark;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMock = ref.watch(isVisionMockProvider);
    final providerName = ref.watch(visionProviderNameProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const Spacer(),

            // ── Hero icon ──────────────────────────────────────────────────
            ScaleTransition(
              scale: pulseAnimation,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_enhance_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Title ──────────────────────────────────────────────────────
            Text(
              'AI Food Vision',
              style: AppTypography.headlineMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Take a photo or select an image to instantly '
              'identify foods and calculate trusted nutrition.',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ── Action buttons ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () =>
                        ref.read(foodScannerProvider.notifier).pickFromCamera(),
                    isDark: isDark,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () =>
                        ref.read(foodScannerProvider.notifier).pickFromGallery(),
                    isDark: isDark,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Tips ───────────────────────────────────────────────────────
            _TipsCard(isDark: isDark),
            const SizedBox(height: AppSpacing.sm),

            // ── Provider badge (mock indicator) ────────────────────────────
            if (isMock)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 12, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      'Demo mode — $providerName',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Source Button ──────────────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        height: AppSpacing.buttonHeightMd,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(label, style: AppTypography.buttonText),
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: AppSpacing.buttonHeightMd,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label, style: AppTypography.buttonText),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

// ── Tips Card ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withOpacity(0.5)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Best results: good lighting, food in frame, close-up shot',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading Body ───────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({
    required this.message,
    this.showProgress = false,
  });

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgress)
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
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
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == ScannerErrorType.permissionDenied
                  ? Icons.no_photography_outlined
                  : Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              type == ScannerErrorType.permissionDenied ? 'Permission Required' : 'Something went wrong',
              style: AppTypography.titleLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: secondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              type.recoveryAction,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (type.isRecoverable)
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightMd,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  onPressed: () =>
                      ref.read(foodScannerProvider.notifier).reset(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

