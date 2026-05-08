import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Extensions}
/// Extension on [DateTime] providing operators and utility methods for
/// date comparisons and formatting.
extension DateExtension on DateTime {
  /// Returns `true` if this date is strictly before [other].
  bool operator <(DateTime? other) {
    if (other == null) return false;
    return isBefore(other);
  }

  /// Returns `true` if this date is before or equal to [other].
  bool operator <=(DateTime? other) {
    if (other == null) return false;
    return millisecondsSinceEpoch <= other.millisecondsSinceEpoch;
  }

  /// Returns `true` if this date is strictly after [other].
  bool operator >(DateTime? other) {
    if (other == null) return true;
    return isAfter(other);
  }

  /// Returns `true` if this date is after or equal to [other].
  bool operator >=(DateTime? other) {
    if (other == null) return true;
    return millisecondsSinceEpoch >= other.millisecondsSinceEpoch;
  }

  /// Returns `true` if this date represents the same day as [other], ignoring time.
  bool isSameDay(DateTime? other) {
    if (other == null) return false;
    return DateUtils.isSameDay(this, other);
  }

  /// Returns `true` if this date is in the same month and year as [other].
  bool isSameMonth(DateTime? other) {
    if (other == null) return false;
    return DateUtils.isSameMonth(this, other);
  }

  /// Returns `true` if this date is in the same year as [other].
  bool isSameYear(DateTime? other) {
    if (other == null) return false;
    return AppDateUtil.isSameYear(firstDate: this, secondDate: other);
  }

  /// Returns `true` if this date is strictly before the current date (ignoring time).
  bool isBeforeToday(DateTime? other) {
    return AppDateUtil.isBeforeToday(date: this);
  }

  /// Returns `true` if this date is strictly after the current date (ignoring time).
  bool isAfterToday() {
    return AppDateUtil.isAfterToday(date: this);
  }

  /// Returns a new [DateTime] instance representing the start of this date's day (00:00:00).
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Returns a new [DateTime] instance representing the end of this date's day (23:59:59).
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Returns a list of month indices from 1 to 12.
  List<int> get months => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  /// Formats this date as a string. Optionally accepts a custom date [format].
  String format([String? format]) {
    return AppTextFormatter.formatDate(toIso8601String(), format: format);
  }

  /// Returns a relative human-readable string indicating the time elapsed since this date.
  String get asDuration {
    return AppTextFormatter.timeSince(toIso8601String());
  }

  /// Returns a human-readable string representing the age based on this date.
  String get asAge {
    return AppTextFormatter.age(this);
  }

  /// Returns a relative string indicating the time elapsed, explicitly including time components.
  String get asTimedDuration {
    return AppTextFormatter.timeSince(toIso8601String(), useTime: true);
  }
}

/// {@category Extensions}
/// Extension on [Duration] providing getters for converting duration into larger time units.
extension DurationExtensions on Duration {
  /// Converts the duration into an integer number of years (approximated as 365 days).
  int get inYears => inDays ~/ 365;

  /// Converts the duration into a precise floating-point number of years.
  double get inPreciseYears => inDays / 365;

  /// Converts the duration into the ceiling number of weeks.
  int get inWeeks => (inDays ~/ 7).ceil();

  /// Converts the duration into the ceiling number of months.
  int get inMonths => (inWeeks / 4).ceil();
}

/// {@category Extensions}
/// Extension on [TimeOfDay] providing comparison operators and formatting methods.
extension TimeExtension on TimeOfDay {
  /// Converts this [TimeOfDay] into a [DateTime] instance using today's date.
  DateTime get asDate {
    final today = DateTime.now().startOfDay;
    return today.add(Duration(hours: hour, minutes: minute));
  }

  /// Returns `true` if this time is strictly after [other].
  bool operator >(TimeOfDay? other) {
    if (other == null) return true;
    return asDate.isAfter(other.asDate);
  }

  /// Returns `true` if this time is after or equal to [other].
  bool operator >=(TimeOfDay? other) {
    if (other == null) return true;
    return asDate.millisecondsSinceEpoch >= other.asDate.millisecondsSinceEpoch;
  }

  /// Returns `true` if this time shares the same hour as [other].
  bool isSameHour(TimeOfDay? other) {
    if (other == null) return false;
    return hour == other.hour;
  }

  /// Returns `true` if this time shares the same minute as [other].
  bool isSameMinute(TimeOfDay? other) {
    if (other == null) return false;
    return minute == other.minute;
  }

  /// Formats this time as a string. Defaults to "hh:mm a".
  String formattedTime([String format = "hh:mm a"]) {
    return asDate.format(format);
  }
}

/// {@category Extensions}
/// Extension on [DateTimeRange] providing utility methods for date ranges.
extension DateRangeExtension on DateTimeRange {
  /// Formats the start and end dates as a concatenated string range.
  String formattedDateRange([String format = "dd-MM-yyy"]) {
    final startText = start.format(format);
    final endText = end.format(format);

    return "$startText - $endText";
  }

  /// Returns `true` if the duration between start and end is one year or less.
  bool get isLessThanAYear {
    return end.difference(start).inPreciseYears <= 1;
  }
}
