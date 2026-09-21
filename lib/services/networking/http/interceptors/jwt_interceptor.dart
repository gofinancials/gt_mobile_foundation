import 'dart:async';

import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// What a host wants done with a request whose token renewal failed.
enum JwtRenewalAction {
  /// Fail the request without sending it.
  ///
  /// Chosen when the credential itself was refused — a `401` or `403` from the
  /// renewal — because the token in hand is no longer the customer's.
  fail,

  /// Send the request with the token already in the session.
  ///
  /// Chosen when the renewal could not reach a verdict — a timeout, a `429`, a
  /// `5xx` — because the token in hand is still the customer's and renewal is
  /// pre-emptive: [AppSessionService.shouldBeRefreshed] reports a token
  /// *nearing* expiry, not an expired one.
  proceed,
}

/// {@category Services}
/// Thrown when a renewal completes without producing a token.
///
/// A renewal that answers with null or an empty string failed as surely as one
/// that threw, and reaches [JwtInterceptor.onRenewalFailure] as this rather
/// than as a transport error, which it is not.
class JwtRenewalException implements Exception {
  final String message;

  const JwtRenewalException(this.message);

  @override
  String toString() => "JwtRenewalException: $message";
}

/// {@category Typedefs}
/// Signature for the decision a host makes about a failed token renewal.
///
/// [options] is the request that was waiting on the renewal, so a host can
/// answer differently for a transfer than for a balance read without this
/// library knowing what either is. [error] is the renewal's own failure — the
/// [DioException] it threw, or a [JwtRenewalException] when it produced no
/// token — so a host classifies it with what it already knows about its own
/// renewal endpoint.
typedef OnJwtRenewalFailure =
    FutureOr<JwtRenewalAction> Function(
      RequestOptions options,
      Object error,
      StackTrace stackTrace,
    );

/// {@category Services}
/// An interceptor that manages JWT tokens, handling injection of device IDs, Auth Bearer tokens, and token renewal.
class JwtInterceptor extends QueuedInterceptorsWrapper {
  /// Service for accessing current session state and device information.
  final AppSessionService _sessionService;

  /// Callback executed when the token requires renewal before it expires.
  final FutureCall<String?> onRenew;

  /// Decides what becomes of a request whose renewal failed.
  ///
  /// Left out, the session's own reading decides: an expired token fails the
  /// request, and one merely due for renewal sends as it is. That default
  /// exists because a gateway's expiry claim is not always the one the token
  /// is honoured by, so a renewal this library could not complete is not
  /// evidence the token in hand stopped working.
  ///
  /// A host that can tell a refused credential from an unreachable renewal
  /// endpoint should say so here instead: that classification belongs to
  /// whoever wrote [onRenew], never to this interceptor.
  final OnJwtRenewalFailure? onRenewalFailure;

  /// Creates a new instance of [JwtInterceptor].
  JwtInterceptor(
    this._sessionService, {
    required this.onRenew,
    this.onRenewalFailure,
  });

  /// Attaches the session's bearer token, renewing it first when it is due.
  ///
  /// A renewal that fails no longer forwards the request unconditionally: a
  /// request sent with a token that could not be renewed reaches the gateway
  /// unauthenticated, and what comes back then is a generic failure the caller
  /// cannot tell apart from a refusal — on a transfer, one the customer cannot
  /// tell landed or not. What happens instead is [onRenewalFailure]'s to say.
  ///
  /// A rejection carries the renewal's own [DioException] whenever renewal
  /// failed with one, so the transport status survives to
  /// [AppHelpers.parseError] and a following `onError` interceptor — which the
  /// rejection calls — still reads it as the gateway wrote it.
  ///
  /// [JwtRenewalAction.proceed] re-reads the session rather than trusting the
  /// token read before renewal, because a host whose [onRenew] closed the
  /// session on a refusal has discarded it by now. A request is never sent
  /// with no token when renewal was due, whatever the decision.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token;

    try {
      token = await _tokenFor(options);
    } on _RenewalRejected catch (rejection) {
      return _reject(options, handler, rejection.cause, rejection.stackTrace);
    } catch (e, t) {
      // Not a renewal failure — a session read itself threw — so it is not
      // [onRenewalFailure]'s to rule on.
      return _reject(options, handler, e, t);
    }

    if (token.hasValue) {
      options.headers["Authorization"] = "Bearer $token";
    }

    return handler.next(options);
  }

  /// The token [options] should travel with, renewing it when it is due.
  ///
  /// Throws [_RenewalRejected] when the request is not to be sent at all.
  Future<String?> _tokenFor(RequestOptions options) async {
    final hasToken = _sessionService.hasToken;
    final shouldRefreshToken = _sessionService.shouldBeRefreshed;

    final accessToken = _sessionService.accessToken;
    if (!hasToken || !shouldRefreshToken) return accessToken;

    try {
      final renewWatch = Stopwatch()..start();
      final renewed = await onRenew();
      renewWatch.stop();
      options.recordPhase("renew", renewWatch.elapsed);

      if (renewed.hasValue) return renewed;

      // A renewal that answers with no token would leave the stale one on the
      // request, or none at all, so it is a failure like any other.
      throw const JwtRenewalException("renewal produced no token");
    } catch (e, t) {
      return _afterFailedRenewal(options, e, t);
    }
  }

  /// The token to carry on with once renewal failed, or a [_RenewalRejected].
  Future<String?> _afterFailedRenewal(
    RequestOptions options,
    Object error,
    StackTrace stackTrace,
  ) async {
    AppLogger.severe(
      "JWT renewal failed: $error",
      stackTrace: stackTrace,
      error: error,
    );

    final action = await _actionFor(options, error, stackTrace);
    if (action == JwtRenewalAction.fail) {
      throw _RenewalRejected(error, stackTrace);
    }

    // Read again: a host that closed the session inside [onRenew] has already
    // discarded the token read before renewal started.
    final current = _sessionService.accessToken;
    if (current.hasValue) return current;

    // Proceeding with nothing would send the request unauthenticated, which is
    // the one outcome no decision here may produce.
    throw _RenewalRejected(error, stackTrace);
  }

  /// What [onRenewalFailure] says, or what the session's own reading implies.
  Future<JwtRenewalAction> _actionFor(
    RequestOptions options,
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      final decide = onRenewalFailure;
      if (decide != null) return await decide(options, error, stackTrace);

      // Renewal is pre-emptive, so a token merely due for renewal is still
      // within the life the session credits it with.
      return _sessionService.isExpired
          ? JwtRenewalAction.fail
          : JwtRenewalAction.proceed;
    } catch (e, t) {
      AppLogger.severe(
        "JWT renewal failure handler failed: $e",
        stackTrace: t,
        error: e,
      );
      return JwtRenewalAction.fail;
    }
  }

  /// Fails the request [cause] stopped, keeping [cause] readable downstream.
  void _reject(
    RequestOptions options,
    RequestInterceptorHandler handler,
    Object? cause,
    StackTrace? stackTrace,
  ) {
    // A renewal that failed against the gateway already carries the status and
    // body that say why; rebuilding it would drop both and flatten every
    // reason to a generic failure.
    final failure = switch (cause) {
      DioException error => error.copyWith(requestOptions: options),
      _ => DioException(
        requestOptions: options,
        error: cause,
        stackTrace: stackTrace,
      ),
    };

    return handler.reject(failure, true);
  }
}

/// Carries a rejected renewal's own failure out of the renewal path.
///
/// Private because it never leaves this interceptor: what a caller sees is the
/// [DioException] [JwtInterceptor._reject] builds from [cause].
class _RenewalRejected implements Exception {
  final Object cause;
  final StackTrace stackTrace;

  const _RenewalRejected(this.cause, this.stackTrace);
}
