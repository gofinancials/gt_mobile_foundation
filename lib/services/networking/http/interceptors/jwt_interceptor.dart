import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// An interceptor that manages JWT tokens, handling injection of device IDs, Auth Bearer tokens, and token renewal.
class JwtInterceptor extends QueuedInterceptorsWrapper {
  /// Service for accessing current session state and device information.
  final AppSessionService _sessionService;

  /// Callback executed when the token requires renewal before it expires.
  final FutureCall<String?> onRenew;

  /// Creates a new instance of [JwtInterceptor].
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
