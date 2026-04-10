import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class LoggerInterceptor with AppAnalyticsMixin implements InterceptorsWrapper {
  const LoggerInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    AppLogger.info({
      "uri": err.requestOptions.uri,
      "statusCode": err.response?.statusCode ?? 400,
      "statusMessage": err.response?.statusMessage,
      "data": err.response?.data ?? {"message": err.error ?? err},
    });
    return handler.next(err);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.info({
      "url": options.uri,
      "body": options.data,
      "params": options.queryParameters,
      "header": options.headers,
      "method": options.method,
    });
    trackEvent(
      .apiRequest,
      description: options.method,
      value: "${options.baseUrl}${options.path}",
    );
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    AppLogger.info({
      "uri": response.requestOptions.uri,
      "data": response.data,
      "extra": response.extra,
      "headers": response.headers.map,
      "statusCode": response.statusCode,
      "statusMessage": response.statusMessage,
    });
    return handler.next(response);
  }
}
