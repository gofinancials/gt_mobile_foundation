import 'package:flutter/foundation.dart';
import 'dart:async';

/// {@category Utilities}
/// A utility class that debounces rapidly firing events or function calls.
///
/// Useful for scenarios like search inputs where you want to wait for the
/// user to stop typing before making an API call.
class AppDebouncer {
  /// The duration to wait before executing the action.
  final Duration delay;
  Timer? _timer;

  /// Creates an [AppDebouncer] with the specified [delay].
  AppDebouncer(this.delay);

  /// Returns `true` if the debouncer is currently waiting to execute an action.
  bool get isActive => _timer?.isActive ?? false;

  /// Schedules the [action] to be run after the [delay].
  ///
  /// If [run] is called again before the delay expires, the previous timer is aborted.
  run(VoidCallback action) {
    if (_timer != null) abort();
    _timer = Timer(delay, action);
  }

  /// Cancels the currently scheduled action, if any.
  void abort() {
    if (_timer == null) return;
    if (!_timer!.isActive) return;
    _timer!.cancel();
  }
}
