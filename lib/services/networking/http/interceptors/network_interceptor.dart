import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class NetworkInterceptor extends Interceptor {
  const NetworkInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final connectTimeout = 500.milliseconds;
    final hasConnection = await AppHelpers.hasConnection().timeout(
      connectTimeout,
      onTimeout: () => false,
    );
    if (!hasConnection) {
      return handler.next(
        DioException(
          requestOptions: err.requestOptions,
          response: Response(
            requestOptions: err.requestOptions,
            data: {"message": stringKeys.checkNetwork.tr()},
            statusCode: err.response?.statusCode ?? 408,
            statusMessage: stringKeys.noInternet.tr(),
          ),
        ),
      );
    }
    return handler.next(err);
  }
}
