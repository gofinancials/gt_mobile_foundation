import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class _TestHttpService extends AppHttpService {
  _TestHttpService(super.model);
}

class _TestBody extends MapCodable {
  const _TestBody(this.value);

  final Map<String, dynamic> value;

  @override
  Map<String, dynamic> toJson() => value;
}

/// Captures what the interceptor passes down the response pipeline.
///
/// It deliberately does not delegate to `super`, which would complete the
/// handler's future with the response and leave it unobserved.
class _CapturingResponseHandler extends ResponseInterceptorHandler {
  Response? captured;

  @override
  void next(Response response) => captured = response;
}

/// Captures what the interceptor passes down the request pipeline.
class _CapturingRequestHandler extends RequestInterceptorHandler {
  RequestOptions? captured;

  @override
  void next(RequestOptions requestOptions) => captured = requestOptions;
}

/// Captures what the interceptor passes down the error pipeline.
class _CapturingErrorHandler extends ErrorInterceptorHandler {
  DioException? captured;

  @override
  void next(DioException error) => captured = error;
}

void main() {
  group('Crypto interceptors', () {
    const tag = 'OneBankProDevMobileApiKey00001';
    final nonSensitiveMarkers = <String, Map<String, dynamic>>{
      'false sensitivity marker': const {sensitiveRequestExtraKey: false},
      'missing sensitivity marker': const {},
    };
    late AppCryptoServiceImpl cryptoService;

    setUp(() {
      cryptoService = AppCryptoServiceImpl(
        aesKey: '01234567890123456789012345678901',
        appTag: tag,
        tamperProof: true,
      );
    });

    for (final marker in nonSensitiveMarkers.entries) {
      test('EncryptInterceptor tags but leaves the body of requests with '
          '${marker.key}', () async {
        final interceptor = EncryptInterceptor(
          cryptoService,
          mode: .base64,
          strategy: .colonDelimited,
        );
        final body = {'amount': 5000, 'account': '0123456789'};
        final options = RequestOptions(
          path: '/onebankcardservices/GetCardById',
          data: body,
          extra: marker.value,
        );
        final handler = _CapturingRequestHandler();

        interceptor.onRequest(options, handler);
        await Future<void>.delayed(Duration.zero);

        final sent = handler.captured!;
        expect(identical(sent.data, body), isTrue);
        expect(
          cryptoService.decrypt(
            sent.headers['App-Tag'] as String,
            mode: .base64,
            strategy: .colonDelimited,
          ),
          tag,
        );
      });
    }

    for (final marker in nonSensitiveMarkers.entries) {
      test(
        'DecryptInterceptor decrypts ciphertext with ${marker.key}',
        () async {
          final interceptor = DecryptInterceptor(
            cryptoService,
            mode: .base64,
            strategy: .colonDelimited,
          );
          final ciphertext = cryptoService.encrypt(
            '{"status":"success"}',
            mode: .base64,
            strategy: .colonDelimited,
          );
          final response = Response(
            requestOptions: RequestOptions(
              path: '/onebankcardservices/GetCardById',
              extra: {...marker.value},
            ),
            data: {'data': ciphertext},
            statusCode: 200,
          );
          final handler = _CapturingResponseHandler();

          interceptor.onResponse(response, handler);
          await Future<void>.delayed(Duration.zero);

          expect(handler.captured?.data, {
            'data': {'status': 'success'},
          });
        },
      );
    }

    test(
      'DecryptInterceptor leaves a clear reply to a clear request',
      () async {
        final interceptor = DecryptInterceptor(
          cryptoService,
          mode: .base64,
          strategy: .colonDelimited,
        );
        final body = {'responseCode': '00', 'data': 'Card retrieved'};
        final response = Response(
          requestOptions: RequestOptions(
            path: '/onebankcardservices/GetCardById',
          ),
          data: body,
          statusCode: 200,
        );
        final handler = _CapturingResponseHandler();

        interceptor.onResponse(response, handler);
        await Future<void>.delayed(Duration.zero);

        expect(identical(handler.captured?.data, body), isTrue);
      },
    );

    test('DecryptInterceptor decrypts a refusal to a clear request', () async {
      final interceptor = DecryptInterceptor(
        cryptoService,
        mode: .base64,
        strategy: .colonDelimited,
      );
      final ciphertext = cryptoService.encrypt(
        '{"responseCode":"401","message":"Unauthorised client"}',
        mode: .base64,
        strategy: .colonDelimited,
      );
      final requestOptions = RequestOptions(
        path: '/onebankBillspayment/Billspayment/GetEMTLevy',
      );
      final error = DioException.badResponse(
        statusCode: 401,
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          data: ciphertext,
          statusCode: 401,
        ),
      );
      final handler = _CapturingErrorHandler();

      interceptor.onError(error, handler);
      await Future<void>.delayed(Duration.zero);

      expect(handler.captured?.response?.data, {
        'responseCode': '401',
        'message': 'Unauthorised client',
      });
    });

    test('DecryptInterceptor decrypts an envelope read as text', () async {
      final interceptor = DecryptInterceptor(
        cryptoService,
        mode: .base64,
        strategy: .colonDelimited,
      );
      final ciphertext = cryptoService.encrypt(
        '{"transactionId":42}',
        mode: .base64,
        strategy: .colonDelimited,
      );
      final response = Response(
        requestOptions: RequestOptions(
          path: '/api/v1/transfer',
          extra: {sensitiveRequestExtraKey: true},
        ),
        data: '{"responseCode":"00","data":"$ciphertext"}',
        statusCode: 200,
      );
      final handler = _CapturingResponseHandler();

      interceptor.onResponse(response, handler);
      // onResponse is async; let its microtasks drain.
      await Future<void>.delayed(Duration.zero);

      expect(handler.captured?.data, {
        'responseCode': '00',
        'data': {'transactionId': 42},
      });
    });

    test('EncryptInterceptor tags a sensitive request with no body', () async {
      late RequestOptions sentRequest;
      final model = AppHttpModel(
        'https://example.com',
        interceptors: [
          EncryptInterceptor(
            cryptoService,
            mode: .base64,
            strategy: .colonDelimited,
          ),
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sentRequest = options;
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {'responseCode': '00', 'message': 'Successful'},
                  statusCode: 200,
                ),
                true,
              );
            },
          ),
        ],
      );
      final service = _TestHttpService(model);

      await service.get(
        '/onboarding/getonboardingprogress/08012345678',
        isSensitiveRequest: true,
      );

      expect(sentRequest.method, 'GET');
      expect(sentRequest.data, isNull);
      expect(
        cryptoService.decrypt(
          sentRequest.headers['App-Tag'] as String,
          mode: .base64,
          strategy: .colonDelimited,
        ),
        tag,
      );
    });

    test(
      'sensitive requests and responses are transformed end to end',
      () async {
        const requestBody = _TestBody({
          'amount': 5000,
          'account': '0123456789',
        });
        const decryptedResponseData = {'transactionId': 42};
        final encodedResponse = await AppHelpers.encodeJson(
          decryptedResponseData,
        );
        final encryptedResponse = cryptoService.encrypt(
          encodedResponse,
          mode: .base64,
          strategy: .colonDelimited,
        );
        late RequestOptions sentRequest;
        final model = AppHttpModel(
          'https://example.com',
          interceptors: [
            EncryptInterceptor(
              cryptoService,
              mode: .base64,
              strategy: .colonDelimited,
            ),
            InterceptorsWrapper(
              onRequest: (options, handler) {
                sentRequest = options;
                handler.resolve(
                  Response(
                    requestOptions: options,
                    data: {
                      'responseCode': '00',
                      'message': 'Successful',
                      'data': encryptedResponse,
                    },
                    statusCode: 200,
                  ),
                  true,
                );
              },
            ),
            DecryptInterceptor(
              cryptoService,
              mode: .base64,
              strategy: .colonDelimited,
            ),
          ],
        );
        final service = _TestHttpService(model);

        final result = await service.post(
          '/api/v1/transfer',
          body: requestBody,
          isSensitiveRequest: true,
        );

        final encryptedRequest = sentRequest.data as Map;
        final requestCiphertext = encryptedRequest['data'] as String;
        expect(
          cryptoService.decrypt(
            requestCiphertext,
            mode: .base64,
            strategy: .colonDelimited,
          ),
          await AppHelpers.encodeJson(requestBody.toJson()),
        );
        expect(
          cryptoService.decrypt(
            sentRequest.headers['App-Tag'] as String,
            mode: .base64,
            strategy: .colonDelimited,
          ),
          tag,
        );
        expect(result.data, {'transactionId': 42});
        expect(result.responseCode, '00');
        expect(result.message, 'Successful');
        expect(result.rawResponse?.data, {
          'responseCode': '00',
          'message': 'Successful',
          'data': decryptedResponseData,
        });
      },
    );
  });
}
