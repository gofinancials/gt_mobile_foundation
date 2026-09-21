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

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? s,
    Future? c,
  ) async {
    reached = true;
    authorization = o.headers['Authorization'] as String?;
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
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
}
