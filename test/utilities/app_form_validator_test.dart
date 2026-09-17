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
      expect(AppValidators.exactLength('012345678', length: 10), 'minLength');
    });

    test('rejects a value one long', () {
      expect(AppValidators.exactLength('01234567890', length: 10), 'maxLength');
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
        'minLength',
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
}
