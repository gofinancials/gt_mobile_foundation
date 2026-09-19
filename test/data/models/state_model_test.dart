import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class _TestStateModel extends StateModel {}

void main() {
  group('StateModel Tests', () {
    test('isDisposed is false until dispose is called', () {
      final model = _TestStateModel();
      expect(model.isDisposed, isFalse);

      model.dispose();
      expect(model.isDisposed, isTrue);
    });

    test('isLoading setter updates state and notifies before disposal', () {
      final model = _TestStateModel();
      var notified = 0;
      model.addListener(() => notified++);

      model.isLoading = true;

      expect(model.isLoading, isTrue);
      expect(notified, 1);
    });

    test('isLoading setter is a no-op after disposal', () {
      final model = _TestStateModel();
      model.dispose();

      expect(() => model.isLoading = true, returnsNormally);
      expect(model.isLoading, isFalse);
    });

    test('reset clears isLoading and notifies before disposal', () {
      final model = _TestStateModel();
      model.isLoading = true;
      var notified = 0;
      model.addListener(() => notified++);

      model.reset();

      expect(model.isLoading, isFalse);
      expect(notified, 1);
    });

    test('reset is a no-op after disposal', () {
      final model = _TestStateModel();
      model.dispose();

      expect(() => model.reset(), returnsNormally);
    });
  });
}
