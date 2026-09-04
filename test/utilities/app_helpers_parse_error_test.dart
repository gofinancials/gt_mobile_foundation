import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// Minimal [AppConfig] exposing only [strings]; every other member is unused by
/// [AppHelpers.parseError].
class _TestConfig implements AppConfig {
  @override
  AppConfigStrings get strings => const AppConfigStrings(
    seconds: 'seconds',
    minutes: 'minutes',
    requestFailedUnexpectedly: 'requestFailedUnexpectedly',
    checkNetwork: 'checkNetwork',
    noInternet: 'noInternet',
    momentsAgo: 'momentsAgo',
    minutesAgo: 'minutesAgo',
    anHourAgo: 'anHourAgo',
    hoursAgo: 'hoursAgo',
    daysAgo: 'daysAgo',
    daysOld: 'daysOld',
    weeksOld: 'weeksOld',
    monthsOld: 'monthsOld',
    yearsOld: 'yearsOld',
    yesterday: 'yesterday',
    fieldRequired: 'fieldRequired',
    passwordRequired: 'passwordRequired',
    passwordMustHaveNChars: 'passwordMustHaveNChars',
    invalidEmail: 'invalidEmail',
    provideValidEmail: 'provideValidEmail',
    invalidPhone: 'invalidPhone',
    invalidDate: 'invalidDate',
    mustBeNYears: 'mustBeNYears',
    invalidUrl: 'invalidUrl',
    invalidAmount: 'invalidAmount',
    amountMinimum: 'amountMinimum',
    amountMaximum: 'amountMaximum',
    fieldsDontMatch: 'fieldsDontMatch',
    invalidNumber: 'invalidNumber',
    minLength: 'minLength',
    maxLength: 'maxLength',
    insufficentFunds: 'insufficentFunds',
    copiedFromClipboard: 'copiedFromClipboard',
    copiedToClipboard: 'copiedToClipboard',
    requestTimedOut: 'requestTimedOut',
    secureConnectionFailed: 'secureConnectionFailed',
    requestCancelled: 'requestCancelled',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

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
  setUpAll(() {
    if (!locator.isRegistered<AppConfig>()) {
      locator.registerSingleton<AppConfig>(_TestConfig());
    }
  });

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
  });

  group('transport failures are sanitised', () {
    test('SocketException text never reaches the message', () {
      const leak = "Failed host lookup: 'api.example.com' (OS Error: errno = 8)";
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
        AppHelpers.parseError(_dio(DioExceptionType.connectionError))['message'],
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
          _dio(DioExceptionType.unknown, error: const HandshakeException('bad cert')),
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

  test('badResponse still shows the API message', () {
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
}
