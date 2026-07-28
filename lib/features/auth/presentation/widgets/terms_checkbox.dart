import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Terms & Conditions + Privacy Policy checkbox widget.
///
/// Renders a compact checkbox row with tappable hyperlinks.
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.hasError = false,
  });

  /// Current checked state.
  final bool value;

  /// Called when the checkbox is toggled.
  final ValueChanged<bool> onChanged;

  /// Whether to show an error highlight.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: hasError
                      ? AppColors.error
                      : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                  width: AppSpacing.borderNormal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall.copyWith(color: textColor),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    _linkSpan(
                      context,
                      'Terms of Service',
                      AppConstants.termsOfServiceUrl,
                    ),
                    const TextSpan(text: ' and '),
                    _linkSpan(
                      context,
                      'Privacy Policy',
                      AppConstants.privacyPolicyUrl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxl),
            child: Text(
              'You must accept the terms to continue.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  TextSpan _linkSpan(BuildContext context, String text, String url) {
    return TextSpan(
      text: text,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.primary,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          // TODO: Open URL with url_launcher when added
          // launchUrl(Uri.parse(url));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening: $url')),
          );
        },
    );
  }
}
