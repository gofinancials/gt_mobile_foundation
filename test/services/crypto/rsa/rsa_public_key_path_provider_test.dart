import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:gt_mobile_foundation/foundation.dart';

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this.pem);

  final String pem;

  @override
  Future<ByteData> load(String key) async {
    final bytes = pem.codeUnits;
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => pem;
}

class _FakeHttpService extends AppHttpService {
  _FakeHttpService(this.responsePem, {this.error})
    : super(AppHttpModel('https://example.com'));

  final String responsePem;
  final Object? error;
  int callCount = 0;

  @override
  Future<ApiResponse<Response>> get(
    String path, {
    Codable? query,
    Options? options,
    ProgressCallback? onReceiveProgress,
  }) async {
    callCount++;
    if (error != null) {
      throw error!;
    }
    return ApiResponse(
      data: responsePem,
      rawResponse: Response(
        requestOptions: RequestOptions(path: path),
        data: responsePem,
        statusCode: 200,
        statusMessage: 'OK',
      ),
    );
  }
}

void main() {
  const validPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALdUOQ9I5nqz4c7L0zq4fO4Xb4K6xK1S\n'
      'xjQk1a3k8uQ4Qp8w9q2P8sJ6g4p1t8YxQGm5m2zG3x0CAwEAAQ==\n'
      '-----END PUBLIC KEY-----\n';
  const invalidPem = 'not a pem';
  const privatePem =
      '-----BEGIN RSA PRIVATE KEY-----\nabc\n-----END RSA PRIVATE KEY-----\n';

  group('LocalRsaPublicKeyPathProvider', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('rsa_local_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('copies a valid PEM asset and returns an absolute path', () async {
      final provider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle(validPem),
        assetPath: 'assets/public_key.pem',
        directory: tempDir,
      );

      final path = await provider.getPublicKeyPath();
      final file = File(path);

      expect(path, isNotEmpty);
      expect(p.isAbsolute(file.path), isTrue);
      expect(file.existsSync(), isTrue);
      expect(await file.readAsString(), validPem);
    });

    test('reuses an existing valid cached file', () async {
      final file = File('${tempDir.path}/rsa_public_key.pem');
      await file.writeAsString(validPem);

      final provider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle('should not be used'),
        assetPath: 'assets/public_key.pem',
        directory: tempDir,
      );

      final path = await provider.getPublicKeyPath();

      expect(path, file.absolute.path);
      expect(await file.readAsString(), validPem);
    });

    test('rejects empty PEM content', () async {
      final provider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle(''),
        assetPath: 'assets/public_key.pem',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('rejects malformed PEM content', () async {
      final provider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle(invalidPem),
        assetPath: 'assets/public_key.pem',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('rejects private-key PEM content', () async {
      final provider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle(privatePem),
        assetPath: 'assets/public_key.pem',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('propagates write failures as provider exceptions', () async {
      Directory('${tempDir.path}/rsa_public_key.pem').createSync();
      final provider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle(validPem),
        assetPath: 'assets/public_key.pem',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(forceRefresh: true),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });
  });

  group('RemoteRsaPublicKeyPathProvider', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('rsa_remote_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'uses the existing network service and stores a successful response',
      () async {
        final http = _FakeHttpService(validPem);
        final provider = RemoteRsaPublicKeyPathProvider(
          httpService: http,
          endpoint: '/public-key',
          directory: tempDir,
        );

        final path = await provider.getPublicKeyPath();
        final file = File(path);

        expect(http.callCount, 1);
        expect(path, file.absolute.path);
        expect(await file.readAsString(), validPem);
      },
    );

    test('reuses a valid cached file without another network call', () async {
      final http = _FakeHttpService('should not download');
      final file = File('${tempDir.path}/rsa_public_key.pem');
      await file.writeAsString(validPem);

      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: http,
        endpoint: '/public-key',
        directory: tempDir,
      );

      final path = await provider.getPublicKeyPath();

      expect(path, file.absolute.path);
      expect(http.callCount, 0);
    });

    test('handles malformed PEM content', () async {
      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: _FakeHttpService(invalidPem),
        endpoint: '/public-key',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('rejects private-key content', () async {
      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: _FakeHttpService(privatePem),
        endpoint: '/public-key',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('handles an empty response', () async {
      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: _FakeHttpService(''),
        endpoint: '/public-key',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('handles network failures', () async {
      final http = _FakeHttpService(
        validPem,
        error: const SocketException('network down'),
      );
      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: http,
        endpoint: '/public-key',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(forceRefresh: true),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });

    test('supports refresh and replaces the cached file', () async {
      final http = _FakeHttpService(
        validPem.replaceFirst('BQADSwAwSAJB', 'BQADSwAwSAJC'),
      );
      final file = File('${tempDir.path}/rsa_public_key.pem');
      await file.writeAsString(validPem);

      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: http,
        endpoint: '/public-key',
        directory: tempDir,
      );

      final path = await provider.getPublicKeyPath(forceRefresh: true);

      expect(http.callCount, 1);
      expect(path, file.absolute.path);
      expect(await file.readAsString(), contains('SAJC'));
    });

    test('propagates write failures correctly', () async {
      Directory('${tempDir.path}/rsa_public_key.pem').createSync();
      final provider = RemoteRsaPublicKeyPathProvider(
        httpService: _FakeHttpService(validPem),
        endpoint: '/public-key',
        directory: tempDir,
      );

      expect(
        provider.getPublicKeyPath(forceRefresh: true),
        throwsA(isA<RsaPublicKeyPathProviderException>()),
      );
    });
  });

  group('TestRsaPublicKeyPathProvider', () {
    test(
      'returns the injected path without loading assets or network calls',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('rsa_test_');
        final file = File('${tempDir.path}/test_public_key.pem');
        await file.writeAsString(validPem);

        final provider = TestRsaPublicKeyPathProvider(file.path);
        final path = await provider.getPublicKeyPath();

        expect(path, file.path);
        expect(await file.readAsString(), validPem);

        tempDir.deleteSync(recursive: true);
      },
    );
  });
}
