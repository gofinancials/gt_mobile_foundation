import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../support/test_config.dart';

void main() {
  setUpAll(registerTestConfig);

  group('AppValidators.exactLength', () {
    test('accepts a value of exactly the required length', () {
      expect(AppValidators.exactLength('0123456789', length: 10), isNull);
    });

    test('rejects a value one short', () {
      expect(AppValidators.exactLength('012345678', length: 10), 'exactLength');
    });

    test('rejects a value one long', () {
      expect(
        AppValidators.exactLength('01234567890', length: 10),
        'exactLength',
      );
    });

    test('rejects non-digits at the right length', () {
      expect(
        AppValidators.exactLength('012345678a', length: 10),
        'invalidNumber',
      );
    });

    test('allows non-digits when digitsOnly is off', () {
      expect(
        AppValidators.exactLength('ABC123', length: 6, digitsOnly: false),
        isNull,
      );
    });

    test('trims surrounding whitespace before measuring', () {
      expect(AppValidators.exactLength('  1234  ', length: 4), isNull);
    });

    test('reports an empty value as required', () {
      expect(AppValidators.exactLength('', length: 4), 'fieldRequired');
      expect(AppValidators.exactLength(null, length: 4), 'fieldRequired');
      expect(AppValidators.exactLength('   ', length: 4), 'fieldRequired');
    });

    test('passes an empty value when it is not required', () {
      expect(
        AppValidators.exactLength('', length: 4, isRequired: false),
        isNull,
      );
      expect(
        AppValidators.exactLength(null, length: 4, isRequired: false),
        isNull,
      );
    });

    test('still measures a value supplied to an optional field', () {
      expect(
        AppValidators.exactLength('123', length: 4, isRequired: false),
        'exactLength',
      );
    });

    test('the caller message replaces every failure reason', () {
      const message = 'Enter your 10-digit account number';

      expect(
        AppValidators.exactLength('123', length: 10, errorMessage: message),
        message,
      );
      expect(
        AppValidators.exactLength(
          '01234567890',
          length: 10,
          errorMessage: message,
        ),
        message,
      );
      expect(
        AppValidators.exactLength(
          'not-a-number',
          length: 10,
          errorMessage: message,
        ),
        message,
      );
    });

    test('the empty message is separate from the failure message', () {
      expect(
        AppValidators.exactLength(
          null,
          length: 4,
          emptyMessage: 'Required',
          errorMessage: 'Wrong length',
        ),
        'Required',
      );
    });
  });
  group('AppValidators.amountValidator', () {
    test('accepts up to two decimal places', () {
      expect(AppValidators.amountValidator('1,000.55'), isNull);
      expect(AppValidators.amountValidator('1,000.5'), isNull);
      expect(AppValidators.amountValidator('1,000'), isNull);
    });

    test('rejects a third decimal place', () {
      expect(AppValidators.amountValidator('1,000.555'), 'invalidAmount');
    });

    test('follows the currency decimal places', () {
      expect(
        AppValidators.amountValidator('1,000.5', decimalDigits: 0),
        'invalidAmount',
      );
      expect(
        AppValidators.amountValidator('1,000.555', decimalDigits: 3),
        isNull,
      );
    });
  });

  group('AppValidators.balanceValidator', () {
    test('accepts two decimal places within the balance', () {
      expect(AppValidators.balanceValidator('10.55', balance: 20), isNull);
    });

    test('rejects a third decimal place', () {
      expect(
        AppValidators.balanceValidator('10.555', balance: 20),
        'invalidAmount',
      );
    });
  });

  group('AppValidators.phoneValidator', () {
    test('accepts a Nigerian mobile number', () {
      expect(
        AppValidators.phoneValidator('0803 123 4567', countryCode: '+234'),
        isNull,
      );
    });

    test('rejects Nigerian mobile numbers one and two digits short', () {
      expect(
        AppValidators.phoneValidator('801234567', countryCode: '+234'),
        'invalidPhone',
      );
      expect(
        AppValidators.phoneValidator('80123456', countryCode: '+234'),
        'invalidPhone',
      );
    });

    test('checks the length of the selected country', () {
      expect(
        AppValidators.phoneValidator('024 123 4567', countryCode: '+233'),
        isNull,
      );
      expect(
        AppValidators.phoneValidator('024 123 4567', countryCode: '+234'),
        'invalidPhone',
      );
    });

    test('accepts a country whose dial carries an area code', () {
      expect(
        AppValidators.phoneValidator('555 1234', countryCode: '+1-876'),
        isNull,
      );
    });

    test('uses the configured country when none is selected', () {
      expect(AppValidators.phoneValidator('08031234567'), isNull);
      expect(AppValidators.phoneValidator('0241234567'), 'invalidPhone');
    });

    test('honours an explicit length', () {
      expect(
        AppValidators.phoneValidator(
          '12345678',
          countryCode: '+234',
          nationalLength: 8,
        ),
        isNull,
      );
    });

    test('rejects letters', () {
      expect(
        AppValidators.phoneValidator('0803a1234567', countryCode: '+234'),
        'invalidPhone',
      );
    });

    test('prefers the caller\'s messages', () {
      expect(AppValidators.phoneValidator('0803', errorMessage: 'bad'), 'bad');
      expect(AppValidators.phoneValidator('', emptyMessage: 'empty'), 'empty');
    });

    test('allows an optional field left empty', () {
      expect(AppValidators.phoneValidator('', isRequired: false), isNull);
    });
  });

  group('AppValidators.dobValidator', () {
    final now = DateTime(2026, 11, 4, 15, 30);
    const validator = AppValidators.dobValidator;

    String? validate(
      String date, {
      int minAge = 18,
      int? maxAge,
      DateTime? at,
    }) {
      final today = at ?? now;

      return validator(date, minAge: minAge, maxAge: maxAge, now: today);
    }

    String? validateUnder18(String date) {
      return validate(date, minAge: 0, maxAge: 18);
    }

    test('rejects 18 x 365 days, which falls short of 18 calendar years', () {
      // 6570 days: the old `inDays / 365` check read this as exactly 18.
      final birthday = DateTime(2008, 11, 8);
      final elapsed = now.difference(birthday);

      expect(elapsed.inDays, 6570);
      expect(validate('2008-11-08'), 'mustBeNYears');
    });

    test('accepts someone whose 18th birthday is today', () {
      expect(validate('2008-11-04'), isNull);
    });

    test('rejects someone whose 18th birthday is tomorrow', () {
      expect(validate('2008-11-05'), 'mustBeNYears');
    });

    test('counts a 29 February birthday from 1 March in common years', () {
      const leapDay = '2008-02-29';
      final dayBefore = DateTime(2026, 2, 28);
      final dayAfter = DateTime(2026, 3, 1);

      expect(validate(leapDay, at: dayBefore), 'mustBeNYears');
      expect(validate(leapDay, at: dayAfter), isNull);
    });

    test('accepts a newborn born today with minAge 0', () {
      expect(validate('2026-11-04', minAge: 0), isNull);
    });

    test('rejects a future date even with minAge 0', () {
      expect(validate('2026-11-05', minAge: 0), 'invalidDate');
    });

    test('treats maxAge as exclusive', () {
      expect(validateUnder18('2008-11-05'), isNull);
      expect(validateUnder18('2008-11-04'), 'mustBeUnderNYears');
    });

    test('prefers maxAgeErrorMessage for the maxAge failure', () {
      final result = validator(
        '2000-01-01',
        minAge: 0,
        maxAge: 18,
        errorMessage: 'error',
        maxAgeErrorMessage: 'too old',
        now: now,
      );

      expect(result, 'too old');
    });

    test('falls back to errorMessage for the maxAge failure', () {
      final result = validator(
        '2000-01-01',
        minAge: 0,
        maxAge: 18,
        errorMessage: 'error',
        now: now,
      );

      expect(result, 'error');
    });

    test('rejects an unparseable date', () {
      expect(validate('not-a-date'), 'invalidDate');
    });

    test('allows an optional field left empty', () {
      final result = validator('', isRequired: false);

      expect(result, isNull);
    });
  });

  group('AppValidators.postcodeValidator', () {
    String? validate(String? text, {bool isRequired = true}) {
      const message = 'invalidPostcode';
      final validator = AppValidators.postcodeValidator;

      return validator(text, errorMessage: message, isRequired: isRequired);
    }

    final valid = <String, String>{
      'a legacy code': '100001',
      'a spaced digital code': 'FC 02 A09 DB 09',
      'a hyphenated digital code': 'FC-02-A09-DB-09',
      'a compact lower-case digital code': 'fc02a09db09',
    };

    valid.forEach((label, value) {
      test('accepts $label', () {
        expect(validate(value), isNull);
      });
    });

    final invalid = <String, String>{
      'five digits': '10000',
      'a digital code with LGA 00': 'FC00A09DB09',
      'a digital code one character short': 'FC02A09DB9',
      'letters only': 'ABCDEF',
    };

    invalid.forEach((label, value) {
      test('rejects $label', () {
        expect(validate(value), 'invalidPostcode');
      });
    });

    test('asks for a required postcode left empty', () {
      expect(validate(''), 'fieldRequired');
      expect(validate(null), 'fieldRequired');
    });

    test('allows an optional postcode left empty', () {
      expect(validate('', isRequired: false), isNull);
    });

    test('still rejects a bad optional postcode', () {
      expect(validate('10000', isRequired: false), 'invalidPostcode');
    });
  });
}
