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
      test('EncryptInterceptor skips requests with ${marker.key}', () {
        final interceptor = EncryptInterceptor(
          cryptoService,
          mode: .base64,
          strategy: .colonDelimited,
        );
        final body = {'amount': 5000, 'account': '0123456789'};
        final options = RequestOptions(
          path: '/api/v1/transfer',
          data: body,
          extra: marker.value,
        );
        final handler = RequestInterceptorHandler();

        interceptor.onRequest(options, handler);

        expect(handler.isCompleted, isTrue);
        expect(identical(options.data, body), isTrue);
        expect(options.headers, isNot(contains('App-Tag')));
      });
    }

    for (final marker in nonSensitiveMarkers.entries) {
      test('DecryptInterceptor skips valid ciphertext with ${marker.key}', () {
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
        final encryptedBody = {'data': ciphertext};
        final response = Response(
          requestOptions: RequestOptions(
            path: '/api/v1/transfer',
            extra: marker.value,
          ),
          data: encryptedBody,
          statusCode: 200,
        );
        final handler = ResponseInterceptorHandler();

        interceptor.onResponse(response, handler);

        expect(handler.isCompleted, isTrue);
        expect(identical(response.data, encryptedBody), isTrue);
        expect(response.data, {'data': ciphertext});
      });
    }

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
