import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../../../support/test_config.dart';

/// A reply as it reaches a service: [data] is what the crypto interceptor
/// unwrapped, [raw] is the outer wrapper that unwrap came from.
///
/// [statusCode] is what the transport answered and [responseCode] is what the
/// gateway nested in the body; they are separate so a test can tell which one
/// was read.
DioResponse _reply({
  required Object? data,
  Object? raw,
  int? statusCode,
  String responseCode = '200',
}) {
  return DioResponse(
    responseCode: responseCode,
    data: data,
    rawResponse: Response(
      requestOptions: RequestOptions(path: '/accounts'),
      data: raw,
      statusCode: statusCode,
    ),
  );
}

/// The two layers a live encrypted reply has.
Map<String, dynamic> _wrapper(Map<String, dynamic> envelope) => {
  'responseCode': '00',
  'data': envelope,
};

class _Service with AppHttpMixin {}

class _RecordingCrashlytics implements AppCrashlyticsService {
  /// The message and error of every report, in order.
  final reports = <(String, Object?)>[];

  @override
  Future<void> init() async {}

  @override
  trackError(
    String message, {
    Object? error,
    StackTrace? trace,
    bool fatal = false,
  }) {
    reports.add((message, error));
  }

  @override
  identifyUser({
    required dynamic id,
    required String accountNumber,
    String? name,
  }) {}
}

void main() {
  setUpAll(registerTestConfig);

  group('ApiEnvelope.of', () {
    test('an encrypted reply is read at the layer carrying the flag', () {
      // The single unwrap lands on the decrypted inner envelope.
      final envelope = {
        'isSuccessful': true,
        'responseMessage': 'ok',
        'data': {'id': 1},
      };

      final read = ApiEnvelope.of(
        _reply(data: envelope, raw: _wrapper(envelope)),
      );

      expect(AppJson.successFlag(read), isTrue);
      expect(read['data'], {'id': 1});
    });

    test('a plaintext reply keeps the status its unwrap consumed', () {
      // The unwrap consumed the only envelope there was, so the payload
      // arrives without the flag and the wrapper still has it.
      final read = ApiEnvelope.of(
        _reply(
          data: {'id': 1},
          raw: {
            'isSuccessful': false,
            'responseMessage': 'Refused',
            'data': {'id': 1},
          },
        ),
      );

      expect(AppJson.successFlag(read), isFalse);
      expect(AppJson.message(read), 'Refused');
      expect(read['id'], 1);
    });

    test('the wrapper data never shadows the payload', () {
      final read = ApiEnvelope.of(
        _reply(
          data: {'id': 1},
          raw: {
            'isSuccessful': true,
            'data': {'id': 999},
          },
        ),
      );

      expect(read['id'], 1);
      expect(read['data'], isNull);
    });

    test('a refused list reply is a refusal, not an empty list', () {
      final read = ApiEnvelope.of(
        _reply(
          data: const [],
          raw: {'isSuccessful': false, 'responseMessage': 'Refused'},
        ),
      );

      expect(AppJson.successFlag(read), isFalse);
      expect(AppJson.message(read), 'Refused');
      expect(read['data'], isEmpty);
    });

    test('a list reply carries its items under data', () {
      final read = ApiEnvelope.of(
        _reply(data: const [1, 2], raw: {'isSuccessful': true}),
      );

      expect(AppJson.successFlag(read), isTrue);
      expect(read['data'], [1, 2]);
    });

    test('an empty unwrap falls back to the wrapper payload', () {
      final read = ApiEnvelope.of(
        _reply(
          data: null,
          raw: {
            'isSuccessful': true,
            'data': {'id': 1},
          },
        ),
      );

      expect(read['id'], 1);
      expect(AppJson.successFlag(read), isTrue);
    });

    test('a reply with no wrapper at all is read as it stands', () {
      final read = ApiEnvelope.of(
        _reply(data: {'isSuccessful': true, 'id': 1}),
      );

      expect(AppJson.successFlag(read), isTrue);
      expect(read['id'], 1);
    });
  });

  group('ApiEnvelope.accepts', () {
    test('a reported refusal is refused either way', () {
      for (final require in [true, false]) {
        expect(
          ApiEnvelope.accepts({
            'isSuccessful': false,
          }, requireSuccessFlag: require),
          isFalse,
        );
      }
    });

    test('a reported success is accepted either way', () {
      for (final require in [true, false]) {
        expect(
          ApiEnvelope.accepts({
            'isSuccessful': true,
          }, requireSuccessFlag: require),
          isTrue,
        );
      }
    });

    test('a missing flag fails closed only when required', () {
      expect(ApiEnvelope.accepts({'id': 1}, requireSuccessFlag: true), isFalse);
      expect(ApiEnvelope.accepts({'id': 1}, requireSuccessFlag: false), isTrue);
    });

    test('a success the gateway spelled as a string is accepted', () {
      // A gateway that reports success as '1' had every accepted call read as
      // a refusal here, and every one of them became a TaskFailure.
      for (final require in [true, false]) {
        expect(
          ApiEnvelope.accepts({
            'isSuccessful': '1',
          }, requireSuccessFlag: require),
          isTrue,
        );
        expect(
          ApiEnvelope.accepts({
            'isSuccessful': '0',
          }, requireSuccessFlag: require),
          isFalse,
        );
      }
    });
  });

  group('ApiEnvelope.refusalMessage', () {
    test('prefers the gateway message', () {
      expect(
        ApiEnvelope.refusalMessage({'responseMessage': 'Insufficient funds'}),
        'Insufficient funds',
      );
    });

    test(
      'falls back to the refusal message, not the unexpected-failure one',
      () {
        expect(
          ApiEnvelope.refusalMessage({'isSuccessful': false}),
          'requestRefused',
        );
      },
    );
  });

  group('sendEnvelope', () {
    final service = _Service();

    test('a refused 200 is a failure carrying the gateway message', () async {
      final result = await service.sendEnvelope(
        () async =>
            _reply(data: {'isSuccessful': false, 'responseMessage': 'Refused'}),
        (envelope) => envelope['id'],
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'Refused');
    });

    test('an accepted 200 decodes its payload', () async {
      final result = await service.sendEnvelope(
        () async => _reply(data: {'isSuccessful': true, 'id': 1}),
        (envelope) => envelope['id'],
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 1);
    });

    test('a success flagged as a string still decodes its payload', () async {
      final result = await service.sendEnvelope(
        () async => _reply(data: {'isSuccessful': '1', 'id': 1}),
        (envelope) => envelope['id'],
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 1);
    });

    test('a mutation refuses a reply that reported neither way', () async {
      final result = await service.sendEnvelope(
        () async => _reply(data: {'id': 1}),
        (envelope) => envelope['id'],
      );

      expect(result.isFailure, isTrue);
    });

    test('a read accepts a reply that reported neither way', () async {
      final result = await service.sendEnvelope(
        () async => _reply(data: {'id': 1}),
        (envelope) => envelope['id'],
        requireSuccessFlag: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, 1);
    });

    test('a transport failure stays a failure', () async {
      final result = await service.sendEnvelope<int>(
        () async => throw DioException(
          requestOptions: RequestOptions(path: '/accounts'),
          type: DioExceptionType.connectionTimeout,
        ),
        (envelope) => 1,
      );

      expect(result.isFailure, isTrue);
    });

    test('a refusal carries the status the reply arrived with', () async {
      final result = await service.sendEnvelope(
        () async =>
            _reply(data: {'isSuccessful': false, 'responseMessage': 'Refused'}),
        (envelope) => envelope['id'],
      );

      // The gateway answered; it refused in the body. Stamping that 500 sends
      // whoever reads the failure looking for a server fault that never was.
      expect(result.error?.statusCode, '200');
    });

    test('a decoder that throws is a failure, not a rejected future', () async {
      final result = await service.sendEnvelope<Map<String, dynamic>>(
        () async => _reply(data: {'isSuccessful': true, 'data': 'not-a-map'}),
        (envelope) => envelope['data'] as Map<String, dynamic>,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'malformedResponse');
      expect(result.error?.statusCode, '200');
    });

    test('a decoder that throws keeps the exception it threw', () async {
      final failure = FormatException('unreadable');
      final result = await service.sendEnvelope<int>(
        () async => _reply(data: {'isSuccessful': true, 'id': 1}),
        (envelope) => throw failure,
      );

      expect(result.error?.error, same(failure));
    });

    test('a read that reported neither way still guards its decoder', () async {
      // The case most exposed to a decoder throw: with no flag to read, the
      // payload is the only evidence, so a payload it cannot read is all the
      // failure there is.
      final result = await service.sendEnvelope<int>(
        () async => _reply(data: {'id': 'not-a-number'}),
        (envelope) => envelope['id'] as int,
        requireSuccessFlag: false,
      );

      expect(result.isFailure, isTrue);
      expect(result.errorMessage, 'malformedResponse');
    });

    test('a failure reads the transport status, not the business code', () async {
      // Without a stated status every reply reads as the 200 fallback, which a
      // constant would satisfy too. 201 and '00' differ from it and each other.
      DioResponse created(Map<String, dynamic> data) =>
          _reply(data: data, statusCode: 201, responseCode: '00');

      final refused = await service.sendEnvelope(
        () async => created({'isSuccessful': false}),
        (envelope) => envelope['id'],
      );
      final unreadable = await service.sendEnvelope<int>(
        () async => created({'isSuccessful': true, 'id': 'not-a-number'}),
        (envelope) => envelope['id'] as int,
      );

      expect(refused.error?.statusCode, '201');
      expect(unreadable.error?.statusCode, '201');
    });

    group('reporting a decoder that throws', () {
      late _RecordingCrashlytics crashlytics;

      setUp(() {
        crashlytics = _RecordingCrashlytics();
        locator.registerSingleton<AppCrashlyticsService>(crashlytics);
      });

      tearDown(() => locator.unregister<AppCrashlyticsService>());

      test('names the failure without repeating what it said', () async {
        // A FormatException carries its source, and the source is the payload.
        const source = '{"accountNumber": "0123456789"}';
        final result = await service.sendEnvelope<int>(
          () async => _reply(data: {'isSuccessful': true}),
          (envelope) => throw const FormatException('bad amount', source),
        );

        final (message, error) = crashlytics.reports.single;
        expect(message, 'MalformedResponse: FormatException');
        expect('$error', 'MalformedResponse: FormatException');
        expect('$message $error', isNot(contains('0123456789')));

        // The caller, on the device, still gets the exception itself.
        expect(result.error?.error, isA<FormatException>());
      });
    });

    test('a refused envelope is never decoded', () async {
      // The decoder throws on everything, so a refusal that reached it would
      // report the decoder's failure instead of the gateway's own message.
      var decoded = false;
      final result = await service.sendEnvelope<int>(
        () async =>
            _reply(data: {'isSuccessful': false, 'responseMessage': 'Refused'}),
        (envelope) {
          decoded = true;
          throw StateError('decoded a refusal');
        },
      );

      expect(decoded, isFalse);
      expect(result.errorMessage, 'Refused');
    });
  });

  group('ApiResponse.fromJson', () {
    test('reads the success flag the gateway sent', () {
      expect(
        ApiResponse.fromJson({'isSuccessful': false, 'data': {}}).isSuccessful,
        isFalse,
      );
      expect(
        ApiResponse.fromJson({'IsSuccess': true, 'data': {}}).isSuccessful,
        isTrue,
      );
    });

    test('a reply that reported neither way leaves the flag null', () {
      expect(ApiResponse.fromJson({'data': {}}).isSuccessful, isNull);
    });

    test('still unwraps the payload as it always did', () {
      final response = ApiResponse.fromJson({
        'responseCode': '99',
        'message': 'Refused',
        'isSuccessful': false,
        'data': {'id': 1},
      });

      expect(response.data, {'id': 1});
      expect(response.responseCode, '99');
      expect(response.message, 'Refused');
    });
  });
}
