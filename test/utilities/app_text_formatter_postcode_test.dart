import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppTextFormatter.canonicalPostcode', () {
    const written = 'EK 01 A03 FK 01';

    final equivalent = <String, String>{
      'spaced': 'EK 01 A03 FK 01',
      'hyphenated': 'EK-01-A03-FK-01',
      'compact': 'EK01A03FK01',
      'lower case': 'ek01a03fk01',
      'mixed separators': 'ek01-a03 fk01',
      'padded': '  EK 01 A03 FK 01  ',
    };

    equivalent.forEach((label, value) {
      test('a $label digital code comes back in its spaced groups', () {
        expect(AppTextFormatter.canonicalPostcode(value), written);
      });
    });

    test('keeps a district made of letters or of digits', () {
      final letters = AppTextFormatter.canonicalPostcode('FC02ABCDB09');
      final digits = AppTextFormatter.canonicalPostcode('FC02123DB09');

      expect(letters, 'FC 02 ABC DB 09');
      expect(digits, 'FC 02 123 DB 09');
    });

    test('returns a legacy code as its six digits', () {
      expect(AppTextFormatter.canonicalPostcode('100001'), '100001');
      expect(AppTextFormatter.canonicalPostcode('100 001'), '100001');
    });

    final invalid = <String, String>{
      'LGA 00': 'EK00A03FK01',
      'building 00': 'EK01A03FK00',
      'a digit in the state': 'E101A03FK01',
      'a letter in the LGA': 'EKO1A03FK01',
      'a digit in the area': 'EK01A03F101',
      'twelve characters': 'EK01A03FK011',
      'ten characters': 'EK01A03FK1',
      'five digits': '10000',
      'seven digits': '1000001',
      'other punctuation': 'EK.01.A03.FK.01',
      'empty': '',
    };

    invalid.forEach((label, value) {
      test('rejects $label', () {
        expect(AppTextFormatter.canonicalPostcode(value), isNull);
      });
    });

    test('rejects null', () {
      expect(AppTextFormatter.canonicalPostcode(null), isNull);
    });
  });

  group('AppRegex.nigerianPostcode', () {
    test('names the groups of a digital code', () {
      final match = AppRegex.nigerianPostcode.firstMatch('FC02A09DB09');
      final groups = ['state', 'lga', 'district', 'area', 'building'];
      final values = groups.map((group) => match?.namedGroup(group));

      expect(values, ['FC', '02', 'A09', 'DB', '09']);
      expect(match?.namedGroup('legacy'), isNull);
    });

    test('needs the code uppercased and its separators removed', () {
      expect(AppRegex.nigerianPostcode.hasMatch('fc02a09db09'), isFalse);
      expect(AppRegex.nigerianPostcode.hasMatch('FC 02 A09 DB 09'), isFalse);
    });

    test('leaves postalCode meaning six digits only', () {
      expect(AppRegex.postalCode.hasMatch('100001'), isTrue);
      expect(AppRegex.postalCode.hasMatch('FC02A09DB09'), isFalse);
    });
  });
}
