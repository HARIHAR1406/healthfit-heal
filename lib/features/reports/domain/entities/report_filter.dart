import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DATE FILTER
// ══════════════════════════════════════════════════════════════════════════════

/// Time-range filter for all analytics pages.
enum DateFilter {
  today('Today', 1),
  thisWeek('This Week', 7),
  thisMonth('This Month', 30),
  last3Months('3 Months', 90),
  last6Months('6 Months', 180),
  thisYear('This Year', 365),
  custom('Custom', -1);

  const DateFilter(this.label, this.days);

  /// Display label shown on filter chips.
  final String label;

  /// Number of calendar days in the range.
  /// [custom] uses -1 as sentinel; actual range is in [CustomDateRange].
  final int days;

  /// Returns the start [DateTime] for this filter (midnight, UTC).
  DateTime get startDate {
    final now = DateTime.now();
    if (this == DateFilter.custom) return now;
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
  }

  /// Returns the end [DateTime] (end of today, UTC).
  DateTime get endDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM DATE RANGE
// ══════════════════════════════════════════════════════════════════════════════

/// Value object for a user-picked date range (used when [DateFilter.custom]).
@immutable
class CustomDateRange {
  const CustomDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get days => end.difference(start).inDays + 1;

  CustomDateRange copyWith({DateTime? start, DateTime? end}) =>
      CustomDateRange(start: start ?? this.start, end: end ?? this.end);

  @override
  bool operator ==(Object other) =>
      other is CustomDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTIVE FILTER (composite)
// ══════════════════════════════════════════════════════════════════════════════

/// The currently selected analytics filter — combines [DateFilter] with an
/// optional [CustomDateRange] for when [DateFilter.custom] is active.
@immutable
class ActiveFilter {
  const ActiveFilter({
    this.filter = DateFilter.thisWeek,
    this.customRange,
  });

  final DateFilter filter;
  final CustomDateRange? customRange;

  DateTime get startDate =>
      filter == DateFilter.custom
          ? (customRange?.start ?? filter.startDate)
          : filter.startDate;

  DateTime get endDate =>
      filter == DateFilter.custom
          ? (customRange?.end ?? filter.endDate)
          : filter.endDate;

  String get label =>
      filter == DateFilter.custom ? 'Custom' : filter.label;

  ActiveFilter copyWith({DateFilter? filter, CustomDateRange? customRange}) =>
      ActiveFilter(
        filter: filter ?? this.filter,
        customRange: customRange ?? this.customRange,
      );

  @override
  bool operator ==(Object other) =>
      other is ActiveFilter &&
      other.filter == filter &&
      other.customRange == customRange;

  @override
  int get hashCode => Object.hash(filter, customRange);
}

