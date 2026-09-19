import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class _Item extends Equatable {
  final String value;
  const _Item(this.value);

  @override
  List<Object?> get props => [value];
}

class _IdentifiableItem extends Identifiable {
  const _IdentifiableItem(String uuid) : super(uuid: uuid);
}

const _error = TaskError(message: 'failed');

void main() {
  group('FutureDataNotifier disposal', () {
    test('isDisposed is false until dispose is called', () {
      final notifier = FutureDataNotifier<_Item>.pristine();
      expect(notifier.isDisposed, isFalse);

      notifier.dispose();
      expect(notifier.isDisposed, isTrue);
    });

    test('writes after disposal are ignored', () {
      final notifier = FutureDataNotifier<_Item>.pristine();
      notifier.dispose();

      expect(() => notifier.setLoading(), returnsNormally);
      expect(() => notifier.setData(const _Item('a')), returnsNormally);
      expect(() => notifier.setError(_error), returnsNormally);
      expect(() => notifier.reset(), returnsNormally);
      expect(() => notifier.updateWith(isLoading: true), returnsNormally);
    });
  });

  group('FutureListDataNotifier disposal', () {
    test('isDisposed is false until dispose is called', () {
      final notifier = FutureListDataNotifier<_Item>.pristine();
      expect(notifier.isDisposed, isFalse);

      notifier.dispose();
      expect(notifier.isDisposed, isTrue);
    });

    test('writes after disposal are ignored', () {
      final notifier = FutureListDataNotifier<_Item>.pristine();
      notifier.dispose();

      const item = _Item('a');
      expect(() => notifier.setLoading(), returnsNormally);
      expect(() => notifier.setData([item]), returnsNormally);
      expect(() => notifier.setError(_error), returnsNormally);
      expect(() => notifier.reset(), returnsNormally);
      expect(() => notifier.updateWith(isLoading: true), returnsNormally);
      expect(
        () => notifier.updateSingleItem(item, const _Item('b')),
        returnsNormally,
      );
      expect(() => notifier.removeSingleItem(item), returnsNormally);
    });
  });

  group('PaginatedDataNotifier disposal', () {
    test('isDisposed is false until dispose is called', () {
      final notifier = PaginatedDataNotifier<_IdentifiableItem>.pristine();
      expect(notifier.isDisposed, isFalse);

      notifier.dispose();
      expect(notifier.isDisposed, isTrue);
    });

    test('writes after disposal are ignored', () {
      final notifier = PaginatedDataNotifier<_IdentifiableItem>.pristine();
      notifier.dispose();

      const item = _IdentifiableItem('1');
      expect(() => notifier.setLoading(), returnsNormally);
      expect(() => notifier.setData([item]), returnsNormally);
      expect(() => notifier.setError(_error), returnsNormally);
      expect(() => notifier.reset(), returnsNormally);
      expect(() => notifier.updateWith(isLoading: true), returnsNormally);
      expect(
        () => notifier.updateSingleItem(item, const _IdentifiableItem('2')),
        returnsNormally,
      );
      expect(() => notifier.removeSingleItem(item), returnsNormally);
      expect(() => notifier.addSingleItem(item), returnsNormally);
      expect(
        () => notifier.addData(PaginatedData.pristine()),
        returnsNormally,
      );
    });
  });
}
