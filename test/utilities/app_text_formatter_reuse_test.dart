import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:intl/intl.dart';

void main() {
  tearDown(() {
    AppTextFormatter.locale = null;
    Intl.defaultLocale = null;
  });

  group('AppTextFormatter after a locale change', () {
    test('formatCurrency follows AppTextFormatter.locale', () {
      final english = AppTextFormatter.formatCurrency(22096.06);
      AppTextFormatter.locale = const Locale('de');
      final german = AppTextFormatter.formatCurrency(22096.06);

      expect(english, '₦22,096.06');
      expect(german, contains('22.096,06'));
    });

    test('formatCurrency follows Intl.defaultLocale when no locale is set', () {
      final english = AppTextFormatter.formatCurrency(22096.06);
      Intl.defaultLocale = 'de';
      final german = AppTextFormatter.formatCurrency(22096.06);

      expect(english, '₦22,096.06');
      expect(german, contains('22.096,06'));
    });

    test('formatCurrencyShort follows AppTextFormatter.locale', () {
      final english = AppTextFormatter.formatCurrencyShort(1500);
      AppTextFormatter.locale = const Locale('fr');
      final french = AppTextFormatter.formatCurrencyShort(1500);

      expect(english, '₦1.5K');
      expect(french, contains('1,5'));
    });

    test('formatNumberCutsom follows AppTextFormatter.locale', () {
      const pattern = '#,##0.00';
      final english = AppTextFormatter.formatNumberCutsom('1234', pattern);
      AppTextFormatter.locale = const Locale('de');
      final german = AppTextFormatter.formatNumberCutsom('1234', pattern);

      expect(english, '1,234.00');
      expect(german, '1.234,00');
    });

    test('formatNumberCutsom with ignoreLocale follows Intl.defaultLocale', () {
      const pattern = '#,##0.00';
      String format() {
        return AppTextFormatter.formatNumberCutsom('1234', pattern, true);
      }

      AppTextFormatter.locale = const Locale('de');
      final english = format();
      Intl.defaultLocale = 'fr';
      final french = format();

      expect(english, '1,234.00');
      expect(french, contains(',00'));
    });

    test('formatNumberLong follows Intl.defaultLocale, not locale', () {
      AppTextFormatter.locale = const Locale('de');
      final english = AppTextFormatter.formatNumberLong('1234.5');
      Intl.defaultLocale = 'de';
      final german = AppTextFormatter.formatNumberLong('1234.5');

      expect(english, '1,234.5');
      expect(german, '1.234,5');
    });

    test('formatNumber follows AppTextFormatter.locale', () {
      final english = AppTextFormatter.formatNumber('1500');
      AppTextFormatter.locale = const Locale('fr');
      final french = AppTextFormatter.formatNumber('1500');

      expect(english, '1.5K');
      expect(french, contains('1,5'));
    });
  });

  group('DateTime.format', () {
    test('formats the date with the given pattern', () {
      final date = DateTime(2026, 11, 24, 9, 5, 7);

      expect(date.format(), '11-24-2026');
      expect(date.format('dd/MM/yyyy HH:mm:ss'), '24/11/2026 09:05:07');
    });

    test('formats a UTC date in UTC', () {
      final date = DateTime.utc(2026, 11, 24, 23, 30);

      expect(date.format('yyyy-MM-dd HH:mm'), '2026-11-24 23:30');
    });
  });

  group('AppTextFormatter.timeSince', () {
    test('formats a date older than two days', () {
      final now = DateTime(2026, 11, 24, 12);
      final date = DateTime(2026, 11, 14, 8, 30).toIso8601String();
      final withTime = AppTextFormatter.timeSince(
        date,
        comparisonDate: now,
        useTime: true,
      );

      expect(AppTextFormatter.timeSince(date, comparisonDate: now), 'Nov 14');
      expect(withTime, 'Nov 14 08:30');
    });
  });
}
