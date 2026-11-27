import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppHelpers.isLargePayload', () {
    const threshold = 50 * 1024;
    final largeText = 'A' * threshold;
    final smallText = 'A' * (threshold - 1);

    test('measures a string by its length', () {
      expect(AppHelpers.isLargePayload(largeText), isTrue);
      expect(AppHelpers.isLargePayload(smallText), isFalse);
    });

    test('finds a base64 file nested in a request body', () {
      final body = {
        'customer': {
          'documents': [
            {'type': 'NIN_SLIP', 'file': largeText},
          ],
        },
      };

      expect(AppHelpers.isLargePayload(body), isTrue);
    });

    test('adds up text spread across keys, values and lists', () {
      final half = 'A' * (threshold ~/ 2);
      final body = {
        half: 'x',
        'items': [half],
      };

      expect(AppHelpers.isLargePayload(body), isTrue);
    });

    test('leaves an ordinary request body small', () {
      final body = {'amount': 5000, 'account': '0123456789', 'save': true};

      expect(AppHelpers.isLargePayload(body), isFalse);
    });

    test('counts nothing it cannot read as text', () {
      expect(AppHelpers.isLargePayload(null), isFalse);
      expect(AppHelpers.isLargePayload(42), isFalse);
    });
  });
}
