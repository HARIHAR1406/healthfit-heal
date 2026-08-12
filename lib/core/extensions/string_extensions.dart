/// String utility extensions for HealthFit Heal.
extension StringExtensions on String {
  // ── Casing ────────────────────────────────────────────────────────────────

  /// Capitalises the first character of the string.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title-cases every word in the string.
  String get titleCase => split(' ')
      .map((word) => word.isEmpty ? word : word.capitalised)
      .join(' ');

  /// Converts to camelCase.
  String get camelCase {
    final words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return this;
    return words[0].toLowerCase() +
        words.skip(1).map((w) => w.capitalised).join();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  /// Whether the string is a valid email address.
  bool get isValidEmail => RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(this);

  /// Whether the string meets minimum password requirements.
  /// Must be at least 8 chars and contain a letter + number.
  bool get isValidPassword =>
      length >= 8 &&
      contains(RegExp(r'[A-Za-z]')) &&
      contains(RegExp(r'[0-9]'));

  /// Whether the string contains at least one uppercase letter.
  bool get hasUppercase => contains(RegExp(r'[A-Z]'));

  /// Whether the string contains at least one lowercase letter.
  bool get hasLowercase => contains(RegExp(r'[a-z]'));

  /// Whether the string contains at least one digit.
  bool get hasDigit => contains(RegExp(r'[0-9]'));

  /// Whether the string contains at least one special character.
  bool get hasSpecialChar => contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  /// Whether the string is a valid phone number (basic check).
  bool get isValidPhone => RegExp(r'^\+?[0-9]{7,15}$').hasMatch(this);

  /// Whether the string is a valid URL.
  bool get isValidUrl => RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}'
        r'\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      ).hasMatch(this);

  // ── Parsing ───────────────────────────────────────────────────────────────

  /// Parses the string as an int, or returns [fallback] if parsing fails.
  int toIntOrDefault([int fallback = 0]) => int.tryParse(this) ?? fallback;

  /// Parses the string as a double, or returns [fallback] if parsing fails.
  double toDoubleOrDefault([double fallback = 0.0]) =>
      double.tryParse(this) ?? fallback;

  // ── Formatting ────────────────────────────────────────────────────────────

  /// Removes all whitespace from the string.
  String get removeWhitespace => replaceAll(RegExp(r'\s'), '');

  /// Truncates the string to [maxLength] and appends [ellipsis] if needed.
  String truncate(int maxLength, {String ellipsis = '…'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$ellipsis';

  /// Masks characters in the string, useful for displaying tokens/passwords.
  String mask({int visibleEnd = 4, String maskChar = '*'}) {
    if (length <= visibleEnd) return this;
    final hidden = maskChar * (length - visibleEnd);
    return '$hidden${substring(length - visibleEnd)}';
  }

  /// Formats a number string with thousand separators.
  String get withThousandSeparator {
    final n = double.tryParse(this);
    if (n == null) return this;
    return n.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  // ── Null / Empty ──────────────────────────────────────────────────────────

  /// Returns null if the string is empty, otherwise returns the string.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Returns null if the string is blank (empty or whitespace-only).
  String? get nullIfBlank => trim().isEmpty ? null : this;
}

/// Nullable String extensions.
extension NullableStringExtensions on String? {
  /// Returns true if the string is null or empty.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if the string is null, empty, or whitespace-only.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// Returns the value or a fallback string.
  String orDefault([String fallback = '']) => this ?? fallback;
}

