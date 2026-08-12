import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/export_request_entity.dart';
import '../providers/reports_providers.dart';
import '../providers/reports_state.dart';
import '../widgets/health_score_ring.dart';

// ══════════════════════════════════════════════════════════════════════════════
// EXPORT CENTER PAGE
// ══════════════════════════════════════════════════════════════════════════════

/// Export Center with format tiles (PDF, CSV, Excel) and scope selection.
///
/// No actual file I/O is implemented. The export notifier simulates a
/// 1.5s processing delay and resolves with a success state.
class ExportCenterPage extends ConsumerStatefulWidget {
  const ExportCenterPage({super.key});

  @override
  ConsumerState<ExportCenterPage> createState() => _ExportCenterPageState();
}

class _ExportCenterPageState extends ConsumerState<ExportCenterPage> {
  ExportScope _selectedScope = ExportScope.full;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exportState = ref.watch(exportProvider);
    final filterLabel = ref.watch(filterLabelProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Export Center',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Hero Banner ──────────────────────────────────────────────────
          _ExportHeroBanner(isDark: isDark, filterLabel: filterLabel),
          const SizedBox(height: AppSpacing.xl),

          // ── Scope Selector ───────────────────────────────────────────────
          Text(
            'Select Report Scope',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScopeSelector(
            selectedScope: _selectedScope,
            isDark: isDark,
            onChanged: (s) => setState(() => _selectedScope = s),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Format Grid ──────────────────────────────────────────────────
          Text(
            'Choose Export Format',
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.1,
            children: [
              ExportCard(
                title: 'PDF Report',
                description:
                    'Full visual report with charts and insights',
                icon: Icons.picture_as_pdf_rounded,
                color: AppColors.secondary,
                badge: 'POPULAR',
                isDark: isDark,
                isLoading: exportState is ExportInProgress &&
                    exportState.request.format == ExportFormat.pdf,
                onTap: () => _requestExport(ExportFormat.pdf, filterLabel),
              ),
              ExportCard(
                title: 'CSV Data',
                description:
                    'Raw data export for spreadsheet analysis',
                icon: Icons.table_chart_rounded,
                color: AppColors.primary,
                isDark: isDark,
                isLoading: exportState is ExportInProgress &&
                    exportState.request.format == ExportFormat.csv,
                onTap: () => _requestExport(ExportFormat.csv, filterLabel),
              ),
              ExportCard(
                title: 'Excel Report',
                description:
                    'Formatted Excel workbook with pivot tables',
                icon: Icons.grid_on_rounded,
                color: AppColors.success,
                isDark: isDark,
                isLoading: exportState is ExportInProgress &&
                    exportState.request.format == ExportFormat.excel,
                onTap: () =>
                    _requestExport(ExportFormat.excel, filterLabel),
              ),
              ExportCard(
                title: 'Quick Summary',
                description: 'One-page snapshot for sharing',
                icon: Icons.summarize_rounded,
                color: AppColors.tertiary,
                isDark: isDark,
                isLoading: false,
                onTap: () =>
                    _requestExport(ExportFormat.pdf, filterLabel),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Export Status ────────────────────────────────────────────────
          _ExportStatusSection(
              state: exportState, isDark: isDark),
          const SizedBox(height: AppSpacing.xl),

          // ── Disclaimer ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border:
                  Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.info, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Export functionality is a preview. Actual file download '
                    'will be available in the next release. Reports are '
                    'generated on-device and never uploaded to external servers.',
                    style: AppTypography.captionText.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }

  Future<void> _requestExport(
      ExportFormat format, String dateRangeLabel) async {
    await ref.read(exportProvider.notifier).requestExport(
          format: format,
          scope: _selectedScope,
          dateRangeLabel: dateRangeLabel,
        );
  }
}

// ── Hero Banner ───────────────────────────────────────────────────────────────

class _ExportHeroBanner extends StatelessWidget {
  const _ExportHeroBanner({required this.isDark, required this.filterLabel});
  final bool isDark;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A4A), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Your Health Data',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Generate detailed reports for period: $filterLabel',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _FeaturePill(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'PDF'),
                    const SizedBox(width: AppSpacing.xs),
                    _FeaturePill(
                        icon: Icons.table_chart_rounded, label: 'CSV'),
                    const SizedBox(width: AppSpacing.xs),
                    _FeaturePill(
                        icon: Icons.grid_on_rounded, label: 'Excel'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.download_rounded,
              size: 52, color: AppColors.primary.withOpacity(0.5)),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.captionText.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scope Selector ────────────────────────────────────────────────────────────

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({
    required this.selectedScope,
    required this.isDark,
    required this.onChanged,
  });
  final ExportScope selectedScope;
  final bool isDark;
  final ValueChanged<ExportScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ExportScope.values.map((scope) {
        final isActive = scope == selectedScope;
        return GestureDetector(
          onTap: () => onChanged(scope),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.06)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Text(
              '${scope.emoji} ${scope.label}',
              style: AppTypography.labelSmall.copyWith(
                color: isActive
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.primary),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Export Status ─────────────────────────────────────────────────────────────

class _ExportStatusSection extends StatelessWidget {
  const _ExportStatusSection(
      {required this.state, required this.isDark});
  final ExportState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ExportIdle() => const SizedBox.shrink(),
      ExportInProgress(:final request) => _StatusCard(
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warning,
          title: 'Generating Report…',
          subtitle:
              '${request.format.label} — ${request.scope.label}',
          isDark: isDark,
          showProgress: true,
        ),
      ExportSuccess(:final request) => _StatusCard(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'Export Ready!',
          subtitle:
              '${request.format.label} · ${request.scope.label} · '
              'Generated at ${_fmt(request.completedAt ?? DateTime.now())}',
          isDark: isDark,
          showProgress: false,
        ),
      ExportFailure(:final message) => _StatusCard(
          icon: Icons.error_rounded,
          color: AppColors.error,
          title: 'Export Failed',
          subtitle: message,
          isDark: isDark,
          showProgress: false,
        ),
    };
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.showProgress,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          showProgress
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      color: color, strokeWidth: 2.5),
                )
              : Icon(icon, color: color, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.captionText.copyWith(
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

