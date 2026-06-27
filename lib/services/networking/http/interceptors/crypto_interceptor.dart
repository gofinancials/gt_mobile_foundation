import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// An interceptor that intercepts outgoing requests and encrypts the body data using [AppCryptoService].
class EncryptInterceptor extends QueuedInterceptorsWrapper {
  /// The cryptography service used for encryption.
  final AppCryptoService _service;

  /// The encryption mode used for encryption.
  final AppCryptoMode mode;

  /// Creates a new instance of [EncryptInterceptor].
  EncryptInterceptor(this._service, {this.mode = .base16});

  /// Encodes the provided [data] to JSON if necessary and returns the encrypted ciphertext
  /// using the configured [_service], and [mode].
  Future<String> _getCiphertext(dynamic data) async {
    String plaintext = "";

    if (data is String) {
      plaintext = data;
    } else {
      plaintext = await AppHelpers.encodeJson(data);
    }

    return _service.encrypt(plaintext, mode: mode);
  }

  /// Returns the encrypted application tag.
  String get _encryptedAppTag {
    return _service.encrypt(_service.appTag, mode: mode);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final data = options.data;
      if (data is List || data is Map || data is String) {
        final encryptedData = await _getCiphertext(data);
        options = options.copyWith(
          data: encryptedData,
          headers: {...options.headers, "App-Tag": _encryptedAppTag},
        );
        AppLogger.info("PlainText: $data -> CipherText: $encryptedData");
      }
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

  /// Whether to use IV in decryption.
  final bool useIV;

  /// The decryption mode used for decryption.
  final AppCryptoMode mode;

  /// Creates a new instance of [DecryptInterceptor].
  DecryptInterceptor(this._service, {this.useIV = false, this.mode = .base16});

  /// Resolves the final [Response] object by substituting the original [payload]
  /// with the [dycryptedData] (or parsed JSON) where applicable.
  ///
  /// If the original payload is a [Map], it replaces the `"data"` field with the decrypted content.
  Response _resolveResponse(
    dynamic payload,
    dynamic dycryptedData,
    Response response,
  ) {
    dynamic data = payload;
    if (dycryptedData == null || payload == dycryptedData) return response;
    if (payload is String) data = dycryptedData;
    if (payload is Map) data = {...payload, "data": dycryptedData};
    return response.copyWith(data: data);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    AppLogger.info("Response Body: ${response.data}");
    final payload = response.data;
    String data = "";
    if (payload is String) data = payload;
    if (payload is Map && payload["data"] is String) {
      data = payload["data"];
    }
    if (!data.hasValue) return handler.next(response);

    final plainText = _service.decrypt(data, mode: mode);

    // Decryption failed (service returns original string on failure).
    if (plainText == data) return handler.next(response);

    final parsedData = await AppHelpers.parseJson(plainText);

    // If JSON parsing fails (e.g. decrypted payload is a raw string), fallback to plainText
    final finalData = parsedData ?? plainText;

    final newResponse = _resolveResponse(payload, finalData, response);
    AppLogger.info(
      "CipherText: $data -> PlainText: $plainText; ParsedData: ${newResponse.data}",
    );

    return handler.next(newResponse);
  }
}
