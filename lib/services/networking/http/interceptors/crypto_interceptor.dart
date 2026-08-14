import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// An interceptor that intercepts outgoing requests and encrypts the body data using [AppCryptoService].
class EncryptInterceptor extends QueuedInterceptorsWrapper {
  /// The cryptography service used for encryption.
  final AppCryptoService _service;

  /// The encryption mode used for encryption.
  final AppCryptoMode mode;

  /// The packaging strategy used for formatting the encrypted payload.
  final AppCryptoPayloadStrategy strategy;

  /// Creates a new instance of [EncryptInterceptor].
  EncryptInterceptor(
    this._service, {
    this.mode = .base16,
    this.strategy = .contiguous,
  });

  /// Encodes the provided [data] to JSON if necessary and returns the encrypted ciphertext
  /// using the configured [_service], [mode], and [strategy].
  Future<String> _getCiphertext(dynamic data) async {
    final plaintext = data is String ? data : await AppHelpers.encodeJson(data);
    return _service.encrypt(plaintext, mode: mode, strategy: strategy);
  }

  /// Returns the encrypted application tag.
  String get _encryptedAppTag {
    return _service.encrypt(_service.appTag, mode: mode, strategy: strategy);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final data = options.data;
      if (data is! List && data is! Map && data is! String) {
        return handler.next(options);
      }

      final encryptedData = await _getCiphertext(data);
      options = options.copyWith(
        data: {"data": encryptedData},
        headers: {...options.headers, "App-Tag": _encryptedAppTag},
      );

      AppLogger.info({
        "plainText": data,
        "cipherText": encryptedData,
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
class DecryptInterceptor extends QueuedInterceptorsWrapper {
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
    return response.copyWith(data: decryptedData);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    AppLogger.info("Response Body: ${response.data}");
    final rawData = response.data;
    final data = switch (rawData) {
      String str => str,
      Map map when map["data"] is String => map["data"] as String,
      _ => "",
    };

    if (!data.hasValue) return handler.next(response);

    final plainText = _service.decrypt(data, mode: mode, strategy: strategy);

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
  }
}


