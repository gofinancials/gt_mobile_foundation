import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// An interceptor that checks for active internet connection before executing a network request.
class NetworkInterceptor extends Interceptor {
  /// Creates a new instance of [NetworkInterceptor].
  const NetworkInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response != null) {
      return handler.next(err);
    }

    // Probe the host the request was actually for: it is the connectivity that
    // matters here, and it is already in the resolver cache from the attempt
    // that just failed. [AppHelpers.hasConnection] bounds its own timeout.
    final hasConnection = await AppHelpers.hasConnection(
      host: err.requestOptions.uri.host,
    );
    if (!hasConnection) {
      return handler.next(
        DioException(
          requestOptions: err.requestOptions,
          // Preserve the classification and the underlying cause; rebuilding
          // without them downgrades a timeout or socket failure to `unknown`
          // and discards the original error for reporting.
          type: DioExceptionType.connectionError,
          error: err.error,
          stackTrace: err.stackTrace,
          response: Response(
            requestOptions: err.requestOptions,
            data: {"message": stringKeys.checkNetwork.tr()},
            statusCode: 408,
            statusMessage: stringKeys.noInternet.tr(),
          ),
        ),
      );
    }
    return handler.next(err);
  }
}
