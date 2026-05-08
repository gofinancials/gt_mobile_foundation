import 'package:dio/dio.dart';

/// {@category Services}
/// An interceptor that automatically attaches the appropriate `Content-Type` header based on the request data format.
class ContentTypeInterceptor extends Interceptor {
  /// Creates a new instance of [ContentTypeInterceptor].
  const ContentTypeInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Object? data = options.data;

    if (data == null || options.contentType != null) {
      return handler.next(options);
    }

    final String? contentType;
    if (data is FormData) {
      contentType = Headers.multipartFormDataContentType;
    } else if (data is List || data is Map || data is String) {
      contentType = Headers.jsonContentType;
    } else {
      contentType = Headers.textPlainContentType;
    }

    options.contentType = contentType;
    handler.next(options);
  }
}
