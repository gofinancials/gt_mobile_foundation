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

/// {@category Typedefs}
/// Signature for what a host does once the gateway says the session ended.
///
/// [error] is the reply that said so: the request's own, or the renewal's when
/// renewal was what the gateway refused. Its status equals
/// [JwtInterceptor.sessionExpiredStatus].
typedef OnJwtSessionExpired = FutureOr<void> Function(DioException error);

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

  /// The HTTP status the gateway reserves for a session it has ended.
  ///
  /// Named by the host, never assumed here: a `401` from a gateway can be a
  /// business refusal on a credential it still honours, so reading one as an
  /// ended session signs a customer out who is still signed in. The OneBank
  /// gateway reserves `440`.
  final int? sessionExpiredStatus;

  /// Called when a reply's status is [sessionExpiredStatus].
  ///
  /// Only for a request that carried the session's current bearer token and
  /// was not marked public (see [publicRequestExtraKey]), so a reply to a
  /// request sent before the customer signed in again cannot end the session
  /// they signed in to. A public request is never given the bearer, but one
  /// whose caller set it by hand is still not read as a lapse. A renewal answered with [sessionExpiredStatus] counts
  /// too, since a gateway that refuses to renew has ended the session as
  /// surely as one that refuses the request. It is seen only when [onRenew]
  /// lets the gateway's [DioException] through; a renewal that catches it and
  /// answers null reads as a [JwtRenewalException], which says nothing about
  /// status.
  ///
  /// For a refused renewal this runs before [onRenewalFailure], and both run:
  /// this one answers for the session, that one for the request waiting on
  /// it. A host that also ends the session from [onRenewalFailure] ends it
  /// twice, which the same debouncing absorbs.
  ///
  /// The guards tell a stale token from a current one; they cannot tell a
  /// true [sessionExpiredStatus] from a gateway that sends it in error. One
  /// that answers a token it has just issued this way — a new session not yet
  /// seen by every node, say — passes every guard, and a host that signs the
  /// customer out each time sends them round a loop: signed in, resumed to a
  /// screen whose requests draw the same answer, signed out again. Only the
  /// host knows when the customer last signed in, so breaking that loop is
  /// the host's too: show the failure rather than signing out again when a
  /// call arrives within moments of a sign-in, or after several in a row.
  ///
  /// It is not awaited and never swallows the error: the caller still receives
  /// its failure and renders it. A screen's concurrent requests can all be
  /// answered this way at once, so this can be called several times for one
  /// ended session; telling those calls apart is the host's to do. A host that
  /// clears the session's token here stops the calls that follow, because
  /// their bearer is then no longer the current one.
  ///
  /// Left out, together with [sessionExpiredStatus], a reply passes through
  /// this interceptor untouched.
  final OnJwtSessionExpired? onSessionExpired;

  /// Failures [_reject] raised, which dio hands back to [onError].
  ///
  /// A renewal refused for an ended session was reported when it was refused;
  /// the rejection carries that refusal's status on the waiting request, and
  /// reporting it again would count one refusal twice.
  static final _rejections = Expando<bool>();

  /// Creates a new instance of [JwtInterceptor].
  JwtInterceptor(
    this._sessionService, {
    required this.onRenew,
    this.onRenewalFailure,
    this.sessionExpiredStatus,
    this.onSessionExpired,
  }) : assert(
         (sessionExpiredStatus == null) == (onSessionExpired == null),
         "sessionExpiredStatus and onSessionExpired are given together or "
         "not at all",
       );

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
  ///
  /// A request marked public (see [publicRequestExtraKey]) passes straight
  /// through: it is not renewed for and is not given the session's bearer.
  /// A sign-in or a passcode reset belongs to no session, so waiting on a
  /// renewal for one only stalls the screen, and the bearer would hand the
  /// gateway a credential for the session the customer is leaving. Headers
  /// the caller set on it are its own and are left as they are.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.isPublicRequest) return handler.next(options);

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
      return _afterFailedRenewal(options, accessToken, e, t);
    }
  }

  /// The token to carry on with once renewal failed, or a [_RenewalRejected].
  ///
  /// [renewing] is the token renewal was asked to replace.
  Future<String?> _afterFailedRenewal(
    RequestOptions options,
    String? renewing,
    Object error,
    StackTrace stackTrace,
  ) async {
    AppLogger.severe(
      "JWT renewal failed: $error",
      stackTrace: stackTrace,
      error: error,
    );

    // A renewal refused for an ended session is reported before the decision
    // below, which still rules on the request as it always has.
    if (error is DioException) _reportLapse(error, options, renewing);

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

  /// Reports a reply that says the session ended, then passes it on.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_rejections[err] == true) return handler.next(err);

    final options = err.requestOptions;
    _reportLapse(err, options, _bearerOf(options));
    return handler.next(err);
  }

  /// Calls [onSessionExpired] when [error] says the session [bearer] belongs
  /// to has ended.
  ///
  /// [request] is the request whose public flag decides, and [bearer] the
  /// token it was sent for. A public request is never renewed for, so only a
  /// reply reaches here for one — and then only with a bearer its caller set.
  void _reportLapse(
    DioException error,
    RequestOptions request,
    String? bearer,
  ) {
    final lapse = onSessionExpired;
    if (lapse == null) return;
    if (error.response?.statusCode != sessionExpiredStatus) return;
    if (request.isPublicRequest) return;

    unawaited(_lapse(lapse, error, bearer));
  }

  /// Runs [lapse] for [error] when [bearer] is still the session's token.
  ///
  /// The token is read before the first await, so it is the one current when
  /// the reply arrived rather than whatever [lapse] leaves behind.
  Future<void> _lapse(
    OnJwtSessionExpired lapse,
    DioException error,
    String? bearer,
  ) async {
    try {
      final current = _sessionService.accessToken;
      // A reply to a request sent on an earlier token speaks for a session the
      // customer has already left.
      if (!bearer.hasValue || bearer != current) return;

      await lapse(error);
    } catch (e, t) {
      AppLogger.severe(
        "JWT session expiry handler failed: $e",
        stackTrace: t,
        error: e,
      );
    }
  }

  /// The bearer token [options] was sent with, if any.
  String? _bearerOf(RequestOptions options) {
    const scheme = "Bearer ";
    final authorization = options.headers["Authorization"];
    if (authorization is! String) return null;
    if (!authorization.startsWith(scheme)) return null;
    return authorization.substring(scheme.length);
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

    _rejections[failure] = true;
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
