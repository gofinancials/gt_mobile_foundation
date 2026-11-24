import 'dart:typed_data';

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

    group('large bodies, decrypted and encrypted in the background', () {
      final document = 'A' * (256 * 1024);
      final requestBody = _TestBody({
        'documentType': 'NIN_SLIP',
        'file': document,
      });
      final replyData = {'documentId': 7, 'preview': document};
      final services = <String, AppCryptoService Function()>{
        'AppCryptoServiceImpl': () => cryptoService,
        'another AppCryptoService': () => _DelegatingCrypto(cryptoService),
      };

      for (final entry in services.entries) {
        test('${entry.key} uploads a document and reads the reply', () async {
          final crypto = entry.value();
          final encodedReply = await AppHelpers.encodeJson(replyData);
          final encryptedReply = cryptoService.encrypt(
            encodedReply,
            mode: .base64,
            strategy: .colonDelimited,
          );
          final gateway = _Gateway(encryptedReply);
          final model = AppHttpModel(
            'https://example.com',
            interceptors: gateway.interceptors(crypto),
          );
          final service = _TestHttpService(model);

          final result = await service.post(
            '/onboarding/uploaddocument',
            body: requestBody,
            isSensitiveRequest: true,
          );

          final requestCiphertext = gateway.sentCiphertext;
          final sentPlaintext = cryptoService.decrypt(
            requestCiphertext,
            mode: .base64,
            strategy: .colonDelimited,
          );
          final requestJson = requestBody.toJson();
          final expectedPlaintext = await AppHelpers.encodeJson(requestJson);
          expect(sentPlaintext, expectedPlaintext);
          expect(result.data, replyData);
        });
      }
    });
  });
}

/// A gateway that records the encrypted request and answers with [reply].
class _Gateway {
  _Gateway(this.reply);

  /// The ciphertext the gateway answers with under `data`.
  final String reply;

  late RequestOptions sent;

  /// The ciphertext the request carried under `data`.
  String get sentCiphertext => (sent.data as Map)['data'] as String;

  /// The crypto interceptors around this gateway, using [crypto].
  List<Interceptor> interceptors(AppCryptoService crypto) => [
    EncryptInterceptor(crypto, mode: .base64, strategy: .colonDelimited),
    InterceptorsWrapper(onRequest: _answer),
    DecryptInterceptor(crypto, mode: .base64, strategy: .colonDelimited),
  ];

  void _answer(RequestOptions options, RequestInterceptorHandler handler) {
    sent = options;
    final body = {'responseCode': '00', 'message': 'Successful', 'data': reply};
    final response = Response(
      requestOptions: options,
      data: body,
      statusCode: 200,
    );
    handler.resolve(response, true);
  }
}

/// An [AppCryptoService] that is not [AppCryptoServiceImpl], so the
/// interceptors cannot move its work to a background isolate.
class _DelegatingCrypto implements AppCryptoService {
  _DelegatingCrypto(this._inner);

  final AppCryptoService _inner;

  @override
  String get appTag => _inner.appTag;

  @override
  AppCryptoPayloadStrategy get defaultStrategy => _inner.defaultStrategy;

  @override
  Future<void> init() => _inner.init();

  @override
  String encrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    return _inner.encrypt(
      data,
      mode: mode,
      strategy: strategy,
      associatedData: associatedData,
    );
  }

  @override
  String decrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    return _inner.decrypt(
      data,
      mode: mode,
      strategy: strategy,
      associatedData: associatedData,
    );
  }

  @override
  String? tryDecrypt(
    String? data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    return _inner.tryDecrypt(
      data,
      mode: mode,
      strategy: strategy,
      associatedData: associatedData,
    );
  }

  @override
  String? encryptRsa(String data, {AppCryptoMode mode = .base16}) {
    return _inner.encryptRsa(data, mode: mode);
  }
}
