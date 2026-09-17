import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// Tracks whether a [ChangeNotifier] has been disposed, so that writes
/// arriving after disposal (e.g. from a request that resolves after its
/// screen has closed) can be silently ignored instead of tripping the
/// "used after being disposed" assertion.
mixin DisposalAware on ChangeNotifier {
  bool _isDisposed = false;

  /// Identifies the call currently holding this object's loading flag, so a
  /// late reply releases only its own hold and never one a newer call took.
  Object? _taskHolder;

  /// Whether [dispose] has already been called on this instance.
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Runs [task] under this object's loading flag.
  ///
  /// The sequence every caller would otherwise write by hand: refuse to start
  /// while a task is already running, raise the loading flag, await, turn a
  /// throw into a [TaskFailure] carrying [AppConfigStrings
  /// .requestFailedUnexpectedly], clear the flag, and then publish. A write
  /// arriving after disposal, or after [isCurrent] stops agreeing, is dropped
  /// rather than applied — the reply outlived what asked for it.
  ///
  /// The flag is cleared *before* the callbacks run, because a success
  /// callback may begin the next action and would otherwise meet an object
  /// that is still loading.
  ///
  /// Returns the task's response, or `null` when the call was refused because
  /// one was already running.
  @protected
  Future<TaskResponse<T>?> runGuardedTask<T>(
    TaskCallResponse<T> Function() task, {
    required bool Function() isLoading,
    required void Function() setLoading,
    required void Function() clearLoading,
    required FutureOr<void> Function(T data) onData,
    required void Function(TaskError error) onFailure,
    bool Function()? isCurrent,
  }) async {
    if (isLoading() || isDisposed || isCurrent?.call() == false) return null;

    final holder = _taskHolder = Object();
    setLoading();

    final response = await _guarded(task);

    // Release this call's hold before anything reads the flag, but only if a
    // newer call has not taken it in the meantime.
    if (identical(_taskHolder, holder)) clearLoading();

    if (isDisposed || isCurrent?.call() == false) return response;

    try {
      switch (response) {
        case TaskSuccess(:final data):
          await onData(data);
        case TaskFailure(:final error):
          onFailure(error);
      }
    } catch (error, trace) {
      // A callback of the caller's own can throw too, and a screen left
      // showing nothing is worse than one showing the generic failure.
      if (isDisposed || isCurrent?.call() == false) return response;
      onFailure(_unexpectedFailure(error, trace));
    }

    return response;
  }

  Future<TaskResponse<T>> _guarded<T>(
    TaskCallResponse<T> Function() task,
  ) async {
    try {
      return await task();
    } catch (error, trace) {
      return TaskFailure(error: _unexpectedFailure(error, trace));
    }
  }

  TaskError _unexpectedFailure(Object error, StackTrace trace) {
    AppLogger.severe(
      "Unexpected state task failure",
      error: error,
      stackTrace: trace,
    );
    return TaskError(
      message: stringKeys.requestFailedUnexpectedly.tr(),
      error: error,
    );
  }
}

/// {@category Data}
/// A foundational state class that provides a standardized loading flag for ViewModels.
abstract class StateModel extends ChangeNotifier with DisposalAware {
  bool _isLoading = false;

  set isLoading(bool state) {
    if (isDisposed) return;
    _isLoading = state;
    notifyListeners();
  }

  get isLoading => _isLoading;

  reset() {
    if (isDisposed) return;
    _isLoading = false;
    notifyListeners();
  }

  /// Runs [action] under this model's loading flag.
  ///
  /// A throw becomes the generic failure message rather than a stuck spinner,
  /// and a model that has been disposed, or that [isCurrent] no longer
  /// recognises, ignores the reply entirely. Pass [isCurrent] to fence a reply
  /// against state the caller owns — a superseded session, say.
  ///
  /// Returns the response, or `null` when the model was already loading.
  Future<TaskResponse<T>?> executeAction<T>(
    TaskCallResponse<T> Function() action, {
    FutureOr<void> Function(T data)? onSuccess,
    OnChanged<TaskError>? onError,
    bool Function()? isCurrent,
  }) {
    return runGuardedTask(
      action,
      isLoading: () => isLoading,
      setLoading: () => isLoading = true,
      clearLoading: () => isLoading = false,
      onData: (data) async => onSuccess?.call(data),
      onFailure: (error) => onError?.call(error),
      isCurrent: isCurrent,
    );
  }
}
