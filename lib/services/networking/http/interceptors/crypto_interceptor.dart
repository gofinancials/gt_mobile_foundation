import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

extension on RequestOptions {
  /// Checks if the request is sensitive
  bool get isSensitiveRequest {
    return extra[sensitiveRequestExtraKey] == true;
  }
}

/// {@category Services}
/// An interceptor that intercepts outgoing requests and encrypts the body data using [AppCryptoService].
class EncryptInterceptor extends InterceptorsWrapper {
  /// The cryptography service used for encryption.
  final AppCryptoService _service;

  /// The encryption mode used for encryption.
  final AppCryptoMode mode;

  /// The packaging strategy used for formatting the encrypted payload.
  final AppCryptoPayloadStrategy strategy;

  /// Determines if app tag is encrypted before injection as an header
  final bool encryptTag;

  /// Determines if app tag is encrypted before injection as an header
  final String tagHeaderKey;

  String? _encryptedAppTag;

  /// Creates a new instance of [EncryptInterceptor].
  EncryptInterceptor(
    this._service, {
    this.mode = .base16,
    this.strategy = .contiguous,
    this.encryptTag = true,
    this.tagHeaderKey = "App-Tag",
  });

  /// Encodes the provided [data] to JSON if necessary and returns the encrypted ciphertext
  /// using the configured [_service], [mode], and [strategy].
  Future<String> _getCiphertext(dynamic data) async {
    final plaintext = data is String ? data : await AppHelpers.encodeJson(data);
    return _service.encrypt(plaintext, mode: mode, strategy: strategy);
  }

  /// Returns the encrypted application tag.
  String get _appTag {
    if (!encryptTag) return _service.appTag;
    if (_encryptedAppTag case String encryptedTag) return encryptedTag;
    _encryptedAppTag ??= _service.encrypt(
      _service.appTag,
      mode: mode,
      strategy: strategy,
    );
    return _encryptedAppTag!;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.isSensitiveRequest) {
      return handler.next(options);
    }
    try {
      final data = options.data;
      if (data is! List && data is! Map && data is! String) {
        return handler.next(options);
      }

      final encryptWatch = Stopwatch()..start();
      final encryptedData = await _getCiphertext(data);
      encryptWatch.stop();
      options.recordPhase("encrypt", encryptWatch.elapsed);

      options = options.copyWith(
        data: {"data": encryptedData},
        headers: {...options.headers, tagHeaderKey: _appTag},
      );

      AppLogger.info({
        "plainText": "***REDACTED***",
        "cipherText": encryptedData.asRedactedSecret,
        "params": options.queryParameters,
        "header": options.headers,
        "method": options.method,
      });

      return handler.next(options);
    } catch (e, t) {
      AppLogger.severe("Encryption failed: $e", stackTrace: t, error: e);
      return handler.next(options);
    }
  }
}

/// {@category Services}
/// An interceptor that intercepts incoming responses and decrypts the body data using [AppCryptoService].
class DecryptInterceptor extends InterceptorsWrapper {
  /// The cryptography service used for decryption.
  final AppCryptoService _service;

  /// The decryption mode used for decryption.
  final AppCryptoMode mode;

  /// The packaging strategy used for decrypting the payload (defaults to [AppCryptoPayloadStrategy.auto]).
  final AppCryptoPayloadStrategy strategy;

  /// Creates a new instance of [DecryptInterceptor].
  DecryptInterceptor(
    this._service, {
    this.mode = .base16,
    this.strategy = .auto,
  });

  /// Resolves the final [Response] object by substituting the original [payload]
  /// with the [decryptedData] (or parsed JSON) where applicable.
  ///
  /// If the original payload is a [Map], it replaces the `"data"` field with the decrypted content.
  Response _resolveResponse(
    dynamic rawData,
    dynamic decryptedData,
    Response response,
  ) {
    if (decryptedData == null || rawData == decryptedData) return response;
    final resolvedData = switch (rawData) {
      Map map => {...map, "data": decryptedData},
      _ => decryptedData,
    };
    return response.copyWith(data: resolvedData);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (!response.requestOptions.isSensitiveRequest) {
      return handler.next(response);
    }
    try {
      AppLogger.info("Decrypting response for ${response.requestOptions.uri}");
      final rawData = response.data;
      final data = switch (rawData) {
        String str => str,
        Map map when map["data"] is String => map["data"] as String,
        _ => "",
      };

      if (!data.hasValue) return handler.next(response);

      final decryptWatch = Stopwatch()..start();
      final plainText = _service.decrypt(data, mode: mode, strategy: strategy);
      decryptWatch.stop();
      response.requestOptions.recordPhase("decrypt", decryptWatch.elapsed);

      // Decryption failed (service returns original string on failure).
      if (plainText == data) return handler.next(response);

      final parsedData = await AppHelpers.parseJson(plainText);

      // If JSON parsing fails (e.g. decrypted payload is a raw string), fallback to plainText
      final finalData = parsedData ?? plainText;

      final newResponse = _resolveResponse(rawData, finalData, response);

      AppLogger.info({
        "cipherText": data,
        "parsedText": finalData,
        "parsedData": newResponse.data,
      });

      return handler.next(newResponse);
    } catch (e, t) {
      AppLogger.severe("Decryption failed: $e", stackTrace: t, error: e);
      return handler.next(response);
    }
  }
}
