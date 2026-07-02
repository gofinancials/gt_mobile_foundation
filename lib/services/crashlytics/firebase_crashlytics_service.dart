import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// An implementation of [AppCrashlyticsService] that integrates with Firebase Crashlytics.
///
/// This service is responsible for initializing global error handlers across the
/// Flutter framework, platform dispatcher, and current isolate to automatically
/// catch and report unhandled exceptions. It also provides methods to manually
/// log errors and identify users for crash tracking context.
class AppCrashlyticsServiceImpl implements AppCrashlyticsService {
  /// Provides direct access to the underlying [FirebaseCrashlytics] instance.
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  /// Initializes global error listeners to automatically catch and report crashes.
  ///
  /// This configures handlers for:
  /// - `FlutterError.onError`: UI and framework-level errors.
  /// - `PlatformDispatcher.instance.onError`: Asynchronous platform-level errors.
  /// - `Isolate.current.addErrorListener`: Unhandled errors outside the root isolate.
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

  /// Manually records a non-fatal or fatal error to Firebase Crashlytics.
  ///
  /// The [message] serves as the primary reason or context for the crash, while
  /// the raw [error] object and [trace] are sent for stack analysis. Setting [fatal]
  /// to `true` marks the error as a critical crash event in the dashboard.
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

  /// Associates the active user with future crash reports to aid in debugging.
  ///
  /// Sets the primary user identifier to [id], and attaches the [accountNumber]
  /// and optional [name] as custom crashlytics keys. These keys will appear alongside
  /// any crash logs submitted during the user's session.
  @override
  identifyUser({
    required dynamic id,
    required String accountNumber,
    String? name,
  }) async {
    try {
      await Future.wait([
        crashlytics.setUserIdentifier("$id"),
        crashlytics.setCustomKey("account_number", accountNumber),
        if (name.hasValue) crashlytics.setCustomKey("user_name", name.value),
      ]);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}
