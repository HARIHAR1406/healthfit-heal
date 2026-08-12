import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/detected_food.dart';

/// Card showing a single detected food item with editable fields.
///
/// Used in [FoodDetectionPage] during the user confirmation step.
/// Exposes callbacks for name edit, quantity edit, unit change, and removal.
class DetectedFoodCard extends StatefulWidget {
  const DetectedFoodCard({
    required this.item,
    required this.onNameChanged,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onRemove,
    super.key,
  });

  final ConfirmedFoodItem item;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<ServingUnit> onUnitChanged;
  final VoidCallback onRemove;

  @override
  State<DetectedFoodCard> createState() => _DetectedFoodCardState();
}

class _DetectedFoodCardState extends State<DetectedFoodCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController =
        TextEditingController(text: _formatQty(widget.item.quantity));
  }

  @override
  void didUpdateWidget(DetectedFoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingName && widget.item.name != oldWidget.item.name) {
      _nameController.text = widget.item.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detection = widget.item.originalDetection;
    final confidence = detection?.confidenceScore;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: _borderColor(context, confidence),
          width: 1.2,
        ),
      ),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                // Confidence badge
                if (confidence != null)
                  _ConfidenceBadge(confidence: confidence),
                if (widget.item.isManuallyAdded)
                  _ManualBadge(isDark: isDark),
                const Spacer(),
                // Remove button
                InkWell(
                  onTap: widget.onRemove,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Food name ──────────────────────────────────────────────────
            _NameField(
              controller: _nameController,
              isDark: isDark,
              isEditing: _isEditingName,
              onTap: () => setState(() => _isEditingName = true),
              onSubmitted: (v) {
                setState(() => _isEditingName = false);
                if (v.trim().isNotEmpty) widget.onNameChanged(v.trim());
              },
              onEditDone: () {
                setState(() => _isEditingName = false);
                final v = _nameController.text;
                if (v.trim().isNotEmpty) widget.onNameChanged(v.trim());
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Quantity row ────────────────────────────────────────────────
            Row(
              children: [
                // Quantity input
                _QuantityField(
                  controller: _quantityController,
                  isDark: isDark,
                  onSubmitted: (v) {
                    final qty = double.tryParse(v);
                    if (qty != null && qty > 0) widget.onQuantityChanged(qty);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                // Unit picker
                _UnitPicker(
                  selectedUnit: widget.item.unit,
                  isDark: isDark,
                  onChanged: widget.onUnitChanged,
                ),
              ],
            ),

            // ── Quantity warning ────────────────────────────────────────────
            if (detection?.needsQuantityConfirmation ?? false) ...[
              const SizedBox(height: AppSpacing.xs),
              _QuantityWarning(isDark: isDark),
            ],

            // ── Alternative suggestions ────────────────────────────────────
            if (detection?.hasAlternatives ?? false) ...[
              const SizedBox(height: AppSpacing.sm),
              _AlternativeSuggestions(
                alternatives: detection!.alternativeSuggestions,
                onSelect: (name) {
                  _nameController.text = name;
                  widget.onNameChanged(name);
                },
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _borderColor(BuildContext context, double? confidence) {
    if (confidence == null) return AppColors.dividerLight.withOpacity(0.5);
    if (confidence >= 0.80) return AppColors.success.withOpacity(0.6);
    if (confidence >= 0.50) return AppColors.warning.withOpacity(0.6);
    return AppColors.error.withOpacity(0.6);
  }

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(1);
  }
}

// ── Confidence Badge ───────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '  ${(confidence * 100).toStringAsFixed(0)}%',
            style: AppTypography.labelSmall.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _info(double c) {
    if (c >= 0.80) return (AppColors.success, 'High');
    if (c >= 0.50) return (AppColors.warning, 'Medium');
    return (AppColors.error, 'Low');
  }
}

class _ManualBadge extends StatelessWidget {
  const _ManualBadge({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
      ),
      child: Text(
        'Manual',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Name Field ─────────────────────────────────────────────────────────────────

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.isDark,
    required this.isEditing,
    required this.onTap,
    required this.onSubmitted,
    required this.onEditDone,
  });

  final TextEditingController controller;
  final bool isDark;
  final bool isEditing;
  final VoidCallback onTap;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onEditDone;

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    if (!isEditing) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.text,
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ],
        ),
      );
    }

    return TextField(
      controller: controller,
      autofocus: true,
      style: AppTypography.titleMedium.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        hintText: 'Enter food name',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? AppColors.textHintDark
              : AppColors.textHintLight,
        ),
        border: const UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.check, size: 18),
          onPressed: onEditDone,
          color: AppColors.primary,
        ),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
    );
  }
}

// ── Quantity Field ─────────────────────────────────────────────────────────────

class _QuantityField extends StatelessWidget {
  const _QuantityField({
    required this.controller,
    required this.isDark,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceDark.withOpacity(0.5)
              : AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

// ── Unit Picker ────────────────────────────────────────────────────────────────

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({
    required this.selectedUnit,
    required this.isDark,
    required this.onChanged,
  });

  final ServingUnit selectedUnit;
  final bool isDark;
  final ValueChanged<ServingUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DropdownButtonFormField<ServingUnit>(
        value: selectedUnit,
        isExpanded: true,
        isDense: true,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: isDark
              ? AppColors.surfaceDark.withOpacity(0.5)
              : AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        items: ServingUnit.values
            .map((u) => DropdownMenuItem(
                  value: u,
                  child: Text(u.fullLabel),
                ))
            .toList(),
        onChanged: (u) {
          if (u != null) onChanged(u);
        },
      ),
    );
  }
}

// ── Quantity Warning ───────────────────────────────────────────────────────────

class _QuantityWarning extends StatelessWidget {
  const _QuantityWarning({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Quantity could not be reliably estimated. Please confirm.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alternative Suggestions ────────────────────────────────────────────────────

class _AlternativeSuggestions extends StatelessWidget {
  const _AlternativeSuggestions({
    required this.alternatives,
    required this.onSelect,
    required this.isDark,
  });

  final List<String> alternatives;
  final ValueChanged<String> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Did you mean:',
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: AppSpacing.xs,
          children: alternatives
              .take(3)
              .map((alt) => ActionChip(
                    label: Text(
                      alt,
                      style: AppTypography.labelSmall,
                    ),
                    onPressed: () => onSelect(alt),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: AppColors.tertiary.withOpacity(0.4),
                    ),
                    backgroundColor:
                        AppColors.tertiary.withOpacity(0.08),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Add Food Sheet ─────────────────────────────────────────────────────────────

/// Bottom sheet for manually adding a food item.
class AddFoodManuallySheet extends StatefulWidget {
  const AddFoodManuallySheet({super.key});

  @override
  State<AddFoodManuallySheet> createState() => _AddFoodManuallySheetState();
}

class _AddFoodManuallySheetState extends State<AddFoodManuallySheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  ServingUnit _unit = ServingUnit.servings;
  bool _hasError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            'Add Food Manually',
            style: AppTypography.titleLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
            decoration: InputDecoration(
              labelText: 'Food name',
              hintText: 'e.g. Apple, Brown Rice, Grilled Chicken',
              errorText: _hasError ? 'Please enter a food name' : null,
              prefixIcon: const Icon(Icons.restaurant_outlined),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_hasError) setState(() => _hasError = false);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Quantity + Unit
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: AppTypography.bodyMedium.copyWith(color: textColor),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<ServingUnit>(
                  value: _unit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: ServingUnit.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.fullLabel),
                          ))
                      .toList(),
                  onChanged: (u) {
                    if (u != null) setState(() => _unit = u);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Add button
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightMd,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add to Meal'),
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    final qty = double.tryParse(_quantityController.text) ?? 1.0;
    Navigator.of(context).pop({
      'name': name,
      'quantity': qty,
      'unit': _unit,
    });
  }
}
