import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../../support/test_config.dart';

class _TestStateModel extends StateModel {}

class _Item extends Equatable {
  const _Item(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

const _failure = TaskError(message: 'Insufficient funds');

TaskCallResponse<_Item> _succeeds([int id = 1]) async =>
    TaskSuccess(data: _Item(id));

TaskCallResponse<_Item> _fails() async => TaskFailure(error: _failure);

TaskCallResponse<_Item> _throws() async => throw StateError('service blew up');

void main() {
  setUpAll(registerTestConfig);

  group('StateModel.executeAction', () {
    test('holds the loading flag for the duration of the action', () async {
      final model = _TestStateModel();
      final gate = Completer<TaskResponse<_Item>>();

      final running = model.executeAction(() => gate.future);
      expect(model.isLoading, isTrue);

      gate.complete(TaskSuccess(data: const _Item(1)));
      await running;

      expect(model.isLoading, isFalse);
    });

    test('hands the data to onSuccess', () async {
      final model = _TestStateModel();
      _Item? received;

      await model.executeAction(
        _succeeds,
        onSuccess: (data) => received = data,
      );

      expect(received, const _Item(1));
    });

    test('hands a reported failure to onError', () async {
      final model = _TestStateModel();
      TaskError? received;

      await model.executeAction(_fails, onError: (error) => received = error);

      expect(received, _failure);
      expect(model.isLoading, isFalse);
    });

    test('a throw becomes the generic failure, not a stuck spinner', () async {
      final model = _TestStateModel();
      TaskError? received;

      await model.executeAction(_throws, onError: (error) => received = error);

      expect(received?.message, 'requestFailedUnexpectedly');
      expect(model.isLoading, isFalse);
    });

    test('a throw out of onSuccess is reported, not swallowed', () async {
      final model = _TestStateModel();
      TaskError? received;

      await model.executeAction(
        _succeeds,
        onSuccess: (_) => throw StateError('callback blew up'),
        onError: (error) => received = error,
      );

      expect(received?.message, 'requestFailedUnexpectedly');
      expect(model.isLoading, isFalse);
    });

    test('refuses to start while an action is already running', () async {
      final model = _TestStateModel();
      final gate = Completer<TaskResponse<_Item>>();
      var calls = 0;

      final first = model.executeAction(() {
        calls++;
        return gate.future;
      });
      final second = await model.executeAction(() {
        calls++;
        return gate.future;
      });

      expect(second, isNull);
      expect(calls, 1);

      gate.complete(TaskSuccess(data: const _Item(1)));
      await first;
    });

    test('the flag is clear before the callbacks run', () async {
      final model = _TestStateModel();
      bool? loadingInCallback;

      await model.executeAction(
        _succeeds,
        onSuccess: (_) => loadingInCallback = model.isLoading,
      );

      expect(loadingInCallback, isFalse);
    });

    test('a success callback can begin the next action', () async {
      final model = _TestStateModel();
      final seen = <int>[];

      await model.executeAction(
        () => _succeeds(1),
        onSuccess: (first) async {
          seen.add(first.id);
          await model.executeAction(
            () => _succeeds(2),
            onSuccess: (second) => seen.add(second.id),
          );
        },
      );

      expect(seen, [1, 2]);
    });

    test('a reply arriving after disposal publishes nothing', () async {
      final model = _TestStateModel();
      final gate = Completer<TaskResponse<_Item>>();
      var published = false;

      final running = model.executeAction(
        () => gate.future,
        onSuccess: (_) => published = true,
      );

      model.dispose();
      gate.complete(TaskSuccess(data: const _Item(1)));
      await running;

      expect(published, isFalse);
    });

    test('a reply arriving after a reset leaves the model reset', () async {
      final model = _TestStateModel();
      final gate = Completer<TaskResponse<_Item>>();

      final running = model.executeAction(() => gate.future);
      model.reset();

      var notifications = 0;
      model.addListener(() => notifications++);

      gate.complete(TaskSuccess(data: const _Item(1)));
      await running;

      expect(model.isLoading, isFalse);
      // The flag was already down, so releasing the hold must not write it
      // again and tell every listener the model changed.
      expect(notifications, 0);
    });

    test('a reply that isCurrent no longer recognises is dropped', () async {
      final model = _TestStateModel();
      var current = true;
      var published = false;

      await model.executeAction(
        () async {
          current = false;
          return TaskSuccess(data: const _Item(1));
        },
        onSuccess: (_) => published = true,
        isCurrent: () => current,
      );

      expect(published, isFalse);
      expect(model.isLoading, isFalse);
    });

    test(
      'an action is refused outright when isCurrent already says no',
      () async {
        final model = _TestStateModel();
        var called = false;

        final response = await model.executeAction(() {
          called = true;
          return _succeeds();
        }, isCurrent: () => false);

        expect(response, isNull);
        expect(called, isFalse);
        expect(model.isLoading, isFalse);
      },
    );

    test('returns the response it ran', () async {
      final model = _TestStateModel();

      expect(await model.executeAction(_succeeds), isA<TaskSuccess<_Item>>());
      expect(await model.executeAction(_fails), isA<TaskFailure<_Item>>());
    });

    test('a failure shouldPublish declines never reaches onError', () async {
      final model = _TestStateModel();
      TaskError? asked;
      var published = false;

      final response = await model.executeAction(
        _fails,
        onError: (_) => published = true,
        shouldPublish: (error) {
          asked = error;
          return false;
        },
      );

      expect(asked, _failure, reason: 'the predicate reads the failure itself');
      expect(published, isFalse);
      expect(response, isA<TaskFailure<_Item>>());
      expect(model.isLoading, isFalse);
    });

    test('a failure shouldPublish accepts is published as before', () async {
      final model = _TestStateModel();
      TaskError? received;

      await model.executeAction(
        _fails,
        onError: (error) => received = error,
        shouldPublish: (_) => true,
      );

      expect(received, _failure);
    });

    test('shouldPublish also gates a throw out of onSuccess', () async {
      final model = _TestStateModel();
      var published = false;

      await model.executeAction(
        _succeeds,
        onSuccess: (_) => throw StateError('callback blew up'),
        onError: (_) => published = true,
        shouldPublish: (_) => false,
      );

      expect(published, isFalse);
      expect(model.isLoading, isFalse);
    });
  });

  group('FutureDataNotifier.executeTask', () {
    test('publishes the data and clears loading', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();

      await notifier.executeTask(_succeeds);

      expect(notifier.data, const _Item(1));
      expect(notifier.isLoading, isFalse);
      expect(notifier.hasError, isFalse);
    });

    test('publishes a reported failure as an error state', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();

      await notifier.executeTask(_fails);

      expect(notifier.error, _failure);
      expect(notifier.isLoading, isFalse);
    });

    test('a throw becomes an error state, not a stuck spinner', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();

      await notifier.executeTask(_throws);

      expect(notifier.error?.message, 'requestFailedUnexpectedly');
      expect(notifier.isLoading, isFalse);
    });

    test('is loading while the task is in flight', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();
      final gate = Completer<TaskResponse<_Item>>();

      final running = notifier.executeTask(() => gate.future);
      expect(notifier.isLoading, isTrue);

      gate.complete(TaskSuccess(data: const _Item(1)));
      await running;

      expect(notifier.isLoading, isFalse);
    });

    test('refuses to start while a task is already running', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();
      final gate = Completer<TaskResponse<_Item>>();

      final first = notifier.executeTask(() => gate.future);
      expect(await notifier.executeTask(_succeeds), isNull);

      gate.complete(TaskSuccess(data: const _Item(1)));
      await first;
    });

    test('a reply arriving after disposal publishes nothing', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();
      final gate = Completer<TaskResponse<_Item>>();

      final running = notifier.executeTask(() => gate.future);
      notifier.dispose();
      gate.complete(TaskSuccess(data: const _Item(1)));
      await running;

      expect(notifier.value.data, isNull);
    });

    test(
      'a reply arriving after a reset leaves the notifier pristine',
      () async {
        final notifier = FutureDataNotifier<_Item>.pristine();
        final gate = Completer<TaskResponse<_Item>>();
        var current = true;

        final running = notifier.executeTask(
          () => gate.future,
          isCurrent: () => current,
        );
        notifier.reset();
        current = false;
        gate.complete(TaskSuccess(data: const _Item(1)));
        await running;

        // A reset restores the pristine state. Lowering a flag that is already
        // down would replace it with a loaded state holding the same nothing,
        // and the screen would show an empty result rather than its first frame.
        expect(notifier.isPristine, isTrue);
        expect(notifier.isLoading, isFalse);
      },
    );

    test('calls onSuccess after the data is published', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();
      _Item? seenInCallback;

      await notifier.executeTask(
        _succeeds,
        onSuccess: (_) => seenInCallback = notifier.data,
      );

      expect(seenInCallback, const _Item(1));
    });

    test('a failure shouldPublish declines writes no error state', () async {
      final notifier = FutureDataNotifier<_Item>.pristine();
      var published = false;

      final response = await notifier.executeTask(
        _fails,
        onError: (_) => published = true,
        shouldPublish: (_) => false,
      );

      expect(notifier.hasError, isFalse);
      expect(published, isFalse);
      expect(notifier.isLoading, isFalse);
      expect(response, isA<TaskFailure<_Item>>());
    });
  });

  group('FutureListDataNotifier.executeTask', () {
    TaskCallResponse<List<_Item>> succeeds() async =>
        TaskSuccess(data: const [_Item(1), _Item(2)]);

    test('publishes the list and clears loading', () async {
      final notifier = FutureListDataNotifier<_Item>.pristine();

      await notifier.executeTask(succeeds);

      expect(notifier.data, const [_Item(1), _Item(2)]);
      expect(notifier.isLoading, isFalse);
    });

    test('a throw becomes an error state, not a stuck spinner', () async {
      final notifier = FutureListDataNotifier<_Item>.pristine();

      await notifier.executeTask(() async => throw StateError('blew up'));

      expect(notifier.error?.message, 'requestFailedUnexpectedly');
      expect(notifier.isLoading, isFalse);
    });

    test('a reply arriving after disposal publishes nothing', () async {
      final notifier = FutureListDataNotifier<_Item>.pristine();
      final gate = Completer<TaskResponse<List<_Item>>>();

      final running = notifier.executeTask(() => gate.future);
      notifier.dispose();
      gate.complete(TaskSuccess(data: const [_Item(1)]));
      await running;

      expect(notifier.value.data, isEmpty);
    });

    test('a failure shouldPublish declines writes no error state', () async {
      final notifier = FutureListDataNotifier<_Item>.pristine();

      await notifier.executeTask(
        () async => TaskFailure(error: _failure),
        shouldPublish: (_) => false,
      );

      expect(notifier.hasError, isFalse);
      expect(notifier.isLoading, isFalse);
    });
  });

  group('PaginatedDataNotifier', () {
    test('an error-only change is published, not swallowed as equal', () {
      final notifier = PaginatedDataNotifier<_Page>.pristine();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier.setError(const TaskError(message: 'boom'));

      expect(notifier.error?.message, 'boom');
      expect(notifications, 1);
    });
  });

  group('PaginatedDataNotifier.executePageTask', () {
    TaskCallResponse<List<_Page>> succeeds() async =>
        TaskSuccess(data: const [_Page('a')]);

    test('hands the page to onData rather than assuming a replace', () async {
      final notifier = PaginatedDataNotifier<_Page>.pristine();
      List<_Page>? page;

      await notifier.executePageTask(succeeds, onData: (data) => page = data);

      expect(page, const [_Page('a')]);
      expect(notifier.isLoading, isFalse);
    });

    test(
      'keeps the loading data on screen while the page is in flight',
      () async {
        final notifier = PaginatedDataNotifier<_Page>.pristine();
        final gate = Completer<TaskResponse<List<_Page>>>();

        final running = notifier.executePageTask(
          () => gate.future,
          onData: (_) {},
          loadingData: const [_Page('stale')],
        );

        expect(notifier.isLoading, isTrue);
        expect(notifier.data, const [_Page('stale')]);

        gate.complete(TaskSuccess(data: const [_Page('a')]));
        await running;
      },
    );

    test('a throw becomes an error state, not a stuck spinner', () async {
      final notifier = PaginatedDataNotifier<_Page>.pristine();

      await notifier.executePageTask(
        () async => throw StateError('blew up'),
        onData: (_) {},
      );

      expect(notifier.error?.message, 'requestFailedUnexpectedly');
      expect(notifier.isLoading, isFalse);
    });

    test('a page arriving after disposal publishes nothing', () async {
      final notifier = PaginatedDataNotifier<_Page>.pristine();
      final gate = Completer<TaskResponse<List<_Page>>>();
      var published = false;

      final running = notifier.executePageTask(
        () => gate.future,
        onData: (_) => published = true,
      );
      notifier.dispose();
      gate.complete(TaskSuccess(data: const [_Page('a')]));
      await running;

      expect(published, isFalse);
    });

    test('a failure shouldPublish declines writes no error state', () async {
      final notifier = PaginatedDataNotifier<_Page>.pristine();
      var published = false;

      await notifier.executePageTask(
        () async => TaskFailure(error: _failure),
        onData: (_) {},
        onError: (_) => published = true,
        shouldPublish: (_) => false,
      );

      expect(notifier.hasError, isFalse);
      expect(published, isFalse);
      expect(notifier.isLoading, isFalse);
    });
  });
}

class _Page extends Equatable implements Identifiable {
  const _Page(this.uuid);

  @override
  final String uuid;

  @override
  List<Object?> get props => [uuid];
}
