import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('FsError', () {
    test('a dismissed picker is cancelled, not a failure', () {
      const error = FsError(type: .cancelled);

      expect(error.isCancelled, isTrue);
      expect(error.isUnknown, isFalse);
      expect(error.isTooLarge, isFalse);
    });

    test('an empty result is not a cancellation', () {
      const error = FsError(type: .empty);

      expect(error.isCancelled, isFalse);
      expect(error.isEmpty, isTrue);
    });

    test('isEmpty covers both ways of coming back without a file', () {
      expect(const FsError(type: .empty).isEmpty, isTrue);
      expect(const FsError(type: .cancelled).isEmpty, isTrue);
      expect(const FsError(type: .oversized).isEmpty, isFalse);
      expect(const FsError(type: .unknown).isEmpty, isFalse);
    });

    test('an oversized file reports only its own type', () {
      const error = FsError(type: .oversized);

      expect(error.isTooLarge, isTrue);
      expect(error.isCancelled, isFalse);
      expect(error.isUnknown, isFalse);
    });
  });
}
