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

  /// Payload size, in UTF-16 code units, beyond which JSON work is moved to a
  /// background isolate. Mirrors the threshold Dio's own transformer uses.
  static const _jsonIsolateThreshold = 50 * 1024;

  static FutureOr<dynamic> _parseAndDecode(String response) {
    return jsonDecode(response);
  }

  /// Decodes [text] as JSON, moving the work to a background isolate once the
  /// payload is large enough for the parse to drop frames.
  ///
  /// Returns `null` if decoding fails, whether it failed on this isolate or in
  /// the background one.
  static FutureOr<dynamic> parseJson(String text) {
    try {
      // `String.length` is O(1). Measuring UTF-8 bytes instead would allocate a
      // full copy of every payload just to pick a branch, which costs more than
      // the parse it is meant to protect.
      if (text.length < _jsonIsolateThreshold) return _parseAndDecode(text);
      return compute(_parseAndDecode, text).catchError(_onParseFailure);
    } catch (e, t) {
      return _onParseFailure(e, t);
    }
  }

  static Null _onParseFailure(Object e, StackTrace t) {
    AppLogger.severe("JSON parsing failed: $e", stackTrace: t, error: e);
    return null;
  }

  static FutureOr<String> _parseAndEncode(Object data) {
    return jsonEncode(data);
  }

  /// Encodes [data] as a JSON string.
  ///
  /// Unlike [parseJson] there is no cheap way to size the payload up front —
  /// measuring it means encoding it — so the encode runs on the calling isolate
  /// by default. Pass [inBackground] when the caller already knows the payload
  /// is large enough to justify the isolate hop.
  ///
  /// Returns an empty string if encoding fails.
  static FutureOr<String> encodeJson(Object data, {bool inBackground = false}) {
    try {
      if (!inBackground) return _parseAndEncode(data);
      return compute(_parseAndEncode, data).catchError(_onEncodeFailure);
    } catch (e, t) {
      return _onEncodeFailure(e, t);
    }
  }

  static String _onEncodeFailure(Object e, StackTrace t) {
    AppLogger.severe("JSON encoding failed: $e", stackTrace: t, error: e);
    return "";
  }

  static double fileSizeInMb(File file) {
    final bytes = file.lengthSync();
    return bytes / 1048576;
  }

  /// Host probed when [hasConnection] is called without one.
  ///
  /// `example.com` is reserved by IANA (RFC 6761) and belongs to no commercial
  /// operator, so it resolves worldwide and cannot be repurposed or withdrawn.
  /// Not `google.com`, which is unreachable in mainland China and on some
  /// corporate networks — there it reports "no internet" to users who are fine.
  static const connectionProbeHost = "example.com";

  /// Returns `true` if [host] resolves within [timeout].
  ///
  /// Pass the host you actually need to reach: it is the connectivity that
  /// matters, and it is usually already in the resolver cache, which makes the
  /// probe ~0.5ms instead of a cold round trip. Resolution is a cheap negative
  /// signal but a weak positive one — a cached record resolves with no
  /// working connection.
  static Future<bool> hasConnection({
    String? host,
    Duration timeout = const Duration(milliseconds: 200),
  }) async {
    try {
      final result = await InternetAddress.lookup(
        host.hasValue ? host! : connectionProbeHost,
      ).timeout(timeout);
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

  /// Localized strings, resolved from the registered [AppConfig].
  ///
  /// `stringKeys` is an extension on `Object?` and so is unavailable to the
  /// static helpers below; this reaches the same instance.
  static AppConfigStrings get _strings => locator<AppConfig>().strings;

  /// Converts an arbitrary [error] into a `{"message", "statusCode"}` pair safe
  /// to show a user.
  ///
  /// Transport failures are mapped to localized strings rather than the raw
  /// exception text, which routinely carries hostnames, ports and OS error
  /// codes — `SocketException.message` alone reads
  /// `"Failed host lookup: 'api.example.com' (OS Error: ..., errno = 8)"`.
  /// The original object is left untouched for crash reporting; only the
  /// message shown to the user is sanitised.
  ///
  /// A server-supplied message on a [DioExceptionType.badResponse] is passed
  /// through as-is only below `500`: a `4xx` is the API's own refusal and is
  /// meant to be read. A `5xx` this far along may not have come from the API
  /// at all — a gateway or reverse proxy in front of it answers on the
  /// origin's behalf, unencrypted, so that body is not trusted; a localized
  /// string is shown instead.
  static Map<String, dynamic> parseError(
    dynamic error, {
    String defaultMessage = "",
  }) {
    try {
      if (error is DioException) {
        return _parseDioError(error, defaultMessage: defaultMessage);
      }

      if (_sanitisedCause(error) case (final message, final code)) {
        return {"message": message, "statusCode": code};
      }

      if (error is String) {
        return {"message": error, "statusCode": 500};
      }

      if (error is Map) {
        return _parseErrorMap(error, defaultMessage: defaultMessage);
      }

      return {"message": defaultMessage, "statusCode": 500};
    } catch (_) {
      return {"message": defaultMessage, "statusCode": 500};
    }
  }

  /// Maps a [DioException] to a user-safe message.
  ///
  /// Dispatches on [DioException.type] before looking at the body, so a
  /// transport failure never falls through to [DioException.message] — which
  /// embeds the underlying error text.
  static Map<String, dynamic> _parseDioError(
    DioException error, {
    String defaultMessage = "",
  }) {
    final responseCode = error.response?.statusCode;

    if (_sanitisedFailure(error) case (final message, final code)) {
      return {"message": message, "statusCode": responseCode ?? code};
    }

    // A gateway or reverse proxy in front of the API answers a `5xx` on its
    // behalf and never authored or encrypted that body, so it is not the
    // API's message to show. A `4xx` is the API's own refusal and falls
    // through to read normally below.
    if (responseCode != null && responseCode >= 500) {
      return {
        "message": _strings.serverUnavailable.tr(),
        "statusCode": responseCode,
      };
    }

    // Reaching here means the server answered, so its own message is the one
    // worth showing.
    final data = error.response?.data;
    if (data is Map) {
      return _parseErrorMap(
        data,
        defaultMessage: defaultMessage,
        statusCode: responseCode ?? 500,
      );
    }
    return {"message": defaultMessage, "statusCode": responseCode ?? 500};
  }

  /// Returns the localized message and status for a transport-level [error],
  /// or `null` when the server responded and its body should be used instead.
  static (String, int)? _sanitisedFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => (_strings.requestTimedOut.tr(), 408),
      DioExceptionType.connectionError => (_strings.checkNetwork.tr(), 503),
      DioExceptionType.badCertificate => (
        _strings.secureConnectionFailed.tr(),
        495,
      ),
      DioExceptionType.cancel => (_strings.requestCancelled.tr(), 499),
      DioExceptionType.badResponse => null,
      // Dio reports a large share of real connection failures as `unknown`
      // with the underlying IO exception attached, so unwrap before giving up.
      _ => _sanitisedCause(error.error),
    };
  }

  /// Maps a raw IO/async failure to a localized message and status.
  static (String, int)? _sanitisedCause(Object? cause) {
    return switch (cause) {
      SocketException _ => (_strings.checkNetwork.tr(), 503),
      TimeoutException _ => (_strings.requestTimedOut.tr(), 408),
      // Covers both HandshakeException and CertificateException.
      TlsException _ => (_strings.secureConnectionFailed.tr(), 495),
      _ => null,
    };
  }

  /// The keys an error body spells its response code with. `DecryptInterceptor`
  /// writes decrypted ciphertext back under whichever case it found `data` in,
  /// so a body that arrived spelled `Data` keeps every other key in that same
  /// case, `Status` included.
  static const _codeKeys = ['responseCode', 'Status'];

  /// The keys an error body spells its top-level message with.
  static const _messageKeys = ['message', 'Message'];

  /// The keys an error body spells its short error string with.
  static const _errorKeys = ['error', 'Error'];

  /// The keys an error body spells its status message with.
  static const _statusMessageKeys = ['statusMessage', 'StatusMessage'];

  /// The keys a validation body spells its field-message map with.
  static const _validationKeys = ['errors', 'Errors'];

  /// The keys an error body nests a narrower error under.
  static const _nestedErrorKeys = ['data', 'Data'];

  /// The keys a validation body spells its heading with.
  static const _titleKeys = ['title', 'Title'];

  static Map<String, dynamic> _parseErrorMap(
    Map error, {
    String defaultMessage = "",
    int statusCode = 500,
  }) {
    final json = AppJson.asMap(error);

    // Interpolate before parsing: `int.tryParse` only accepts a String, so a
    // missing key (null) or a numeric code used to throw and lose the message.
    final code =
        int.tryParse("${AppJson.valueAt(json, _codeKeys)}") ?? statusCode;

    if (AppJson.valueAt(json, _messageKeys) case final String value) {
      return {"message": value, "statusCode": code};
    }

    if (AppJson.valueAt(json, _errorKeys) case final String value
        when value.isNotEmpty) {
      return {"message": value, "statusCode": code};
    }

    if (AppJson.valueAt(json, _statusMessageKeys) case final String value) {
      return {"message": value, "statusCode": code};
    }

    // A rejected field is reported as a map of field names to their messages,
    // with no `message` of its own. Without this the customer is told only
    // that something went wrong, never which field or why.
    if (_validationMessages(AppJson.valueAt(json, _validationKeys))
        case final message?) {
      return {"message": message, "statusCode": code};
    }

    final nested = AppJson.valueAt(json, _nestedErrorKeys);
    if (nested is Map) {
      return _parseErrorMap(
        nested,
        defaultMessage: defaultMessage,
        statusCode: code,
      );
    }
    if (nested != null) {
      return parseError(nested, defaultMessage: defaultMessage);
    }

    // The heading that accompanies a validation body, used only once its own
    // field messages and any nested body have come to nothing.
    if (AppJson.valueAt(json, _titleKeys) case final String title
        when title.hasValue) {
      return {"message": title, "statusCode": code};
    }

    return {"message": defaultMessage, "statusCode": code};
  }

  /// Every message in a validation [errors] map, one per line, or `null` when
  /// it holds none.
  ///
  /// A field maps either to a list of messages or to a single one, and the
  /// same message can repeat across fields, so they are de-duplicated.
  static String? _validationMessages(Object? errors) {
    if (errors is! Map) return null;

    final messages = <String>{};
    for (final value in errors.values) {
      switch (value) {
        case Iterable values:
          messages.addAll(
            values.map((item) => "$item".value).where((item) => item.hasValue),
          );
        case final value?:
          final message = "$value".value;
          if (message.hasValue) messages.add(message);
      }
    }

    if (messages.isEmpty) return null;
    return messages.join("\n");
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
