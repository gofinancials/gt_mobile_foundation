import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Mixins}
/// A mixin that provides safe execution wrappers for tasks and automatic
/// crash reporting for unexpected errors.
mixin AppTaskMixin {
  /// Internal helper to report caught errors to the [AppCrashlyticsService].
  _reportError(String tag, Object? error, StackTrace trace) {
    final crashReporter = locator<AppCrashlyticsService>();
    crashReporter.trackError(tag, error: error, trace: trace);
  }

  /// Executes a synchronous [func] safely, catching and reporting any exceptions.
  ///
  /// If an error occurs, it reports it to Crashlytics. If [onError] is provided,
  /// its result is returned; otherwise, the exception is rethrown.
  T runThrowableTask<T>(FunctionCall<T> func, {FunctionCall<T>? onError}) {
    try {
      return func();
    } catch (e, t) {
      _reportError("$e", e, t);
      if (onError != null) return onError();
      rethrow;
    }
  }

  /// Attempts to run [func] safely, returning null if an exception is thrown.
  ///
  /// Any thrown exceptions are automatically caught and reported.
  T? tryRunThrowableTask<T>(FunctionCall<T> func) {
    return runThrowableTask(func, onError: () => null);
  }
}
