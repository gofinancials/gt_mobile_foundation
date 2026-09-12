import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  // These check the legacy output contract, not the quality of the RNG.
  test('randomNumString preserves its unpadded decimal range', () {
    for (var i = 0; i < 100; i++) {
      final value = randomNumString();
      expect(value, matches(r'^(0|[1-9][0-9]{0,7})$'));
      expect(int.parse(value), inInclusiveRange(0, 99999999));
    }
  });

  test('randomInt preserves its range', () {
    for (var i = 0; i < 100; i++) {
      expect(randomInt(), inInclusiveRange(0, 9999));
    }
  });
}
