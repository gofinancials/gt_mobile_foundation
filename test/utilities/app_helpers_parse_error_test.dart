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

Response _res(dynamic data, int code, {Map<String, dynamic>? extra}) =>
    Response(requestOptions: _opts, data: data, statusCode: code, extra: extra);

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
      'responseMessage key': {'responseMessage': 'Unauthorized client'},
      'ResponseMessage key': {'ResponseMessage': 'Unauthorized client'},
      'ResponseMessage nested under data': {
        'data': {
          'IsSuccessful': false,
          'ResponseCode': '04',
          'ResponseMessage': 'Unauthorized client',
        },
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

    test('the gateway code is read in either case', () {
      final bodies = {
        'camelCase': {
          'isSuccessful': false,
          'responseCode': '3',
          'responseMessage': 'Invalid Phone Number',
        },
        'PascalCase': {
          'IsSuccessful': false,
          'ResponseCode': '3',
          'ResponseMessage': 'Invalid Phone Number',
          'Data': null,
        },
        'PascalCase nested under data': {
          'data': {
            'IsSuccessful': false,
            'ResponseCode': '3',
            'ResponseMessage': 'Invalid Phone Number',
          },
        },
      };
      bodies.forEach((label, body) {
        final out = AppHelpers.parseError(
          _dio(DioExceptionType.badResponse, response: _res(body, 400)),
          defaultMessage: fallback,
        );
        expect(out['message'], 'Invalid Phone Number', reason: label);
        expect(out['statusCode'], 3, reason: label);
      });
    });

    test('a blank message does not hide the envelope ResponseMessage', () {
      final out = AppHelpers.parseError({
        'message': '',
        'ResponseMessage': 'Unauthorized client',
      }, defaultMessage: fallback);
      expect(out['message'], 'Unauthorized client');
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

  group('a 5xx is not trusted to be the API unless it reads as the API', () {
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

    test('an undecryptable 500 body is not shown verbatim', () {
      final out = parse({'data': 'not-ciphertext-at-all'}, 500);
      expect(out['message'], 'serverUnavailable');
      expect(out['statusCode'], 500);
    });

    test('a responseMessage with no code or flag beside it is not trusted', () {
      final out = parse({'responseMessage': 'Upstream exploded'}, 500);
      expect(out['message'], 'serverUnavailable');
    });
  });

  group('a 5xx the API wrote shows its message', () {
    const locked =
        'Profile locked. Please click Forgot Passcode? to reset or Contact '
        'Support';
    const decrypted = {decryptedResponseExtraKey: true};

    Map<String, dynamic> parse(
      Object? body,
      int code, {
      Map<String, dynamic>? extra,
    }) => AppHelpers.parseError(
      _dio(
        DioExceptionType.badResponse,
        response: _res(body, code, extra: extra),
      ),
      defaultMessage: fallback,
    );

    test('a decrypted 500 refusal nested under data', () {
      final out = parse(
        {
          'data': {
            'isSuccessful': false,
            'responseCode': 3,
            'responseMessage': locked,
          },
        },
        500,
        extra: decrypted,
      );
      expect(out['message'], locked);
      expect(out['statusCode'], 3);
    });

    test('a decrypted 500 refusal under the capital-D Data spelling', () {
      final out = parse(
        {
          'Data': {
            'IsSuccessful': false,
            'ResponseCode': '3',
            'ResponseMessage': 'Invalid request, invalid debit Account name.',
          },
        },
        500,
        extra: decrypted,
      );
      expect(out['message'], 'Invalid request, invalid debit Account name.');
      expect(out['statusCode'], 3);
    });

    test('a decrypted 500 is trusted even without the envelope', () {
      final out = parse(
        {
          'data': {'message': 'Daily limit exceeded'},
        },
        500,
        extra: decrypted,
      );
      expect(out['message'], 'Daily limit exceeded');
      expect(out['statusCode'], 500);
    });

    test('a decrypted text 500 reads as text, a blank one as the default', () {
      final out = parse({'data': 'plain text'}, 500, extra: decrypted);
      expect(out['message'], 'plain text');

      final empty = parse({'data': ''}, 500, extra: decrypted);
      expect(empty['message'], fallback);
    });

    test('a clear 500 envelope at the top level', () {
      final out = parse({'responseCode': '3', 'responseMessage': locked}, 500);
      expect(out['message'], locked);
      expect(out['statusCode'], 3);
    });

    test('a clear 500 envelope keyed by its success flag', () {
      final out = parse({
        'IsSuccessful': false,
        'ResponseMessage': locked,
      }, 500);
      expect(out['message'], locked);
      expect(out['statusCode'], 500);
    });

    test('a clear 500 envelope nested under data', () {
      final out = parse({
        'data': {'isSuccessful': false, 'responseMessage': locked},
      }, 500);
      expect(out['message'], locked);
    });

    test('a clear 500 envelope read as text', () {
      final out = parse(
        '{"responseCode":"3","responseMessage":"$locked"}',
        500,
      );
      expect(out['message'], locked);
      expect(out['statusCode'], 3);
    });

    test('a 502, 503 or 504 that carries the envelope is trusted too', () {
      for (final code in [502, 503, 504]) {
        final out = parse({
          'responseCode': '96',
          'responseMessage': locked,
        }, code);
        expect(out['message'], locked, reason: '$code');
      }
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

  group('a string is shown only when it reads as a message', () {
    const page = '<!DOCTYPE html><html><body>403 Forbidden</body></html>';
    const flagged =
        '{"title":"Error 429: Too many requests","cloudflare_error":true}';

    test('a message a repository threw on purpose passes through', () {
      final out = AppHelpers.parseError(
        'Insufficient funds',
        defaultMessage: fallback,
      );
      expect(out['message'], 'Insufficient funds');
      expect(out['statusCode'], 500);
    });

    test('an HTML page falls back rather than leaking', () {
      for (final html in [page, '  <center>nginx</center>', 'x <HTML> y']) {
        final out = AppHelpers.parseError(html, defaultMessage: fallback);
        expect(out['message'], fallback, reason: html);
      }
    });

    test('a stringified proxy page meets the proxy check', () {
      final out = AppHelpers.parseError(flagged, defaultMessage: fallback);
      expect(out['message'], 'requestRefused');
    });

    test('a stringified API body still gives its message', () {
      final out = AppHelpers.parseError(
        '{"message":"Account locked","responseCode":"423"}',
        defaultMessage: fallback,
      );
      expect(out['message'], 'Account locked');
      expect(out['statusCode'], 423);
    });

    test('text that only opens with a brace is still a message', () {
      final out = AppHelpers.parseError('{oops', defaultMessage: fallback);
      expect(out['message'], '{oops');
    });

    test('a page nested under data falls back and keeps the status', () {
      final out = AppHelpers.parseError({
        'responseCode': '403',
        'data': page,
      }, defaultMessage: fallback);
      expect(out['message'], fallback);
      expect(out['statusCode'], 403);
    });

    test('a message nested under data as a string is still shown', () {
      final out = AppHelpers.parseError({
        'responseCode': '422',
        'data': 'Daily limit exceeded',
      }, defaultMessage: fallback);
      expect(out['message'], 'Daily limit exceeded');
      expect(out['statusCode'], 422);
    });

    test('a Dio body read as plain text is decoded before it is read', () {
      Map<String, dynamic> parse(String body, int code) =>
          AppHelpers.parseError(
            _dio(DioExceptionType.badResponse, response: _res(body, code)),
            defaultMessage: fallback,
          );

      expect(
        parse('{"message":"Account locked"}', 423)['message'],
        'Account locked',
      );
      expect(parse(flagged, 429)['message'], 'requestRefused');
      expect(parse(page, 403)['message'], fallback);
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
  group('a blank or placeholder message is no message', () {
    const placeholders = [
      '<none>',
      'none',
      'null',
      ' NONE ',
      'Null',
      ' <None>',
    ];

    for (final placeholder in placeholders) {
      test('"$placeholder" as the message falls back', () {
        final out = AppHelpers.parseError({
          'message': placeholder,
          'responseCode': '400',
        }, defaultMessage: fallback);
        expect(out['message'], fallback);
        expect(out['statusCode'], 400);
      });

      test('"$placeholder" thrown as a string falls back', () {
        final out = AppHelpers.parseError(
          placeholder,
          defaultMessage: fallback,
        );
        expect(out['message'], fallback);
      });

      test('"$placeholder" in a 4xx body falls back', () {
        final out = AppHelpers.parseError(
          _dio(
            DioExceptionType.badResponse,
            response: _res({'message': placeholder}, 400),
          ),
          defaultMessage: fallback,
        );
        expect(out['message'], fallback);
        expect(out['statusCode'], 400);
      });
    }

    test('an empty message falls through to the field errors', () {
      final out = AppHelpers.parseError({
        'message': '',
        'errors': {
          'amount': ['Amount is required'],
        },
      }, defaultMessage: fallback);
      expect(out['message'], 'Amount is required');
    });

    test('a placeholder message falls through to the error key', () {
      final out = AppHelpers.parseError({
        'message': '<none>',
        'error': 'Account locked',
      }, defaultMessage: fallback);
      expect(out['message'], 'Account locked');
    });

    test('a placeholder message falls through to a nested body', () {
      final out = AppHelpers.parseError({
        'message': 'null',
        'data': {'message': 'Daily limit exceeded'},
      }, defaultMessage: fallback);
      expect(out['message'], 'Daily limit exceeded');
    });

    test('a placeholder nested under data falls back', () {
      final out = AppHelpers.parseError({
        'data': '<none>',
      }, defaultMessage: fallback);
      expect(out['message'], fallback);
    });

    test('placeholder field errors are dropped', () {
      final out = AppHelpers.parseError({
        'errors': {
          'nin': ['<none>'],
          'amount': ['Amount is required', null],
        },
      }, defaultMessage: fallback);
      expect(out['message'], 'Amount is required');
    });

    test('a placeholder title falls back', () {
      final out = AppHelpers.parseError({
        'title': 'none',
      }, defaultMessage: fallback);
      expect(out['message'], fallback);
    });

    test('a message is trimmed', () {
      final out = AppHelpers.parseError({
        'message': '  Insufficient funds ',
      }, defaultMessage: fallback);
      expect(out['message'], 'Insufficient funds');
    });
  });
}
