import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppRegex.name', () {
    const accepted = [
      'A',
      'A.',
      "O'Brien",
      'O’Brien',
      'Adéṣọlá',
      'Ụchechukwu',
      'Ɗanjuma',
      'José',
      'Nguyễn',
      'Jean-Paul',
      'Bayo Jr.',
      '-',
      ' ',
    ];

    for (final name in accepted) {
      test('accepts "$name"', () {
        expect(AppRegex.name.hasMatch(name), isTrue);
      });
    }

    test('refuses an empty name', () {
      expect(AppRegex.name.hasMatch(''), isFalse);
    });
  });

  group('AppRegex.nameBoundary', () {
    const allowed = ['A.', 'Bayo Jr.', 'Olu Snr.', "O'Brien", 'Jean-Paul'];
    const flagged = ['.Ade', "'Ade", '-Ade', ' Ade', "Ade'", 'Ade-', 'Ade '];

    for (final name in allowed) {
      test('allows "$name"', () {
        expect(AppRegex.nameBoundary.hasMatch(name), isFalse);
      });
    }

    for (final name in flagged) {
      test('flags "$name"', () {
        expect(AppRegex.nameBoundary.hasMatch(name), isTrue);
      });
    }
  });
}
