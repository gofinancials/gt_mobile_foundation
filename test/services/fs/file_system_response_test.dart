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
      expect(error.hasNoFile, isTrue);
    });

    test('hasNoFile covers both ways of coming back without a file', () {
      expect(const FsError(type: .empty).hasNoFile, isTrue);
      expect(const FsError(type: .cancelled).hasNoFile, isTrue);
      expect(const FsError(type: .oversized).hasNoFile, isFalse);
      expect(const FsError(type: .unknown).hasNoFile, isFalse);
    });

    test('the deprecated isEmpty still answers as hasNoFile', () {
      // ignore: deprecated_member_use_from_same_package
      expect(const FsError(type: .empty).isEmpty, isTrue);
      // ignore: deprecated_member_use_from_same_package
      expect(const FsError(type: .cancelled).isEmpty, isTrue);
      // ignore: deprecated_member_use_from_same_package
      expect(const FsError(type: .oversized).isEmpty, isFalse);
    });

    test('an oversized file reports only its own type', () {
      const error = FsError(type: .oversized);

      expect(error.isTooLarge, isTrue);
      expect(error.isCancelled, isFalse);
      expect(error.isUnknown, isFalse);
    });
  });

  group('FsResponse', () {
    FsResponse responseWith(FsErrorType type) =>
        FsResponse(type: .document, error: FsError(type: type));

    test('a dismissal is both cancelled and an absent selection', () {
      final response = responseWith(.cancelled);

      expect(response.wasCancelled, isTrue);
      expect(response.hasNoSelection, isTrue);
    });

    test('an empty pick is an absent selection but not a dismissal', () {
      final response = responseWith(.empty);

      expect(response.wasCancelled, isFalse);
      expect(response.hasNoSelection, isTrue);
    });

    test('a failure is neither, so callers still report it', () {
      for (final type in [FsErrorType.oversized, FsErrorType.unknown]) {
        final response = responseWith(type);

        expect(response.wasCancelled, isFalse, reason: '$type');
        expect(response.hasNoSelection, isFalse, reason: '$type');
      }
    });

    test('a response without an error answers false rather than null', () {
      const response = FsResponse(type: .document);

      expect(response.hasError, isFalse);
      expect(response.wasCancelled, isFalse);
      expect(response.hasNoSelection, isFalse);
    });
  });
}
