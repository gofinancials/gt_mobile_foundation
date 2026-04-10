import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

extension DateExtension on DateTime {
  bool operator <(DateTime? other) {
    if (other == null) return false;
    return isBefore(other);
  }

  bool operator <=(DateTime? other) {
    if (other == null) return false;
    return millisecondsSinceEpoch <= other.millisecondsSinceEpoch;
  }

  bool operator >(DateTime? other) {
    if (other == null) return true;
    return isAfter(other);
  }

  bool operator >=(DateTime? other) {
    if (other == null) return true;
    return millisecondsSinceEpoch >= other.millisecondsSinceEpoch;
  }

  bool isSameDay(DateTime? other) {
    if (other == null) return false;
    return DateUtils.isSameDay(this, other);
  }

  bool isSameMonth(DateTime? other) {
    if (other == null) return false;
    return DateUtils.isSameMonth(this, other);
  }

  bool isSameYear(DateTime? other) {
    if (other == null) return false;
    return AppDateUtil.isSameYear(firstDate: this, secondDate: other);
  }

  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  List<int> get months => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  String format([String? format]) {
    return AppTextFormatter.formatDate(toIso8601String(), format: format);
  }

  String get asDuration {
    return AppTextFormatter.timeSince(toIso8601String());
  }

  String get asAge {
    return AppTextFormatter.age(this);
  }

  String get asTimedDuration {
    return AppTextFormatter.timeSince(toIso8601String(), useTime: true);
  }
}

extension DurationExtensions on Duration {
  int get inYears => inDays ~/ 365;
  double get inPreciseYears => inDays / 365;
  int get inWeeks => (inDays ~/ 7).ceil();
  int get inMonths => (inWeeks / 4).ceil();
}

extension TimeExtension on TimeOfDay {
  DateTime get asDate {
    final today = DateTime.now().startOfDay;
    return today.add(Duration(hours: hour, minutes: minute));
  }

  bool operator >(TimeOfDay? other) {
    if (other == null) return true;
    return asDate.isAfter(other.asDate);
  }

  bool operator >=(TimeOfDay? other) {
    if (other == null) return true;
    return asDate.millisecondsSinceEpoch >= other.asDate.millisecondsSinceEpoch;
  }

  bool isSameHour(TimeOfDay? other) {
    if (other == null) return false;
    return hour == other.hour;
  }

  bool isSameMinute(TimeOfDay? other) {
    if (other == null) return false;
    return minute == other.minute;
  }
}

extension DateRangeExtension on DateTimeRange {
  String get fmt => "MM/dd/yyyy";
  String get longFmt => "MMMM dd yyyy";

  String get formattedDateRange {
    final startText = start.format(fmt);
    final endText = end.format(fmt);

    return "$startText - $endText";
  }

  String get formattedDateRangeLong {
    final startText = start.format(longFmt);
    final endText = end.format(longFmt);

    return "$startText - $endText";
  }

  String get formattedDateTimeRange {
    final startText = start.format("$fmt hh:mm");
    final endText = end.format("$fmt hh:mm");

    return "$startText - $endText";
  }

  String get formattedDateTimeRangeLong {
    final startText = start.format("$longFmt hh:mm");
    final endText = end.format("$longFmt hh:mm");

    return "$startText - $endText";
  }

  bool get isLessThanAYear {
    return end.difference(start).inPreciseYears <= 1;
  }
}
