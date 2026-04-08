import 'package:dio/dio.dart';

class ContentTypeInterceptor extends Interceptor {
  const ContentTypeInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Object? data = options.data;
    if (data != null && options.contentType == null) {
      final String? contentType;
      if (data is FormData) {
        contentType = Headers.multipartFormDataContentType;
      } else if (data is List || data is Map || data is String) {
        contentType = Headers.jsonContentType;
      } else {
        contentType = Headers.textPlainContentType;
      }
      options.contentType = contentType;
    }
    handler.next(options);
  }
}
