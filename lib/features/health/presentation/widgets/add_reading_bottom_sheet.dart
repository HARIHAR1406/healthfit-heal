import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/blood_sugar_entity.dart';
import '../providers/health_notifier.dart';
import '../providers/health_providers.dart';

/// Modal bottom sheet for adding a new health reading.
///
/// Handles:
///   - Blood Pressure (systolic / diastolic / pulse)
///   - Blood Sugar (value / type selector)
///   - SpO₂ (percentage)
enum AddReadingType { bloodPressure, bloodSugar, spo2 }

class AddReadingBottomSheet extends ConsumerStatefulWidget {
  const AddReadingBottomSheet({required this.type, super.key});

  final AddReadingType type;

  static Future<void> show(BuildContext context, AddReadingType type) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReadingBottomSheet(type: type),
    );
  }

  @override
  ConsumerState<AddReadingBottomSheet> createState() =>
      _AddReadingBottomSheetState();
}

class _AddReadingBottomSheetState
    extends ConsumerState<AddReadingBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  // BP fields
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();

  // Sugar fields
  final _sugarCtrl = TextEditingController();
  BloodSugarType _sugarType = BloodSugarType.fasting;

  // SpO2 fields
  final _spo2Ctrl = TextEditingController();

  // Notes
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _sugarCtrl.dispose();
    _spo2Ctrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(healthNotifierProvider.notifier);

    try {
      switch (widget.type) {
        case AddReadingType.bloodPressure:
          await notifier.addBpReading(
            systolic: int.parse(_systolicCtrl.text.trim()),
            diastolic: int.parse(_diastolicCtrl.text.trim()),
            pulse: _pulseCtrl.text.isNotEmpty
                ? int.parse(_pulseCtrl.text.trim())
                : null,
            notes: _notesCtrl.text.trim().isNotEmpty
                ? _notesCtrl.text.trim()
                : null,
          );
        case AddReadingType.bloodSugar:
          await notifier.addSugarReading(
            value: double.parse(_sugarCtrl.text.trim()),
            type: _sugarType,
            notes: _notesCtrl.text.trim().isNotEmpty
                ? _notesCtrl.text.trim()
                : null,
          );
        case AddReadingType.spo2:
          await notifier.addSpo2Reading(
            percentage: int.parse(_spo2Ctrl.text.trim()),
          );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomPad,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              _title,
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Form fields
            ..._buildFields(isDark),

            const SizedBox(height: AppSpacing.md),

            // Notes field
            _Field(
              controller: _notesCtrl,
              label: 'Notes (optional)',
              hint: 'Add any relevant notes…',
              keyboardType: TextInputType.text,
              isDark: isDark,
              required: false,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Save Reading',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (widget.type) {
        AddReadingType.bloodPressure => 'Add Blood Pressure',
        AddReadingType.bloodSugar => 'Add Blood Sugar',
        AddReadingType.spo2 => 'Add SpO₂ Reading',
      };

  List<Widget> _buildFields(bool isDark) {
    return switch (widget.type) {
      AddReadingType.bloodPressure => [
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: _systolicCtrl,
                  label: 'Systolic',
                  hint: '120',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  validator: _intValidator(60, 250),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Field(
                  controller: _diastolicCtrl,
                  label: 'Diastolic',
                  hint: '80',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  validator: _intValidator(30, 150),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Field(
                  controller: _pulseCtrl,
                  label: 'Pulse',
                  hint: '72',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  required: false,
                ),
              ),
            ],
          ),
        ],
      AddReadingType.bloodSugar => [
          _Field(
            controller: _sugarCtrl,
            label: 'Blood Sugar (mg/dL)',
            hint: '92',
            keyboardType: TextInputType.number,
            isDark: isDark,
            validator: _doubleValidator(20, 600),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Type selector
          Row(
            children: BloodSugarType.values.map((t) {
              final selected = _sugarType == t;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: t != BloodSugarType.values.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _sugarType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                        ),
                      ),
                      child: Text(
                        t.label,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          color: selected
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      AddReadingType.spo2 => [
          _Field(
            controller: _spo2Ctrl,
            label: 'SpO₂ (%)',
            hint: '98',
            keyboardType: TextInputType.number,
            isDark: isDark,
            validator: _intValidator(70, 100),
          ),
        ],
    };
  }

  String? Function(String?) _intValidator(int min, int max) {
    return (v) {
      if (v == null || v.isEmpty) return 'Required';
      final n = int.tryParse(v);
      if (n == null) return 'Enter a number';
      if (n < min || n > max) return '$min–$max';
      return null;
    };
  }

  String? Function(String?) _doubleValidator(double min, double max) {
    return (v) {
      if (v == null || v.isEmpty) return 'Required';
      final n = double.tryParse(v);
      if (n == null) return 'Enter a number';
      if (n < min || n > max) return '$min–$max';
      return null;
    };
  }
}

// ── Form field widget ─────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.isDark,
    this.validator,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final bool isDark;
  final String? Function(String?)? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      validator: required
          ? (validator ?? (v) => (v == null || v.isEmpty) ? 'Required' : null)
          : null,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDark
            ? AppColors.cardDark
            : AppColors.primary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
