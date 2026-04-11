import 'package:easy_localization/easy_localization.dart';

class AppDateUtil {
  static bool isSameYear({
    required DateTime firstDate,
    required DateTime secondDate,
  }) {
    return firstDate.year == secondDate.year;
  }

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

  static bool isBeforeToday({required DateTime date}) {
    final stringOther = DateFormat("yyyy-MM-dd").format(date);
    final stringToday = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final otherDate = DateTime.parse(stringOther);
    final todayDate = DateTime.parse(stringToday);

    return todayDate.difference(otherDate).inDays > 0;
  }

  static bool isAfterToday({required DateTime date}) {
    final stringOther = DateFormat("yyyy-MM-dd").format(date);
    final stringToday = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final otherDate = DateTime.parse(stringOther);
    final todayDate = DateTime.parse(stringToday);

    return otherDate.difference(todayDate).inDays > 0;
  }
}
