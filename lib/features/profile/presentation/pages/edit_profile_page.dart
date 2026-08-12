import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_notifier.dart';
import '../providers/profile_providers.dart';
import '../providers/profile_state.dart';
import '../widgets/profile_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE PAGE
// ══════════════════════════════════════════════════════════════════════════════

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  late Gender _gender;
  late ActivityLevel _activityLevel;
  late DateTime _dateOfBirth;

  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    _firstNameCtrl = TextEditingController(text: profile?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: profile?.lastName ?? '');
    _emailCtrl = TextEditingController(text: profile?.email ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');
    _heightCtrl =
        TextEditingController(text: profile?.heightCm.toStringAsFixed(0) ?? '175');
    _weightCtrl =
        TextEditingController(text: profile?.weightKg.toStringAsFixed(1) ?? '70.0');
    _gender = profile?.gender ?? Gender.male;
    _activityLevel = profile?.activityLevel ?? ActivityLevel.moderatelyActive;
    _dateOfBirth = profile?.dateOfBirth ?? DateTime(1995, 1, 1);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final current = ref.read(currentProfileProvider);
    if (current == null) return;

    final updated = current.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      heightCm: double.tryParse(_heightCtrl.text) ?? current.heightCm,
      weightKg: double.tryParse(_weightCtrl.text) ?? current.weightKg,
      gender: _gender,
      activityLevel: _activityLevel,
      dateOfBirth: _dateOfBirth,
    );

    await ref.read(profileNotifierProvider.notifier).updateProfile(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving =
        ref.watch(profileNotifierProvider) is ProfileSaving;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Edit Profile',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(
                    'Save',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () {
          if (!_dirty) setState(() => _dirty = true);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Avatar ───────────────────────────────────────────────────────
            Center(
              child: ProfileAvatar(
                initials: '${_firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text[0] : '?'}'
                    '${_lastNameCtrl.text.isNotEmpty ? _lastNameCtrl.text[0] : ''}',
                size: 96,
                showEditBadge: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo upload coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Personal Info ─────────────────────────────────────────────────
            _SectionLabel(label: 'Personal Information', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ProfileField(
                    controller: _firstNameCtrl,
                    label: 'First Name',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ProfileField(
                    controller: _lastNameCtrl,
                    label: 'Last Name',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              controller: _emailCtrl,
              label: 'Email',
              icon: Icons.email_outlined,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              controller: _phoneCtrl,
              label: 'Phone',
              icon: Icons.phone_outlined,
              isDark: isDark,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              controller: _bioCtrl,
              label: 'Bio',
              icon: Icons.notes_rounded,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Date of Birth ─────────────────────────────────────────────────
            _SectionLabel(label: 'Date of Birth', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            _DatePickerTile(
              date: _dateOfBirth,
              isDark: isDark,
              onChanged: (d) => setState(() => _dateOfBirth = d),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Gender ────────────────────────────────────────────────────────
            _SectionLabel(label: 'Gender', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            _GenderSelector(
              selected: _gender,
              isDark: isDark,
              onChanged: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Physical ─────────────────────────────────────────────────────
            _SectionLabel(label: 'Physical Stats', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ProfileField(
                    controller: _heightCtrl,
                    label: 'Height (cm)',
                    icon: Icons.height_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d < 50 || d > 250) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ProfileField(
                    controller: _weightCtrl,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d < 20 || d > 500) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Activity Level ────────────────────────────────────────────────
            _SectionLabel(label: 'Activity Level', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            _ActivitySelector(
              selected: _activityLevel,
              isDark: isDark,
              onChanged: (a) => setState(() => _activityLevel = a),
            ),
            const SizedBox(height: AppSpacing.massive),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.overline.copyWith(
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(
        color:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor:
            isDark ? AppColors.cardDark : const Color(0xFFF8FAFF),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.date,
    required this.isDark,
    required this.onChanged,
  });

  final DateTime date;
  final bool isDark;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final label =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Material(
      color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(1920),
            lastDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
              ),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.cake_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  final Gender selected;
  final bool isDark;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: Gender.values.map((g) {
        final isSelected = g == selected;
        return ChoiceChip(
          label: Text('${g.symbol} ${g.label}'),
          selected: isSelected,
          onSelected: (_) => onChanged(g),
          selectedColor: AppColors.primary.withOpacity(0.15),
          backgroundColor:
              isDark ? AppColors.cardDark : const Color(0xFFF8FAFF),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }
}

class _ActivitySelector extends StatelessWidget {
  const _ActivitySelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  final ActivityLevel selected;
  final bool isDark;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ActivityLevel.values.map((a) {
        final isSelected = a == selected;
        return GestureDetector(
          onTap: () => onChanged(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : (isDark ? AppColors.cardDark : const Color(0xFFF8FAFF)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight),
                width: isSelected ? 1.5 : AppSpacing.borderThin,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      Text(
                        a.description,
                        style: AppTypography.captionText.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

