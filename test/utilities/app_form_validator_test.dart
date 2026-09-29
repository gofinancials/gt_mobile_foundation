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
}
