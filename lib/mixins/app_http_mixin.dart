import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Mixins}
/// A mixin that provides safe network request handling and error parsing
/// for repositories or services interacting with HTTP APIs.
mixin AppHttpMixin {
  /// Internal helper to parse an arbitrary [error] into a standard [TaskError].
  TaskError _getParsedError(dynamic error) {
    final errorData = AppHelpers.parseError(
      error,
      defaultMessage: stringKeys.requestFailedUnexpectedly.tr(),
    );
    return TaskError(
      message: errorData["message"] ?? "",
      statusCode: errorData["statusCode"],
      error: error,
    );
  }

  /// Internal helper to report caught network errors to the [AppCrashlyticsService].
  _reportError(String tag, Object? error, StackTrace trace) {
    final crashReporter = locator<AppCrashlyticsService>();
    crashReporter.trackError(tag, error: error, trace: trace);
  }

  /// Executes an asynchronous network [func] and returns a [TaskResponse].
  ///
  /// This wrapper catches [DioException], [SocketException], [TimeoutException],
  /// and any other arbitrary errors, parses them, and returns a [TaskFailure].
  /// If successful, it returns a [TaskSuccess] containing the data of type [T].
  ///
  /// In debug mode, it also logs the duration of the request.
  Future<TaskResponse<T>> requestHandler<T>(FutureCall<T> func) async {
    try {
      final watch = Stopwatch();
      if (kDebugMode) watch.start();
      final result = await func();
      if (kDebugMode) {
        watch.stop();
        AppLogger.info("Request took ${watch.elapsed.inMilliseconds / 1000}s");
      }
      return TaskSuccess(data: result);
    } on SocketException catch (e, t) {
      _reportError("DioException: ${e.message}", e, t);
      return TaskFailure(error: _getParsedError(e));
    } on DioException catch (e, t) {
      _reportError("DioException: ${e.message}", e, t);
      return TaskFailure(error: _getParsedError(e));
    } on TaskError catch (e, t) {
      _reportError("TaskError: ${e.message}", e, t);
      return TaskFailure(error: e);
    } on TimeoutException catch (e, t) {
      _reportError("NetworkTimeout: ${e.message}", e, t);
      return TaskFailure(error: _getParsedError(e));
    } catch (e, t) {
      _reportError("UnknownError: $e", e, t);
      return TaskFailure(error: _getParsedError(e));
    }
  }
}
