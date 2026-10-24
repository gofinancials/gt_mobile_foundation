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

    final pattern = AppRegex.currencyPrefix;
    final val = (amount!.startsWith(pattern) ? amount.substring(1) : amount)
        .trim();
    final number = num.tryParse(val.replaceAll(AppRegex.nonAmount, "").trim());
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
  ///
  /// A proxy also answers below `500` — Cloudflare returns `429` when it
  /// rate-limits and `403` when its firewall refuses — and status alone cannot
  /// tell those from the API's own `4xx`. Cloudflare flags the pages it
  /// authors, so a body carrying that flag is replaced the same way, whether
  /// it arrives inside a [DioException] or as a bare [Map].
  ///
  /// A [String] is shown as-is only when it reads as a message. One that
  /// spells a JSON map is read as that map, so a stringified proxy page meets
  /// the same checks, and one that is markup — a router's or proxy's HTML
  /// page — gives way to [defaultMessage].
  ///
  /// The localized strings resolve through the registered [AppConfig]. With
  /// none registered those branches throw and [defaultMessage] is returned, so
  /// a test has to register a config before it can exercise them.
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
        return _parseErrorString(error, defaultMessage: defaultMessage);
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

    // A body read as plain text is still the API's map, only undecoded.
    final data = switch (error.response?.data) {
      String raw => AppJson.decodedMap(raw),
      final other => other,
    };

    // A gateway or reverse proxy in front of the API answers a `5xx` on its
    // behalf and never authored or encrypted that body, so it is not the
    // API's message to show. The API answers some business refusals with a
    // `500` too, and that body was decrypted or carries its envelope, so it
    // reads as a `4xx` does. A `4xx` is the API's own refusal and falls
    // through to read normally below, where a body the proxy flagged as its
    // own is still caught.
    if (_isProxyFailure(error.response, data)) {
      return {
        "message": _strings.serverUnavailable.tr(),
        "statusCode": responseCode,
      };
    }

    // Reaching here means the server answered, so its own message is the one
    // worth showing.
    if (data is Map) {
      return _parseErrorMap(
        data,
        defaultMessage: defaultMessage,
        statusCode: responseCode ?? 500,
      );
    }
    return {"message": defaultMessage, "statusCode": responseCode ?? 500};
  }

  /// Whether [response] is a `5xx` the API did not author, read with its body
  /// already decoded as [data].
  ///
  /// A proxy's page is never encrypted and never carries the API's envelope,
  /// so a body `DecryptInterceptor` decrypted, or one that reads as the
  /// envelope, is the API's whatever its status.
  static bool _isProxyFailure(Response? response, Object? data) {
    if (response == null || (response.statusCode ?? 0) < 500) return false;
    if (response.isDecrypted) return false;
    return !_isEnvelope(data);
  }

  /// Whether [body] is the gateway's envelope: a `responseMessage` beside a
  /// `responseCode` or an `isSuccessful`, at the top or nested under `data`.
  ///
  /// The keys need only be present. A blank message still marks the envelope,
  /// and [_parseErrorMap] then gives way to the caller's default for it.
  static bool _isEnvelope(Object? body) {
    final json = switch (body) {
      String raw => AppJson.decodedMap(raw),
      Map map => AppJson.asMap(map),
      _ => null,
    };
    if (json == null) return false;
    if (_carriesEnvelope(json)) return true;
    return _isEnvelope(AppJson.valueAt(json, _nestedErrorKeys));
  }

  /// Whether [json] itself spells the gateway's envelope keys.
  static bool _carriesEnvelope(Map<String, dynamic> json) {
    if (!_responseMessageKeys.any(json.containsKey)) return false;
    return [..._envelopeCodeKeys, ..._envelopeFlagKeys].any(json.containsKey);
  }

  /// Reads a bare string [error]: a message a repository threw on purpose, or
  /// whatever a body nested where a narrower error was expected.
  static Map<String, dynamic> _parseErrorString(
    String error, {
    String defaultMessage = "",
    int statusCode = 500,
  }) {
    if (AppJson.decodedMap(error) case final map?) {
      return _parseErrorMap(
        map,
        defaultMessage: defaultMessage,
        statusCode: statusCode,
      );
    }

    if (AppRegex.htmlMarkup.hasMatch(error)) {
      return {"message": defaultMessage, "statusCode": statusCode};
    }

    final message = AppJson.asMessage(error) ?? defaultMessage;
    return {"message": message, "statusCode": statusCode};
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
  /// case, `Status` included. The gateway's envelope spells its code
  /// `ResponseCode` in that case, and a caller keyed on a gateway code needs
  /// it in place of the HTTP status.
  static const _codeKeys = ['responseCode', 'ResponseCode', 'Status'];

  /// The keys an error body spells its top-level message with.
  static const _messageKeys = ['message', 'Message'];

  /// The keys the gateway's own envelope spells its message with. Read apart
  /// from [_messageKeys] because a body may carry both, and a blank `message`
  /// must not hide the envelope's.
  static const _responseMessageKeys = ['responseMessage', 'ResponseMessage'];

  /// The keys the gateway's own envelope spells its response code with, in
  /// either case. Narrower than [_codeKeys], whose `Status` a proxy page may
  /// carry too.
  static const _envelopeCodeKeys = ['responseCode', 'ResponseCode'];

  /// The keys the gateway's own envelope spells its success flag with.
  static const _envelopeFlagKeys = ['isSuccessful', 'IsSuccessful'];

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

  /// The key Cloudflare flags a page it authored with, on every status it
  /// answers with. A body that carries it is never one the API wrote, nor one
  /// `DecryptInterceptor` re-cased, so it has the one spelling.
  static const _proxyFlagKeys = ['cloudflare_error'];

  /// The message under the first of [keys] present in [json], or `null` when
  /// that one is blank, a placeholder or not a string.
  static String? _messageAt(Map<String, dynamic> json, List<String> keys) {
    return AppJson.asMessage(AppJson.valueAt(json, keys));
  }

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

    // A reverse proxy answers below `500` too, in the same shape as its `5xx`
    // page, and its `title` would otherwise be read out as the API's message.
    // Read by [AppJson.asFlag] because an interceptor may have stringified it.
    if (AppJson.asFlag(AppJson.valueAt(json, _proxyFlagKeys)) == true) {
      return {"message": _strings.requestRefused.tr(), "statusCode": code};
    }

    // A blank or placeholder message is no message, so the search goes on to
    // the next field rather than showing the customer an empty or `<none>`
    // error.
    if (_messageAt(json, _messageKeys) case final value?) {
      return {"message": value, "statusCode": code};
    }

    if (_messageAt(json, _responseMessageKeys) case final value?) {
      return {"message": value, "statusCode": code};
    }

    if (_messageAt(json, _errorKeys) case final value?) {
      return {"message": value, "statusCode": code};
    }

    if (_messageAt(json, _statusMessageKeys) case final value?) {
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
    if (nested is String) {
      return _parseErrorString(
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
    if (_messageAt(json, _titleKeys) case final title?) {
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

    final messages = errors.values
        .expand((value) => value is Iterable ? value : [value])
        .map((item) => AppJson.asMessage("$item"))
        .nonNulls
        .toSet();

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
