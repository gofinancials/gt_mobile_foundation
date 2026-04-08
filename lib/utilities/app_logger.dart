import 'dart:developer';

import 'package:flutter/foundation.dart';

class AppLogger {
  static info(dynamic data) {
    if (!kDebugMode) return;
    log(
      "MESSAGE -> \x1B[32m$data\x1B[0m",
      time: _now,
      name: "$_tag<>INFO",
      level: 1,
    );
  }

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

  static setTag(String tag) => _tag = tag;

  static DateTime get _now => DateTime.now();
  static String _tag = "GT";
}
