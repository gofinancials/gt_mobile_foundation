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
    try {
      final hasToken = _sessionService.hasToken;
      final shouldRefreshToken = _sessionService.shouldBeRefreshed;

      String? accessToken = _sessionService.accessToken;

      if (hasToken && shouldRefreshToken) {
        final renewWatch = Stopwatch()..start();
        accessToken = await onRenew();
        renewWatch.stop();
        options.recordPhase("renew", renewWatch.elapsed);
      }

      if (accessToken.hasValue) {
        options.headers["Authorization"] = "Bearer $accessToken";
      }

      return handler.next(options);
    } catch (e, t) {
      AppLogger.severe("JWT Interceptor failed: $e", stackTrace: t, error: e);
      return handler.next(options);
    }
  }
}
