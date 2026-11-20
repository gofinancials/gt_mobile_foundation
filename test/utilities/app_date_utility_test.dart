import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppDateUtil.yearsBetween', () {
    int years(DateTime from, DateTime to) {
      return AppDateUtil.yearsBetween(from: from, to: to);
    }

    test('counts a full year on the anniversary', () {
      final from = DateTime(2020, 6, 15);
      final to = DateTime(2021, 6, 15);

      expect(years(from, to), 1);
    });

    test('does not count the year until the anniversary', () {
      final from = DateTime(2020, 6, 15);
      final to = DateTime(2021, 6, 14);

      expect(years(from, to), 0);
    });

    test('counts leap days, unlike 365-day years', () {
      final from = DateTime(2008, 11, 8);
      final to = DateTime(2026, 11, 4);
      final elapsed = to.difference(from);

      expect(elapsed.inYears, 18);
      expect(years(from, to), 17);
    });

    test('moves a 29 February anniversary to 1 March in common years', () {
      final leapDay = DateTime(2024, 2, 29);
      final dayBefore = DateTime(2025, 2, 28);
      final dayAfter = DateTime(2025, 3, 1);
      final nextLeapDay = DateTime(2028, 2, 29);

      expect(years(leapDay, dayBefore), 0);
      expect(years(leapDay, dayAfter), 1);
      expect(years(leapDay, nextLeapDay), 4);
    });

    test('ignores the time of day', () {
      final lateEvening = DateTime(2020, 6, 15, 23, 59);
      final earlyMorning = DateTime(2021, 6, 15, 0, 1);

      expect(years(lateEvening, earlyMorning), 1);
    });

    test('is negative when to is before from', () {
      final from = DateTime(2021, 6, 15);
      final yearEarlier = DateTime(2020, 6, 15);
      final dayAfterYearEarlier = DateTime(2020, 6, 16);

      expect(years(from, yearEarlier), -1);
      expect(years(from, dayAfterYearEarlier), 0);
    });

    test('is mirrored by DateTime.yearsUntil', () {
      final from = DateTime(2000, 1, 1);
      final to = DateTime(2026, 11, 4);

      expect(from.yearsUntil(to), 26);
    });
  });

  group('DateTimeRange.isLessThanAYear', () {
    final start = DateTime(2024, 1, 1);

    bool isLessThanAYear(DateTime end) {
      final range = DateTimeRange(start: start, end: end);

      return range.isLessThanAYear;
    }

    test('is true up to and including the first anniversary', () {
      final lastDayOfYear = DateTime(2024, 12, 31);
      final anniversary = DateTime(2025, 1, 1);

      expect(isLessThanAYear(lastDayOfYear), isTrue);
      expect(isLessThanAYear(anniversary), isTrue);
    });

    test('is false after the first anniversary', () {
      final dayAfterAnniversary = DateTime(2025, 1, 2);

      expect(isLessThanAYear(dayAfterAnniversary), isFalse);
    });
  });
}
