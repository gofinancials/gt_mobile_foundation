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
  /// [isCurrent] speaks for the caller; [shouldPublish] speaks for the
  /// failure. Some failures are nobody's fault and not worth a screen — the
  /// calls a session renewal supersedes all fail together — and whether that
  /// is so is read off the [TaskError] itself. A failure it declines never
  /// reaches [onFailure], so no error state is written and no callback runs;
  /// the response is still returned. It is asked before [onFailure], not
  /// inside it, because once [onFailure] runs the failure is already shown.
  ///
  /// The flag is cleared *before* the callbacks run, because a success
  /// callback may begin the next action and would otherwise meet an object
  /// that is still loading.
  ///
  /// Returns the task's response, or `null` when the call was refused because
  /// one was already running.
  @protected
  Future<TaskResponse<T>?> runGuardedTask<T>(
    FutureCall<TaskResponse<T>> task, {
    required FunctionCall<bool> isLoading,
    required OnPressed setLoading,
    required OnPressed clearLoading,
    required OnChangedMaybeAsync<T> onData,
    required OnChanged<TaskError> onFailure,
    FunctionCall<bool>? isCurrent,
    OnBoolValidation<TaskError>? shouldPublish,
  }) async {
    if (isLoading() || isDisposed || isCurrent?.call() == false) return null;

    final holder = _taskHolder = Object();
    setLoading();

    final response = await _guarded(task);

    // Release this call's hold before anything reads the flag, but only if a
    // newer call has not taken it in the meantime — and only if the flag is
    // still raised. A `reset` lowers it and restores the pristine state, and
    // clearing a flag that is already clear is not free: it writes a value,
    // so the reset state would be overwritten by a loaded one carrying the
    // same emptiness, and every listener would be told about it.
    if (identical(_taskHolder, holder) && isLoading()) clearLoading();

    if (isDisposed || isCurrent?.call() == false) return response;

    void publishFailure(TaskError error) {
      if (shouldPublish?.call(error) == false) return;
      onFailure(error);
    }

    try {
      switch (response) {
        case TaskSuccess(:final data):
          await onData(data);
        case TaskFailure(:final error):
          publishFailure(error);
      }
    } catch (error, trace) {
      // A callback of the caller's own can throw too, and a screen left
      // showing nothing is worse than one showing the generic failure.
      if (isDisposed || isCurrent?.call() == false) return response;
      publishFailure(_unexpectedFailure(error, trace));
    }

    return response;
  }

  Future<TaskResponse<T>> _guarded<T>(FutureCall<TaskResponse<T>> task) async {
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
  /// against state the caller owns, and [shouldPublish] to keep a failure
  /// that is not worth showing — one a superseded session caused, say — from
  /// reaching [onError] at all.
  ///
  /// Returns the response, or `null` when the model was already loading.
  Future<TaskResponse<T>?> executeAction<T>(
    FutureCall<TaskResponse<T>> action, {
    OnChangedMaybeAsync<T>? onSuccess,
    OnChanged<TaskError>? onError,
    FunctionCall<bool>? isCurrent,
    OnBoolValidation<TaskError>? shouldPublish,
  }) {
    return runGuardedTask(
      action,
      isLoading: () => isLoading,
      setLoading: () => isLoading = true,
      clearLoading: () => isLoading = false,
      onData: (data) async => onSuccess?.call(data),
      onFailure: (error) => onError?.call(error),
      isCurrent: isCurrent,
      shouldPublish: shouldPublish,
    );
  }
}
