import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

mixin AppHttpMixin {
  NetworkError _getParsedError(dynamic error) {
    final errorData = AppHelpers.parseError(
      error,
      defaultMessage: stringKeys.requestFailedUnexpectedly.tr(),
    );
    return NetworkError(
      message: errorData["message"] ?? "",
      statusCode: errorData["statusCode"],
      error: error,
    );
  }

  _reportError(String tag, Object? error, StackTrace trace) {
    final crashReporter = locator<AppCrashlyticsService>();
    crashReporter.trackError(tag, error: error, trace: trace);
  }

  Future<NetworkResponse<T>> requestHandler<T>(FutureCall<T> func) async {
    try {
      final watch = Stopwatch();
      if (kDebugMode) watch.start();
      final result = await func();
      if (kDebugMode) {
        watch.stop();
        AppLogger.info("Request took ${watch.elapsed.inMilliseconds / 1000}s");
      }
      return NetworkSuccess(data: result);
    } on SocketException catch (e, t) {
      _reportError("DioException: ${e.message}", e, t);
      return NetworkFailure(error: _getParsedError(e));
    } on DioException catch (e, t) {
      _reportError("DioException: ${e.message}", e, t);
      return NetworkFailure(error: _getParsedError(e));
    } on NetworkError catch (e, t) {
      _reportError("NetworkError: ${e.message}", e, t);
      return NetworkFailure(error: e);
    } on TimeoutException catch (e, t) {
      _reportError("NetworkTimeout: ${e.message}", e, t);
      return NetworkFailure(error: _getParsedError(e));
    } catch (e, t) {
      _reportError("UnknownError: $e", e, t);
      return NetworkFailure(error: _getParsedError(e));
    }
  }
}
