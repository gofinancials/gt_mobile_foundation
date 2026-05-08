import 'dart:developer';

import 'package:flutter/foundation.dart';

/// {@category Utilities}
/// A simple logger wrapper that prints colored output only in debug mode.
class AppLogger {
  /// Logs an informational [data] message in green.
  static info(dynamic data) {
    if (!kDebugMode) return;
    log(
      "MESSAGE -> \x1B[32m$data\x1B[0m",
      time: _now,
      name: "$_tag<>INFO",
      level: 1,
    );
  }

  /// Logs a severe/error [message] in red with optional [stackTrace] and [error] details.
  static severe(dynamic message, {StackTrace? stackTrace, Object? error}) {
    if (!kDebugMode) return;
    log(
      "ERROR -> \x1B[31m$message\x1B[0m",
      time: _now,
      stackTrace: stackTrace,
      error: error,
      name: "$_tag<>ERROR",
      level: 2,
    );
  }

  /// Updates the default logging prefix tag.
  static setTag(String tag) => _tag = tag;

  static DateTime get _now => DateTime.now();
  static String _tag = "GT";
}
