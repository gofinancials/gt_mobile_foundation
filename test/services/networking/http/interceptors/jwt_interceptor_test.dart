import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../../../../support/test_config.dart';

class _Session implements AppSessionService {
  _Session({
    this.shouldBeRefreshed = false,
    this.hasToken = true,
    this.isExpired = false,
  });

  @override
  final bool shouldBeRefreshed;

  @override
  final bool hasToken;

  @override
  final bool isExpired;

  @override
  String? accessToken = 'stale';

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// Records whether the request ever left the interceptor chain.
class _Stub implements HttpClientAdapter {
  var reached = false;
  String? authorization;

  /// The status every reply carries.
  var status = 200;

  /// Runs while the request is in flight, before its reply.
  void Function()? inFlight;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? s,
    Future? c,
  ) async {
    reached = true;
    authorization = o.headers['Authorization'] as String?;
    inFlight?.call();
    return ResponseBody.fromString(
      status == 200 ? '{"ok":true}' : '{"message":"session ended"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A renewal that failed against the gateway, carrying its own reply.
DioException gatewayFailure(int status, Object body) {
  final options = RequestOptions(path: '/renew');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  registerTestConfig();

  late _Stub adapter;
  late _Session session;

  Dio build({
    required FutureCall<String?> onRenew,
    OnJwtRenewalFailure? onRenewalFailure,
    int? sessionExpiredStatus,
    OnJwtSessionExpired? onSessionExpired,
    bool refresh = true,
    bool hasToken = true,
    bool isExpired = false,
  }) {
    adapter = _Stub();
    session = _Session(
      shouldBeRefreshed: refresh,
      hasToken: hasToken,
      isExpired: isExpired,
    );
    return Dio(BaseOptions(baseUrl: 'https://stub.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        JwtInterceptor(
          session,
          onRenew: onRenew,
          onRenewalFailure: onRenewalFailure,
          sessionExpiredStatus: sessionExpiredStatus,
          onSessionExpired: onSessionExpired,
        ),
      );
  }

  Future<Object?> failureOf(Dio dio, {Options? options}) async {
    try {
      await dio.get<dynamic>('/ping', options: options);
      return null;
    } catch (e) {
      return e;
    }
  }

  group('without a failure handler', () {
    test('a token merely due for renewal still carries the request', () async {
      final dio = build(onRenew: () async => throw StateError('refresh down'));

      await dio.get<dynamic>('/ping');
      expect(
        adapter.authorization,
        'Bearer stale',
        reason: 'renewal is pre-emptive, so the token in hand has not expired',
      );
    });

    test('an expired token fails the request instead of sending it', () async {
      final dio = build(
        onRenew: () async => throw StateError('refresh down'),
        isExpired: true,
      );

      expect(await failureOf(dio), isA<DioException>());
      expect(
        adapter.reached,
        isFalse,
        reason: 'an expired token that could not be renewed is not a token',
      );
    });

    test('an empty renewal still carries a token not yet expired', () async {
      final dio = build(onRenew: () async => null);

      await dio.get<dynamic>('/ping');
      expect(adapter.authorization, 'Bearer stale');
    });

    test('a renewal that answers with no token is a failure too', () async {
      final dio = build(onRenew: () async => null, isExpired: true);

      expect(await failureOf(dio), isA<DioException>());
      expect(adapter.reached, isFalse);
    });
  });

  group('with a failure handler', () {
    test('a refused credential fails the request', () async {
      final dio = build(
        onRenew: () async => throw gatewayFailure(401, {'message': 'expired'}),
        onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
      );

      final parsed = AppHelpers.parseError(await failureOf(dio));
      expect(adapter.reached, isFalse);
      expect(parsed['statusCode'], 401, reason: 'the refusal must survive');
      expect(parsed['message'], 'expired');
    });

    test(
      'an unreachable renewal endpoint sends on the current token',
      () async {
        final dio = build(
          onRenew: () async =>
              throw gatewayFailure(503, '<html>gateway</html>'),
          onRenewalFailure: (_, _, _) => JwtRenewalAction.proceed,
        );

        await dio.get<dynamic>('/ping');
        expect(adapter.authorization, 'Bearer stale');
      },
    );

    test('the handler reads the request it is deciding for', () async {
      final paths = <String>[];
      final dio = build(
        onRenew: () async => throw StateError('refresh down'),
        onRenewalFailure: (options, _, _) {
          paths.add(options.path);
          return JwtRenewalAction.proceed;
        },
      );

      await dio.get<dynamic>('/ping');
      expect(paths, ['/ping']);
    });

    test('an empty renewal arrives as a JwtRenewalException', () async {
      final causes = <Object>[];
      final dio = build(
        onRenew: () async => '',
        onRenewalFailure: (_, error, _) {
          causes.add(error);
          return JwtRenewalAction.proceed;
        },
      );

      await dio.get<dynamic>('/ping');
      expect(
        causes.single,
        isA<JwtRenewalException>(),
        reason: 'a renewal that produced nothing is not a transport error',
      );
    });

    test(
      'proceeding is refused when the session no longer holds a token',
      () async {
        // A host that closes the session inside onRenew has discarded the token
        // the request would otherwise proceed on.
        final dio = build(
          onRenew: () async {
            session.accessToken = null;
            throw gatewayFailure(401, {'message': 'expired'});
          },
          onRenewalFailure: (_, _, _) => JwtRenewalAction.proceed,
        );

        expect(await failureOf(dio), isA<DioException>());
        expect(
          adapter.reached,
          isFalse,
          reason: 'no decision may send a request unauthenticated',
        );
      },
    );

    test('a handler that throws fails the request', () async {
      final dio = build(
        onRenew: () async => throw StateError('refresh down'),
        onRenewalFailure: (_, _, _) => throw StateError('handler down'),
      );

      expect(await failureOf(dio), isA<DioException>());
      expect(adapter.reached, isFalse);
    });

    test('a handler may answer asynchronously', () async {
      final dio = build(
        onRenew: () async => throw StateError('refresh down'),
        onRenewalFailure: (_, _, _) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return JwtRenewalAction.fail;
        },
      );

      expect(await failureOf(dio), isA<DioException>());
    });
  });

  group('the rest of the chain', () {
    test('a following error interceptor sees the rejection', () async {
      DioException? seen;
      final dio =
          build(
              onRenew: () async => throw StateError('refresh down'),
              onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
            )
            ..interceptors.add(
              InterceptorsWrapper(
                onError: (e, handler) {
                  seen = e;
                  handler.next(e);
                },
              ),
            );

      await failureOf(dio);
      expect(
        seen,
        isNotNull,
        reason: 'a host ends the session from its own onError interceptor',
      );
    });

    test('the composed chain keeps the renewal refusal readable', () async {
      // Mirrors what a host composes: a logger and the error-decrypting crypto
      // interceptor sit alongside this one, and the rejection travels through
      // both. The renewal's own reply is plaintext, so nothing may try to
      // decrypt it on the strength of the current request's sensitive flag.
      final dio = build(
        onRenew: () async => throw gatewayFailure(401, {'message': 'expired'}),
        onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
      );
      dio.interceptors.insert(0, const LoggerInterceptor());
      dio.interceptors.add(
        DecryptInterceptor(
          AppCryptoServiceImpl(
            aesKey: '01234567890123456789012345678901',
            appTag: 'JwtInterceptorTestTag00000001',
            tamperProof: true,
          ),
          mode: .base64,
          strategy: .colonDelimited,
        ),
      );

      final parsed = AppHelpers.parseError(
        await failureOf(
          dio,
          options: Options(extra: {sensitiveRequestExtraKey: true}),
        ),
      );
      expect(parsed['statusCode'], 401);
      expect(parsed['message'], 'expired');
    });
  });

  group('requests that need no renewal', () {
    test('a fresh token is attached when renewal succeeds', () async {
      final dio = build(onRenew: () async => 'fresh');

      await dio.get<dynamic>('/ping');
      expect(adapter.authorization, 'Bearer fresh');
    });

    test('a token not due for renewal is left alone', () async {
      var renewed = false;
      final dio = build(
        onRenew: () async {
          renewed = true;
          return 'fresh';
        },
        refresh: false,
      );

      await dio.get<dynamic>('/ping');
      expect(renewed, isFalse);
      expect(adapter.authorization, 'Bearer stale');
    });

    test('an unauthenticated request is unaffected', () async {
      final dio = build(onRenew: () async => null, hasToken: false);

      await dio.get<dynamic>('/ping');
      expect(adapter.reached, isTrue);
    });
  });

  group('requests marked public', () {
    final public = Options(extra: {publicRequestExtraKey: true});

    test('are not renewed for, however due the token is', () async {
      var renewed = false;
      final dio = build(
        onRenew: () async {
          renewed = true;
          return 'fresh';
        },
      );

      await dio.get<dynamic>('/ping', options: public);
      expect(renewed, isFalse, reason: 'a sign-in waits on no renewal');
      expect(adapter.reached, isTrue);
    });

    test('are not given the session bearer', () async {
      final dio = build(onRenew: () async => 'fresh', refresh: false);

      await dio.get<dynamic>('/ping', options: public);
      expect(
        adapter.authorization,
        isNull,
        reason: 'the session the customer is leaving is not theirs to carry',
      );
    });

    test('never reach the renewal failure handler', () async {
      var asked = false;
      final dio = build(
        onRenew: () async => throw StateError('refresh down'),
        onRenewalFailure: (_, _, _) {
          asked = true;
          return JwtRenewalAction.fail;
        },
        isExpired: true,
      );

      await dio.get<dynamic>('/ping', options: public);
      expect(asked, isFalse);
      expect(adapter.reached, isTrue);
    });

    test('keep an Authorization header their caller set', () async {
      final dio = build(onRenew: () async => 'fresh');

      await dio.get<dynamic>(
        '/ping',
        options: Options(
          extra: {publicRequestExtraKey: true},
          headers: {'Authorization': 'Bearer own'},
        ),
      );
      expect(
        adapter.authorization,
        'Bearer own',
        reason: 'passing through leaves the request as the caller built it',
      );
    });
  });

  group('a session the gateway has ended', () {
    late List<DioException> lapses;

    Dio lapsing({
      FutureCall<String?>? onRenew,
      OnJwtRenewalFailure? onRenewalFailure,
      OnJwtSessionExpired? onSessionExpired,
      bool refresh = false,
      int status = 440,
    }) {
      lapses = [];
      final dio = build(
        onRenew: onRenew ?? () async => 'fresh',
        onRenewalFailure: onRenewalFailure,
        sessionExpiredStatus: 440,
        onSessionExpired: onSessionExpired ?? lapses.add,
        refresh: refresh,
      );
      adapter.status = status;
      return dio;
    }

    test('is reported, and the caller still receives its failure', () async {
      final dio = lapsing();

      final parsed = AppHelpers.parseError(await failureOf(dio));
      expect(lapses.single.response?.statusCode, 440);
      expect(
        parsed['statusCode'],
        440,
        reason: 'the caller renders its own failure',
      );
    });

    test('is not read from any other status', () async {
      // A 401 from this gateway can refuse a request on a credential it still
      // honours; reading it as an ended session looped a customer through
      // sign-in.
      final dio = lapsing(status: 401);

      await failureOf(dio);
      expect(lapses, isEmpty);
    });

    test('is not reported for a request sent on an earlier token', () async {
      final dio = lapsing();
      // The customer signs in again while this request is in flight.
      adapter.inFlight = () => session.accessToken = 'next';

      await failureOf(dio);
      expect(
        lapses,
        isEmpty,
        reason: 'the reply speaks for a session the customer already left',
      );
    });

    test('is not reported for a request marked public', () async {
      final dio = lapsing();

      await failureOf(
        dio,
        options: Options(extra: {publicRequestExtraKey: true}),
      );
      expect(lapses, isEmpty);
    });

    test('is not reported for a request sent with no token', () async {
      final dio = lapsing();
      session.accessToken = null;

      await failureOf(dio);
      expect(adapter.authorization, isNull);
      expect(lapses, isEmpty);
    });

    test('is reported once for each concurrent request', () async {
      // One screen's fan-out is answered together; telling the calls apart is
      // the host's.
      final dio = lapsing();

      await Future.wait(List.generate(3, (_) => failureOf(dio)));
      expect(lapses, hasLength(3));
    });

    test('stops once the host clears the session', () async {
      final dio = lapsing(
        onSessionExpired: (error) {
          lapses.add(error);
          session.accessToken = null;
        },
      );

      await Future.wait(List.generate(3, (_) => failureOf(dio)));
      expect(
        lapses,
        hasLength(1),
        reason: 'the bearer the rest carried is no longer the current one',
      );
    });

    test('is not awaited', () async {
      final dio = lapsing(onSessionExpired: (_) => Completer<void>().future);

      expect(await failureOf(dio), isA<DioException>());
    });

    test('a handler that throws leaves the failure as it was', () async {
      final dio = lapsing(onSessionExpired: (_) => throw StateError('down'));

      final parsed = AppHelpers.parseError(await failureOf(dio));
      expect(parsed['statusCode'], 440);
    });

    test('is reported when renewal is what the gateway refused', () async {
      final dio = lapsing(
        onRenew: () async => throw gatewayFailure(440, {'message': 'ended'}),
        onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
        refresh: true,
      );

      final parsed = AppHelpers.parseError(await failureOf(dio));
      expect(adapter.reached, isFalse);
      expect(lapses.single.requestOptions.path, '/renew');
      expect(parsed['statusCode'], 440);
    });

    test(
      'a refused renewal is reported once, not again on rejection',
      () async {
        // dio hands a request interceptor's rejection back to every onError,
        // this interceptor's included, carrying the renewal's status.
        final dio = lapsing(
          onRenew: () async => throw gatewayFailure(440, {'message': 'ended'}),
          onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
          refresh: true,
        );

        await failureOf(
          dio,
          options: Options(headers: {'Authorization': 'Bearer stale'}),
        );
        expect(lapses, hasLength(1));
      },
    );

    test('a refused renewal still leaves the request to the handler', () async {
      final dio = lapsing(
        onRenew: () async => throw gatewayFailure(440, {'message': 'ended'}),
        onRenewalFailure: (_, _, _) => JwtRenewalAction.proceed,
        refresh: true,
        status: 200,
      );

      await dio.get<dynamic>('/ping');
      expect(adapter.authorization, 'Bearer stale');
      expect(lapses, hasLength(1));
    });

    test(
      'a refused renewal is not reported once the host closed the session',
      () async {
        final dio = lapsing(
          onRenew: () async {
            session.accessToken = null;
            throw gatewayFailure(440, {'message': 'ended'});
          },
          onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
          refresh: true,
        );

        await failureOf(dio);
        expect(lapses, isEmpty);
      },
    );

    test('a public request is never renewed for, so none is refused', () async {
      var renewed = false;
      final dio = lapsing(
        onRenew: () async {
          renewed = true;
          throw gatewayFailure(440, {'message': 'ended'});
        },
        onRenewalFailure: (_, _, _) => JwtRenewalAction.fail,
        refresh: true,
        status: 200,
      );

      await dio.get<dynamic>(
        '/ping',
        options: Options(extra: {publicRequestExtraKey: true}),
      );
      expect(renewed, isFalse);
      expect(adapter.reached, isTrue);
      expect(lapses, isEmpty);
    });

    test('a public request carrying its own bearer is not a lapse', () async {
      final dio = lapsing();

      await failureOf(
        dio,
        options: Options(
          extra: {publicRequestExtraKey: true},
          headers: {'Authorization': 'Bearer stale'},
        ),
      );
      expect(adapter.authorization, 'Bearer stale');
      expect(lapses, isEmpty);
    });

    test('the status and handler are given together', () {
      expect(
        () => JwtInterceptor(
          _Session(),
          onRenew: () async => null,
          sessionExpiredStatus: 440,
        ),
        throwsAssertionError,
      );
    });
  });
}
