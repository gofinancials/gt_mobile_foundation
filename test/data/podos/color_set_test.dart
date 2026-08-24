import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('ColorSet', () {
    test('inverts opaque white to opaque black', () {
      const color = ColorSet(0xffffffff);

      expect(color.dark.toARGB32(), 0xff000000);
    });

    test('inverts opaque black to opaque white', () {
      const color = ColorSet(0xff000000);

      expect(color.dark.toARGB32(), 0xffffffff);
    });

    test('inverts each RGB channel while preserving alpha', () {
      const color = ColorSet(0x80402010);

      expect(color.dark.toARGB32(), 0x80bfdfef);
    });

    test('uses the explicitly provided dark color', () {
      const color = ColorSet(0xff123456, 0xff654321);

      expect(color.dark.toARGB32(), 0xff654321);
    });
  });
}
