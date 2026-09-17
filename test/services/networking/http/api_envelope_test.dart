import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

import '../../../support/test_config.dart';

/// A reply as it reaches a service: [data] is what the crypto interceptor
/// unwrapped, [raw] is the outer wrapper that unwrap came from.
DioResponse _reply({required Object? data, Object? raw}) {
  return DioResponse(
    data: data,
    rawResponse: Response(
      requestOptions: RequestOptions(path: '/accounts'),
      data: raw,
    ),
  );
}

/// The two layers a live encrypted reply has.
Map<String, dynamic> _wrapper(Map<String, dynamic> envelope) => {
  'responseCode': '00',
  'data': envelope,
};

class _Service with AppHttpMixin {}

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

    test('falls back to the refusal message, not the unexpected-failure one', () {
      expect(
        ApiEnvelope.refusalMessage({'isSuccessful': false}),
        'requestRefused',
      );
    });
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
