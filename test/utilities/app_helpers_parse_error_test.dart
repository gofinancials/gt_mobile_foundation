import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../support/test_config.dart';

RequestOptions get _opts => RequestOptions(path: '/accounts');

DioException _dio(DioExceptionType type, {Object? error, Response? response}) =>
    DioException(
      requestOptions: _opts,
      type: type,
      error: error,
      response: response,
    );

Response _res(dynamic data, int code) =>
    Response(requestOptions: _opts, data: data, statusCode: code);

void main() {
  setUpAll(registerTestConfig);

  const fallback = 'GENERIC';

  group('server messages are preserved', () {
    final cases = <String, Map>{
      'no responseCode': {'message': 'Insufficient funds'},
      'int responseCode': {'message': 'Bad request', 'responseCode': 400},
      'string responseCode': {'message': 'Bad request', 'responseCode': '400'},
      'error key': {'error': 'Account locked'},
      'statusMessage key': {'statusMessage': 'Unauthorized'},
      'nested data': {
        'data': {'message': 'Daily limit exceeded'},
      },
      'nested Data': {
        'Data': {'message': 'Daily limit exceeded'},
      },
    };
    cases.forEach((label, body) {
      test(label, () {
        final out = AppHelpers.parseError(body, defaultMessage: fallback);
        expect(out['message'], isNot(fallback), reason: 'server message lost');
      });
    });

    test('statusCode survives a nested body', () {
      final out = AppHelpers.parseError({
        'responseCode': '422',
        'data': {'message': 'Daily limit exceeded'},
      }, defaultMessage: fallback);
      expect(out['message'], 'Daily limit exceeded');
      expect(out['statusCode'], 422);
    });

    test('a body spelled entirely in the capitalised case is still read', () {
      // What DecryptInterceptor hands the parser when ciphertext arrived
      // nested under `Data`: every other key in that body keeps that case too.
      final out = AppHelpers.parseError({
        'Status': '422',
        'Data': {'Message': 'Insufficient funds'},
      }, defaultMessage: fallback);
      expect(out['message'], 'Insufficient funds');
      expect(out['statusCode'], 422);
    });
  });

  group('transport failures are sanitised', () {
    test('SocketException text never reaches the message', () {
      const leak =
          "Failed host lookup: 'api.example.com' (OS Error: errno = 8)";
      for (final error in <Object>[
        const SocketException(leak),
        _dio(DioExceptionType.unknown, error: const SocketException(leak)),
      ]) {
        final out = AppHelpers.parseError(error, defaultMessage: fallback);
        expect(out['message'], 'checkNetwork', reason: '$error');
        expect('${out['message']}', isNot(contains('api.example.com')));
        expect('${out['message']}', isNot(contains('errno')));
      }
    });

    test('timeouts map to the timeout string', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final out = AppHelpers.parseError(_dio(type), defaultMessage: fallback);
        expect(out['message'], 'requestTimedOut', reason: '$type');
        expect(out['statusCode'], 408);
      }
      final bare = AppHelpers.parseError(
        TimeoutException('took too long', const Duration(seconds: 1)),
        defaultMessage: fallback,
      );
      expect(bare['message'], 'requestTimedOut');
    });

    test('connection, certificate and cancel each map to their string', () {
      expect(
        AppHelpers.parseError(
          _dio(DioExceptionType.connectionError),
        )['message'],
        'checkNetwork',
      );
      expect(
        AppHelpers.parseError(_dio(DioExceptionType.badCertificate))['message'],
        'secureConnectionFailed',
      );
      expect(
        AppHelpers.parseError(_dio(DioExceptionType.cancel))['message'],
        'requestCancelled',
      );
      expect(
        AppHelpers.parseError(
          _dio(
            DioExceptionType.unknown,
            error: const HandshakeException('bad cert'),
          ),
        )['message'],
        'secureConnectionFailed',
      );
    });

    test('an unrecognised unknown falls back rather than leaking', () {
      final out = AppHelpers.parseError(
        _dio(DioExceptionType.unknown, error: StateError('internal detail')),
        defaultMessage: fallback,
      );
      expect(out['message'], fallback);
      expect('${out['message']}', isNot(contains('internal detail')));
    });
  });

  test('badResponse still shows the API message below 500', () {
    final out = AppHelpers.parseError(
      _dio(
        DioExceptionType.badResponse,
        response: _res({'message': 'Insufficient funds'}, 400),
      ),
      defaultMessage: fallback,
    );
    expect(out['message'], 'Insufficient funds');
    expect(out['statusCode'], 400);
  });

  group('a 5xx is never trusted to be the API', () {
    Map<String, dynamic> parse(Object? body, int code) => AppHelpers.parseError(
      _dio(DioExceptionType.badResponse, response: _res(body, code)),
      defaultMessage: fallback,
    );

    test('a gateway 502 with a title is not shown verbatim', () {
      final out = parse({'title': 'Error 502: Bad gateway'}, 502);
      expect(out['message'], 'serverUnavailable');
      expect(out['statusCode'], 502);
    });

    test('a router 503 HTML page is not shown verbatim', () {
      final out = parse('Application is not available… all pods are down', 503);
      expect(out['message'], 'serverUnavailable');
      expect(out['statusCode'], 503);
    });

    test('a gateway 504 with a title is not shown verbatim', () {
      final out = parse({'title': 'Error 504: Gateway time-out'}, 504);
      expect(out['message'], 'serverUnavailable');
      expect(out['statusCode'], 504);
    });

    test('an origin 500 message is not shown verbatim', () {
      final out = parse({
        'Message': 'Object reference not set to an instance of an object',
      }, 500);
      expect(out['message'], 'serverUnavailable');
      expect(out['statusCode'], 500);
    });

    test('a 4xx is unaffected and still reads the body', () {
      final out = parse({'message': 'Account locked'}, 423);
      expect(out['message'], 'Account locked');
      expect(out['statusCode'], 423);
    });
  });

  group('a proxy page below 500 is never trusted to be the API', () {
    Map<String, dynamic> body(int code, {Object? flag = true}) => {
      'title': 'Error $code: Too many requests',
      'status': code,
      'error_name': 'rate_limited',
      'cloudflare_error': flag,
    };

    Map<String, dynamic> parse(Object? body, int code) => AppHelpers.parseError(
      _dio(DioExceptionType.badResponse, response: _res(body, code)),
      defaultMessage: fallback,
    );

    test('a Cloudflare 429 and 403 are not shown verbatim', () {
      for (final code in [429, 403]) {
        final out = parse(body(code), code);
        expect(out['message'], 'requestRefused', reason: '$code');
        expect(out['statusCode'], code);
      }
    });

    test('a flag an interceptor stringified still counts', () {
      final out = parse(body(429, flag: 'true'), 429);
      expect(out['message'], 'requestRefused');
      expect(out['statusCode'], 429);
    });

    test('a bare map handed over by an interceptor is gated too', () {
      final out = AppHelpers.parseError({
        ...body(429),
        'responseCode': '429',
      }, defaultMessage: fallback);
      expect(out['message'], 'requestRefused');
      expect(out['statusCode'], 429);
    });

    test('a flagged page nested under data is gated too', () {
      final out = parse({'data': body(403)}, 403);
      expect(out['message'], 'requestRefused');
      expect(out['statusCode'], 403);
    });

    test('a body that is not flagged still reads its title', () {
      for (final flag in [false, 'false', null]) {
        final out = parse(body(429, flag: flag), 429);
        expect(out['message'], 'Error 429: Too many requests', reason: '$flag');
      }
    });

    test('a flagged 5xx keeps the server-unavailable string', () {
      final out = parse(body(502), 502);
      expect(out['message'], 'serverUnavailable');
      expect(out['statusCode'], 502);
    });
  });

  group('a rejected field reports its own message', () {
    Map<String, dynamic> parse(Object? body, {int code = 400}) =>
        AppHelpers.parseError(
          _dio(DioExceptionType.badResponse, response: _res(body, code)),
          defaultMessage: fallback,
        );

    test('a single rejected field', () {
      final out = parse({
        'title': 'One or more validation errors occurred.',
        'errors': {
          'phoneNumber': ['The phone number is required.'],
        },
      });

      expect(out['message'], 'The phone number is required.');
      expect(out['statusCode'], 400);
    });

    test('several rejected fields are listed one per line', () {
      final out = parse({
        'errors': {
          'phoneNumber': ['The phone number is required.'],
          'bvn': ['The BVN must be 11 digits.', 'The BVN is invalid.'],
        },
      });

      expect(out['message'], '''
The phone number is required.
The BVN must be 11 digits.
The BVN is invalid.''');
    });

    test('a field mapped to a single message rather than a list', () {
      final out = parse({
        'errors': {'bvn': 'The BVN is invalid.'},
      });

      expect(out['message'], 'The BVN is invalid.');
    });

    test('the same message across two fields is said once', () {
      final out = parse({
        'errors': {
          'firstName': ['This field is required.'],
          'lastName': ['This field is required.'],
        },
      });

      expect(out['message'], 'This field is required.');
    });

    test('an explicit message still wins over the field errors', () {
      final out = parse({
        'message': 'Account locked',
        'errors': {
          'bvn': ['The BVN is invalid.'],
        },
      });

      expect(out['message'], 'Account locked');
    });

    test('the title is used only when there are no field messages', () {
      expect(
        parse({'title': 'Validation failed', 'errors': const {}})['message'],
        'Validation failed',
      );
      expect(
        parse({'title': 'Validation failed'})['message'],
        'Validation failed',
      );
    });

    test('an empty title falls through to the default', () {
      expect(parse({'title': '   '})['message'], fallback);
    });

    test('an errors value that is not a map is ignored', () {
      expect(parse({'errors': 'unexpected'})['message'], fallback);
    });
  });
}
