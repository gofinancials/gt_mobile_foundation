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

  group('AppTextFormatter.isCanonicalisablePhone', () {
    test('agrees with the canonicaliser', () {
      expect(AppTextFormatter.isCanonicalisablePhone('08031234567'), isTrue);
      expect(AppTextFormatter.isCanonicalisablePhone('0803'), isFalse);
      expect(AppTextFormatter.isCanonicalisablePhone(null), isFalse);
    });
  });
}
