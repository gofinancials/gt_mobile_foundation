import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// Captures what the interceptor passes down the error pipeline.
///
/// It deliberately does not delegate to `super`, which would complete the
/// handler's future with the error and leave it unobserved.
class _CapturingHandler extends ErrorInterceptorHandler {
  DioException? captured;

  @override
  void next(DioException err) => captured = err;
}

void main() {
  group('DecryptInterceptor.onError', () {
    const tag = 'OneBankProDevMobileApiKey00001';
    late AppCryptoServiceImpl cryptoService;
    late DecryptInterceptor interceptor;

    setUp(() {
      cryptoService = AppCryptoServiceImpl(
        aesKey: '01234567890123456789012345678901',
        appTag: tag,
        tamperProof: true,
      );
      interceptor = DecryptInterceptor(
        cryptoService,
        mode: .base64,
        strategy: .colonDelimited,
      );
    });

    String encrypt(String plaintext) => cryptoService.encrypt(
      plaintext,
      mode: .base64,
      strategy: .colonDelimited,
    );

    DioException error({
      required Object? data,
      int statusCode = 400,
      bool sensitive = true,
      bool withResponse = true,
    }) {
      final options = RequestOptions(
        path: '/api/v1/transfer',
        extra: {sensitiveRequestExtraKey: sensitive},
      );
      return DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: withResponse
            ? Response(
                requestOptions: options,
                data: data,
                statusCode: statusCode,
              )
            : null,
      );
    }

    Future<DioException?> run(DioException err) async {
      final handler = _CapturingHandler();
      interceptor.onError(err, handler);
      // onError is async; let its microtasks drain.
      await Future<void>.delayed(Duration.zero);
      return handler.captured;
    }

    test('an encrypted 4xx message reaches the parser in plaintext', () async {
      final ciphertext = encrypt('{"message":"Insufficient funds"}');

      final passed = await run(error(data: {'data': ciphertext}));

      expect(passed?.response?.data, {
        'data': {'message': 'Insufficient funds'},
      });
      expect(
        AppHelpers.parseError(passed, defaultMessage: 'GENERIC')['message'],
        'Insufficient funds',
      );
    });

    test('a bare ciphertext body is decrypted too', () async {
      final ciphertext = encrypt('{"message":"Account locked"}');

      final passed = await run(error(data: ciphertext));

      expect(passed?.response?.data, {'message': 'Account locked'});
    });

    test('the capital-D Data spelling is decrypted in place', () async {
      final ciphertext = encrypt('{"message":"Refused"}');

      final passed = await run(error(data: {'Data': ciphertext}));

      expect(passed?.response?.data, {
        'Data': {'message': 'Refused'},
      });
    });

    test('a gateway 502, 503 or 504 body is left alone', () async {
      for (final status in [502, 503, 504]) {
        final body = {'data': encrypt('{"message":"never read"}')};

        final passed = await run(error(data: body, statusCode: status));

        expect(passed?.response?.data, same(body));
      }
    });

    test('a skipped status is configurable', () async {
      interceptor = DecryptInterceptor(
        cryptoService,
        mode: .base64,
        strategy: .colonDelimited,
        skipErrorStatuses: const {418},
      );
      final ciphertext = encrypt('{"message":"Refused"}');

      final skipped = await run(
        error(data: {'data': ciphertext}, statusCode: 418),
      );
      final decrypted = await run(
        error(data: {'data': ciphertext}, statusCode: 502),
      );

      expect(skipped?.response?.data, {'data': ciphertext});
      expect(decrypted?.response?.data, {
        'data': {'message': 'Refused'},
      });
    });

    test('a non-sensitive request is left alone', () async {
      final body = {'data': encrypt('{"message":"Refused"}')};

      final passed = await run(error(data: body, sensitive: false));

      expect(passed?.response?.data, same(body));
    });

    test('a transport error with no response passes through', () async {
      final err = error(data: null, withResponse: false);

      final passed = await run(err);

      expect(passed, same(err));
      expect(passed?.response, isNull);
    });

    test('a plaintext error body is passed through unchanged', () async {
      final body = {'message': 'Bad request'};

      final passed = await run(error(data: body));

      expect(passed?.response?.data, same(body));
    });

    test('an undecryptable body is passed through unchanged', () async {
      final body = {'data': 'not-a-ciphertext'};

      final passed = await run(error(data: body));

      expect(passed?.response?.data, same(body));
    });
  });
}
