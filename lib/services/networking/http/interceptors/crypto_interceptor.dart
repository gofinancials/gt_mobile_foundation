import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class EncryptInterceptor extends QueuedInterceptorsWrapper {
  final AppCryptoService _service;

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

class DecryptInterceptor extends QueuedInterceptorsWrapper {
  final AppCryptoService _service;

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
