import 'package:easy_localization/easy_localization.dart';

/// {@category Utilities}
/// A utility class for safely comparing [DateTime] instances.
class AppDateUtil {
  /// Returns `true` if both dates are in the same calendar year.
  static bool isSameYear({
    required DateTime firstDate,
    required DateTime secondDate,
  }) {
    return firstDate.year == secondDate.year;
  }

  /// Returns `true` if both dates are in the same year and month.
  static bool isSameMonth({
    required DateTime firstDate,
    required DateTime secondDate,
  }) {
    final hasSameYearIndex = isSameYear(
      firstDate: firstDate,
      secondDate: secondDate,
    );
    final hasSameMonthIndex = firstDate.month == secondDate.month;

    return hasSameMonthIndex && hasSameYearIndex;
  }

  /// Returns `true` if both dates represent the exact same calendar day.
  static bool isSameDay({
    required DateTime firstDate,
    required DateTime secondDate,
  }) {
    final hasSameDayIndex = firstDate.day == secondDate.day;
    final isInSameMonth = isSameMonth(
      firstDate: firstDate,
      secondDate: secondDate,
    );
    final isInSameYear = isSameYear(
      firstDate: firstDate,
      secondDate: secondDate,
    );

    return hasSameDayIndex && isInSameMonth && isInSameYear;
  }

  /// Returns `true` if [date] occurred strictly before the current local day.
  static bool isBeforeToday({required DateTime date}) {
    final stringOther = DateFormat("yyyy-MM-dd").format(date);
    final stringToday = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final otherDate = DateTime.parse(stringOther);
    final todayDate = DateTime.parse(stringToday);

    return todayDate.difference(otherDate).inDays > 0;
  }

  /// Returns `true` if [date] occurs strictly after the current local day.
  static bool isAfterToday({required DateTime date}) {
    final stringOther = DateFormat("yyyy-MM-dd").format(date);
    final stringToday = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final otherDate = DateTime.parse(stringOther);
    final todayDate = DateTime.parse(stringToday);

    return otherDate.difference(todayDate).inDays > 0;
  }
}
