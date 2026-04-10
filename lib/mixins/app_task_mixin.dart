import 'package:gt_mobile_foundation/foundation.dart';

mixin AppTaskMixin {
  _reportError(String tag, Object? error, StackTrace trace) {
    final crashReporter = locator<AppCrashlyticsService>();
    crashReporter.trackError(tag, error: error, trace: trace);
  }

  T runThrowableTask<T>(FunctionCall<T> func, {FunctionCall<T>? onError}) {
    try {
      return func();
    } catch (e, t) {
      _reportError("$e", e, t);
      if (onError != null) return onError();
      rethrow;
    }
  }

  T? tryRunThrowableTask<T>(FunctionCall<T> func) {
    return runThrowableTask(func, onError: () => null);
  }
}
