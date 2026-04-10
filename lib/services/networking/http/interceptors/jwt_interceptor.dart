import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class JwtInterceptor extends QueuedInterceptorsWrapper {
  final AppSessionService _sessionService;
  final FutureCall<String?> onRenew;

  JwtInterceptor(this._sessionService, {required this.onRenew});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final hasToken = _sessionService.hasToken;
    final shouldRefreshToken = _sessionService.shouldBeRefreshed;
    final isExpired = _sessionService.isExpired;

    final deviceId = await _sessionService.deviceId;
    String? accessToken = _sessionService.accessToken;

    options.headers["x-device-id"] = deviceId;

    if (hasToken && shouldRefreshToken && !isExpired) {
      accessToken = await onRenew();
    }

    if (accessToken.hasValue) {
      options.headers["Authorization"] = "Bearer $accessToken";
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
