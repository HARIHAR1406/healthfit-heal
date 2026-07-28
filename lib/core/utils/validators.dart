/// Form validation utilities for HealthFit Heal.
///
/// All methods return null if valid (as required by [FormField.validator]),
/// or a user-facing error string if invalid.
abstract final class Validators {

  // ── Email ─────────────────────────────────────────────────────────────────

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required.';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!value.contains(RegExp(r'[A-Za-z]'))) {
      return 'Password must contain at least one letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  /// Validates that [confirmValue] matches [originalValue].
  static String? confirmPassword(String? confirmValue, String? originalValue) {
    if (confirmValue == null || confirmValue.isEmpty) {
      return 'Please confirm your password.';
    }
    if (confirmValue != originalValue) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // ── Name ──────────────────────────────────────────────────────────────────

  static String? name(String? value, {String label = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    if (value.trim().length < 2) {
      return '$label must be at least 2 characters.';
    }
    if (value.trim().length > 50) {
      return '$label cannot exceed 50 characters.';
    }
    return null;
  }

  // ── Phone ─────────────────────────────────────────────────────────────────

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  // ── Required ──────────────────────────────────────────────────────────────

  /// Generic required-field validator.
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  // ── Number ────────────────────────────────────────────────────────────────

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    final n = double.tryParse(value);
    if (n == null) return '$label must be a number.';
    if (n <= 0) return '$label must be greater than 0.';
    return null;
  }

  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    String label = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    final n = double.tryParse(value);
    if (n == null) return '$label must be a number.';
    if (n < min || n > max) return '$label must be between $min and $max.';
    return null;
  }

  // ── Age ───────────────────────────────────────────────────────────────────

  static String? age(String? value) {
    return numberInRange(value, min: 1, max: 120, label: 'Age');
  }

  // ── Weight / Height ───────────────────────────────────────────────────────

  static String? weight(String? value) {
    return numberInRange(value, min: 1, max: 500, label: 'Weight');
  }

  static String? height(String? value) {
    return numberInRange(value, min: 50, max: 300, label: 'Height');
  }

  // ── URL ───────────────────────────────────────────────────────────────────

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}'
      r'\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL.';
    }
    return null;
  }

  // ── Compose ───────────────────────────────────────────────────────────────

  /// Runs multiple validators in sequence, returning the first error.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) =>
      (value) {
        for (final validator in validators) {
          final error = validator(value);
          if (error != null) return error;
        }
        return null;
      };
}

/// Alias for [Validators] — used throughout auth feature pages.
typedef AppValidators = Validators;
