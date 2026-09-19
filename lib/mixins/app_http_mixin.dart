import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Mixins}
/// A mixin that provides safe network request handling and error parsing
/// for repositories or services interacting with HTTP APIs.
///
/// A call fails in two places, so it is guarded in two: [requestHandler] guards
/// sending the request, [decodeHandler] guards reading what it answered.
/// Together they are what lets a [TaskCallResponse] report a failure as a
/// [TaskFailure] rather than a rejected future.
///
/// Both build their failure from the registered [AppConfig]'s strings, so that
/// holds only once one is registered: without it the guard's own message
/// lookup throws, and that does reject.
mixin AppHttpMixin {
  /// Internal helper to parse an arbitrary [error] into a standard [TaskError].
  TaskError _getParsedError(dynamic error) {
    final errorData = AppHelpers.parseError(
      error,
      defaultMessage: stringKeys.requestFailedUnexpectedly.tr(),
    );
    return TaskError(
      message: errorData["message"] ?? "",
      statusCode: "${errorData["statusCode"]}",
      error: error,
    );
  }

  /// Internal helper to report caught network errors to the [AppCrashlyticsService].
  _reportError(String tag, Object? error, StackTrace trace) {
    if (!locator.isRegistered<AppCrashlyticsService>()) return;
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
      _reportError("SocketException: ${e.message}", e, t);
      return TaskFailure(error: _getParsedError(e));
    } on DioException catch (e, t) {
      _reportError("DioException: ${e.message}", e, t);
      return TaskFailure(error: _getParsedError(e));
    } on TimeoutException catch (e, t) {
      _reportError("NetworkTimeout: ${e.message}", e, t);
      return TaskFailure(error: _getParsedError(e));
    } catch (e, t) {
      _reportError("UnknownError: $e", e, t);
      return TaskFailure(error: _getParsedError(e));
    }
  }

  /// Reads a reply the gateway already answered with, returning a
  /// [TaskFailure] when [decode] cannot read it.
  ///
  /// [requestHandler] guards the request; this guards its answer, which is the
  /// one failure the request guard cannot see — [decode] belongs to the caller
  /// and runs after the request returned. A decoder throws whenever a `200`
  /// carries a shape the contract did not promise, and an unguarded throw
  /// leaves the [TaskCallResponse] rejecting rather than failing: inside a
  /// state task that is reported as a bug in the state layer, and outside one
  /// nothing catches it at all.
  ///
  /// The failure is its own kind rather than the generic one. It carries
  /// [AppConfigStrings.malformedResponse], because the request did not fail —
  /// its answer did, and repeating it changes nothing. It is tagged
  /// `MalformedResponse:` in Crashlytics, so a gateway contract drift is not
  /// filed among transport errors. And it keeps [statusCode], the status the
  /// reply actually arrived with, rather than the `500` an unparsed error
  /// falls back to: nothing here went wrong at the server.
  ///
  /// Crashlytics is told the type of the failure and never what it said. A
  /// decoder's exception quotes what it could not read — a [FormatException]
  /// carries its source text, a hand-written one the value it rejected — and
  /// that is the customer's payload. The caller still receives the exception
  /// itself on [TaskError.error], which never leaves the device.
  Future<TaskResponse<T>> decodeHandler<T>(
    FutureCall<T> decode, {
    String statusCode = "200",
  }) async {
    try {
      return TaskSuccess(data: await decode());
    } catch (e, t) {
      // Crashlytics records the reported object's own `toString`, so the tag
      // alone is not enough: the exception has to be replaced too. The trace
      // still says where it was thrown.
      final reported = _UnreadableReply(e.runtimeType);
      _reportError("$reported", reported, t);
      return TaskFailure(
        error: TaskError(
          message: stringKeys.malformedResponse.tr(),
          statusCode: statusCode,
          error: e,
        ),
      );
    }
  }
}

/// What Crashlytics is told when a reply could not be decoded: the type of the
/// failure, and nothing the failure said.
class _UnreadableReply implements Exception {
  const _UnreadableReply(this.cause);

  /// The type of the exception the decoder threw.
  final Type cause;

  @override
  String toString() => "MalformedResponse: $cause";
}
