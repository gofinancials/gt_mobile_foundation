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
}
