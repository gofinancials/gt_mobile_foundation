import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../support/test_config.dart';

void main() {
  setUpAll(registerTestConfig);

  group('AppTextFormatter.nationalPhoneDigits', () {
    const national = '8031234567';

    final equivalent = <String, String>{
      'trunk zero': '08031234567',
      'dial code': '2348031234567',
      'dial code with plus': '+2348031234567',
      'dial code and trunk zero': '23408031234567',
      'national digits alone': '8031234567',
      'spaced': '0803 123 4567',
      'spaced with plus': '+234 803 123 4567',
      'punctuated': '(0803) 123-4567',
    };

    equivalent.forEach((label, value) {
      test('$label reduces to the same national digits', () {
        expect(AppTextFormatter.nationalPhoneDigits(value), national);
      });
    });

    test('a national number beginning with the dial code survives', () {
      // Stripping unconditionally would leave seven digits and reject this.
      expect(AppTextFormatter.nationalPhoneDigits('2345678901'), '2345678901');
    });

    test('rejects a number that is too short', () {
      expect(AppTextFormatter.nationalPhoneDigits('803123456'), isNull);
    });

    test('rejects a number that is too long', () {
      expect(AppTextFormatter.nationalPhoneDigits('80312345678'), isNull);
    });

    test(
      'rejects an eleven-digit number that does not start with a trunk zero',
      () {
        expect(AppTextFormatter.nationalPhoneDigits('18031234567'), isNull);
      },
    );

    test('rejects a value with no digits at all', () {
      expect(AppTextFormatter.nationalPhoneDigits('not a phone'), isNull);
      expect(AppTextFormatter.nationalPhoneDigits(''), isNull);
      expect(AppTextFormatter.nationalPhoneDigits(null), isNull);
    });

    test('honours an explicit dial code and length', () {
      expect(
        AppTextFormatter.nationalPhoneDigits(
          '+1 415 555 0123',
          dialCode: '+1',
          nationalLength: 10,
        ),
        '4155550123',
      );
    });
  });

  group('AppTextFormatter.canonicalPhone', () {
    test('assembles the dial code and the national digits', () {
      expect(AppTextFormatter.canonicalPhone('0803 123 4567'), '2348031234567');
    });

    test('adds the plus only when asked', () {
      expect(
        AppTextFormatter.canonicalPhone('08031234567', withPlus: true),
        '+2348031234567',
      );
    });

    test('is idempotent', () {
      final once = AppTextFormatter.canonicalPhone('0803 123 4567');
      expect(AppTextFormatter.canonicalPhone(once), once);
    });

    test('returns null rather than guessing at a malformed number', () {
      expect(AppTextFormatter.canonicalPhone('0803 123'), isNull);
    });

    test('uses the dial code it was given', () {
      expect(
        AppTextFormatter.canonicalPhone('4155550123', dialCode: '1'),
        '14155550123',
      );
    });
  });

  group('AppTextFormatter.nationalPhoneDigits by calling code', () {
    test('takes the length from the dial code when none is given', () {
      expect(
        AppTextFormatter.nationalPhoneDigits('024 123 4567', dialCode: '+233'),
        '241234567',
      );
    });

    test('rejects a number of the wrong length for the dial code', () {
      expect(
        AppTextFormatter.nationalPhoneDigits('02412345678', dialCode: '+233'),
        isNull,
      );
    });

    test('rejects Nigerian mobile numbers one and two digits short', () {
      expect(AppTextFormatter.nationalPhoneDigits('801234567'), isNull);
      expect(AppTextFormatter.nationalPhoneDigits('80123456'), isNull);
    });

    test('accepts every length a country publishes', () {
      expect(
        AppTextFormatter.nationalPhoneDigits('01512 3456789', dialCode: '49'),
        '15123456789',
      );
      expect(
        AppTextFormatter.nationalPhoneDigits('0151 2345678', dialCode: '49'),
        '1512345678',
      );
      expect(
        AppTextFormatter.nationalPhoneDigits('0151 234567', dialCode: '49'),
        isNull,
      );
    });

    test('an explicit length overrides the published one', () {
      expect(
        AppTextFormatter.nationalPhoneDigits('2412345678', dialCode: '+233'),
        isNull,
      );
      expect(
        AppTextFormatter.nationalPhoneDigits(
          '2412345678',
          dialCode: '+233',
          nationalLength: 10,
        ),
        '2412345678',
      );
    });

    test('falls back to ten digits for an unknown calling code', () {
      expect(
        AppTextFormatter.nationalPhoneDigits('4155550123', dialCode: '999'),
        '4155550123',
      );
    });

    test('rejects letters mixed into the digits', () {
      expect(AppTextFormatter.nationalPhoneDigits('0803a1234567'), isNull);
    });
  });

  group('AppTextFormatter.nationalPhoneDigits with an area code dial', () {
    const national = '8765551234';

    final equivalent = <String, String>{
      'without the area code': '555 1234',
      'with the area code': '876 555 1234',
      'with the calling code': '+1 876 555 1234',
    };

    equivalent.forEach((label, value) {
      test('$label reduces to the same national digits', () {
        expect(
          AppTextFormatter.nationalPhoneDigits(value, dialCode: '+1-876'),
          national,
        );
      });
    });

    test('needs the area code when the dial lists several', () {
      const dial = '1-809,1-829,1-849';

      expect(
        AppTextFormatter.nationalPhoneDigits('809 555 1234', dialCode: dial),
        '8095551234',
      );
      expect(
        AppTextFormatter.nationalPhoneDigits('555 1234', dialCode: dial),
        isNull,
      );
    });
  });

  group('AppTextFormatter.canonicalPhone by calling code', () {
    test('canonicalises a Ghanaian number without a length', () {
      expect(
        AppTextFormatter.canonicalPhone(
          '024 123 4567',
          dialCode: '233',
          withPlus: true,
        ),
        '+233241234567',
      );
    });

    test('uses the calling code alone for an area code dial', () {
      expect(
        AppTextFormatter.canonicalPhone('555 1234', dialCode: '+1-876'),
        '18765551234',
      );
    });

    test('is idempotent where a country publishes several lengths', () {
      final once = AppTextFormatter.canonicalPhone(
        '0664 1234567',
        dialCode: '+43',
      );

      expect(once, '436641234567');
      expect(AppTextFormatter.canonicalPhone(once, dialCode: '+43'), once);
    });
  });

  group('AppTextFormatter.isCanonicalisablePhone', () {
    test('agrees with the canonicaliser', () {
      expect(AppTextFormatter.isCanonicalisablePhone('08031234567'), isTrue);
      expect(AppTextFormatter.isCanonicalisablePhone('0803'), isFalse);
      expect(AppTextFormatter.isCanonicalisablePhone(null), isFalse);
    });
  });
}
