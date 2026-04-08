import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class AppCrashlyticsServiceImpl implements AppCrashlyticsService {
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  @override
  Future init() async {
    try {
      FlutterError.onError = (errorDetails) {
        trackError(
          errorDetails.exceptionAsString(),
          error: errorDetails.exception,
          trace: errorDetails.stack,
          fatal: false,
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        trackError("Platform error", error: error, trace: stack, fatal: true);
        return true;
      };
      Isolate.current.addErrorListener(
        RawReceivePort((pair) async {
          final List<dynamic> errorAndStacktrace = pair;
          trackError(
            "Runtime error",
            error: errorAndStacktrace.tryFirst,
            trace: errorAndStacktrace.tryLast,
          );
        }).sendPort,
      );
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  trackError(
    String message, {
    Object? error,
    StackTrace? trace,
    bool fatal = false,
  }) async {
    try {
      AppLogger.severe(message, error: error, stackTrace: trace);
      await crashlytics.recordError(
        error,
        trace,
        fatal: fatal,
        reason: message,
        printDetails: kDebugMode,
      );
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  identifyUser({required id, required String email, String? name}) async {
    try {
      await Future.wait([
        crashlytics.setUserIdentifier("$id"),
        crashlytics.setCustomKey("user_email", email),
        if (name != null) crashlytics.setCustomKey("user_name", name),
      ]);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}
