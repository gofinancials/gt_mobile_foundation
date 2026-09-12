import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// An interceptor that logs detailed request, response, and error information, and pushes events to analytics.
class LoggerInterceptor with AppAnalyticsMixin implements InterceptorsWrapper {
  /// Creates a new instance of [LoggerInterceptor].
  const LoggerInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final elapsed = err.requestOptions.elapsed;
    final phases = err.requestOptions.recordedPhases;
    AppLogger.info({
      "status": "error",
      "uri": err.requestOptions.uri,
      "statusCode": err.response?.statusCode ?? 400,
      "statusMessage": err.response?.statusMessage,
      "data": err.response?.data ?? {"message": err.error ?? err},
      "durationMs": elapsed?.inMilliseconds,
      "phasesMs": phases,
    });
    trackEvent(
      .apiError,
      description: err.response?.statusMessage ?? err.type.name,
      value: "${err.requestOptions.uri}",
      duration: elapsed,
      phases: phases,
    );
    return handler.next(err);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.markStarted();
    AppLogger.info({
      "status": "request",
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
    final elapsed = response.requestOptions.elapsed;
    final phases = response.requestOptions.recordedPhases;
    AppLogger.info({
      "status": "response",
      "uri": response.requestOptions.uri,
      "data": response.data,
      "extra": response.extra,
      "headers": response.headers.map,
      "statusCode": response.statusCode,
      "statusMessage": response.statusMessage,
      "durationMs": elapsed?.inMilliseconds,
      "phasesMs": phases,
    });
    trackEvent(
      .apiResponse,
      description: response.statusMessage,
      value: "${response.requestOptions.uri}",
      duration: elapsed,
      phases: phases,
    );
    return handler.next(response);
  }
}
