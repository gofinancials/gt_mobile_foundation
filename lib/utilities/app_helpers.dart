import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Utilities}
/// A collection of miscellaneous helper functions including JSON parsing,
/// connection checking, file size calculation, and error extraction.
class AppHelpers {
  static bool get randomBool {
    final list = [true, false];
    list.shuffle();
    return list.first;
  }

  static FutureOr<dynamic> _parseAndDecode(String response) {
    return jsonDecode(response);
  }

  static FutureOr<dynamic> parseJson(String text) {
    try {
      if (text.codeUnits.length < 50 * 1024) return _parseAndDecode(text);
      return compute(_parseAndDecode, text);
    } catch (e, t) {
      AppLogger.severe("JSON parsing failed: $e", stackTrace: t, error: e);
      return null;
    }
  }

  static FutureOr<String> _parseAndEncode(Object data) {
    return jsonEncode(data);
  }

  static FutureOr<String> encodeJson(Object data) {
    try {
      if ("$data".codeUnits.length < 50 * 1024) return _parseAndEncode(data);
      return compute(_parseAndEncode, data);
    } catch (e, t) {
      AppLogger.severe("JSON encoding failed: $e", stackTrace: t, error: e);
      return "";
    }
  }

  static double fileSizeInMb(File file) {
    final bytes = file.lengthSync();
    return bytes / 1048576;
  }

  static Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.tryFirst?.rawAddress.isNotEmpty ?? false;
    } catch (_) {
      return false;
    }
  }

  static num? extractAmount(String? amount) {
    if (!amount.hasValue) return null;

    final pattern = RegExp(r"(\$|£|€|N)");
    final val = (amount!.startsWith(pattern) ? amount.substring(1) : amount)
        .trim();
    final number = num.tryParse(val.replaceAll(RegExp(r'[^0-9\.]'), "").trim());
    return number;
  }

  static Map<String, dynamic> parseError(
    dynamic error, {
    String defaultMessage = "",
  }) {
    try {
      if (error is SocketException) {
        final data = error.message;
        int? code = error.osError?.errorCode;
        return {"message": data, "statusCode": code ?? 500};
      }

      if (error is TimeoutException) {
        final data = error.message;
        return {"message": data, "statusCode": 408};
      }

      if (error is String) {
        return {"message": error, "statusCode": 500};
      }

      if (error is DioException) {
        final data = error.response?.data;
        int? code = error.response?.statusCode;
        String message = error.message ?? defaultMessage;

        if (data is Map) {
          return _parseErrorMap(
            data,
            defaultMessage: defaultMessage,
            statusCode: code ?? 500,
          );
        }

        return {"message": message, "statusCode": code ?? 500};
      }

      if (error is Map) {
        return _parseErrorMap(error, defaultMessage: defaultMessage);
      }

      return {"message": defaultMessage, "statusCode": 500};
    } catch (_) {
      return {"message": defaultMessage, "statusCode": 500};
    }
  }

  static _parseErrorMap(
    Map error, {
    String defaultMessage = "",
    int statusCode = 500,
  }) {
    int? code = int.tryParse(error["responseCode"]) ?? statusCode;
    if (error.containsKey("message") &&
        error["message"] != null &&
        error["message"] is String) {
      final String message = error["message"] ?? "";
      return {"message": message, "statusCode": code};
    } else if (error["error"] != null &&
        error["error"] is String &&
        error["error"].isNotEmpty) {
      return {"message": error["error"], "statusCode": code};
    } else if (error.containsKey("statusMessage") &&
        error["statusMessage"] != null &&
        error["statusMessage"] is String) {
      final String message = error["statusMessage"] ?? "";
      return {"message": message, "statusCode": code};
    } else {
      if (error.containsKey("data") && error["data"] != null) {
        return parseError(error["data"]);
      }
      return {"message": defaultMessage, "statusCode": code};
    }
  }

  static updateValue(
    String char,
    TextEditingController controller, {
    required int limit,
  }) {
    String value = controller.text;

    if (char.lower == 'x') {
      final currentText = value;
      if (currentText.isEmpty) return;
      if (currentText.length == 1) value = '';
      value = currentText.substring(0, currentText.length - 1);
      controller.text = value;
      return;
    }

    if (value.length >= limit) return;

    value += char;
    controller.text = value;
  }

  static String? getInitials(String? name) {
    if (!name.hasValue) return null;

    final names = name!.trim().split(" ");

    if (names.length == 1) {
      final part = names.first;
      return (part.length > 1 ? "${part[0]}${part[1]}" : part[0]).upper;
    }

    final head = names.first[0];
    final tail = names.last[0];

    return "$head$tail".upper;
  }

  static String? getAccronym(String? name) {
    try {
      if (!name.hasValue) return null;

      final names = name!.trim().split(" ");

      final initials = names
          .whereList((it) => it.hasValue)
          .mapList((it) => it[0].upper);

      return initials.join("");
    } catch (_) {
      return null;
    }
  }

  static Stream<int> countDown([int seconds = 59]) async* {
    int i = seconds;
    while (i >= 0) {
      yield i--;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
