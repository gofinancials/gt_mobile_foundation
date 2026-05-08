import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// An interceptor that intercepts outgoing requests and encrypts the body data using [AppCryptoService].
class EncryptInterceptor extends QueuedInterceptorsWrapper {
  /// The cryptography service used for encryption.
  final AppCryptoService _service;

  /// Creates a new instance of [EncryptInterceptor].
  EncryptInterceptor(this._service);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final data = options.data;
    if (data is List || data is Map || data is String) {
      final encryptedData = _service.encrypt("$data");
      options = options.copyWith(data: encryptedData);
      AppLogger.info("PlainText: $data -> CipherText: $encryptedData");
    }
    return handler.next(options);
  }
}

/// {@category Services}
/// An interceptor that intercepts incoming responses and decrypts the body data using [AppCryptoService].
class DecryptInterceptor extends QueuedInterceptorsWrapper {
  /// The cryptography service used for decryption.
  final AppCryptoService _service;

  /// Creates a new instance of [DecryptInterceptor].
  DecryptInterceptor(this._service);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final data = response.data;
    if (data is String) {
      final decryptedData = _service.decrypt(data);
      response.data = AppHelpers.parseJson(decryptedData);
      AppLogger.info("CipherText: $data -> PlainText: $decryptedData");
    }
    return handler.next(response);
  }
}
