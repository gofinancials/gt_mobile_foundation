import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class _TestHttpService extends AppHttpService {
  _TestHttpService(super.model);
}

typedef _RequestCall = Future<DioResponse> Function(AppHttpService service);

Future<RequestOptions> _captureRequest(_RequestCall call) async {
  late RequestOptions capturedOptions;
  final captureInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      capturedOptions = options;
      handler.resolve(
        Response(
          requestOptions: options,
          data: const {'status': 'success'},
          statusCode: 200,
        ),
      );
    },
  );
  final service = _TestHttpService(
    AppHttpModel('https://example.com', interceptors: [captureInterceptor]),
  );

  await call(service);
  return capturedOptions;
}

void main() {
  group('AppHttpService request sensitivity', () {
    final nonSensitiveRequests = <String, _RequestCall>{
      'PUT': (service) => service.put('/put'),
      'PATCH': (service) => service.patch('/patch'),
      'POST': (service) => service.post('/post'),
      'DELETE': (service) => service.delete('/delete'),
    };

    for (final request in nonSensitiveRequests.entries) {
      test('${request.key} is marked as non-sensitive by default', () async {
        final options = await _captureRequest(request.value);

        expect(options.extra[sensitiveRequestExtraKey], isFalse);
      });
    }

    test('multipart POST does not carry sensitivity metadata', () async {
      final options = await _captureRequest(
        (service) => service.postFile('/post-file'),
      );

      expect(options.extra, isNot(contains(sensitiveRequestExtraKey)));
    });

    test('explicit false overrides a previous true value', () async {
      final options = await _captureRequest(
        (service) => service.post(
          '/post',
          options: Options(
            extra: const {
              sensitiveRequestExtraKey: true,
              'existing-option': 'preserved',
            },
          ),
          isSensitiveRequest: false,
        ),
      );

      expect(options.extra[sensitiveRequestExtraKey], isFalse);
      expect(options.extra['existing-option'], 'preserved');
    });

    test('explicit true marks the request as sensitive', () async {
      final options = await _captureRequest(
        (service) => service.post('/post', isSensitiveRequest: true),
      );

      expect(options.extra[sensitiveRequestExtraKey], isTrue);
    });
  });
}
