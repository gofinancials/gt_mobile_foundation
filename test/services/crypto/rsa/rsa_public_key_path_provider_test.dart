import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:gt_mobile_foundation/foundation.dart';

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this.pem, {this.beforeLoad});

  final String pem;
  final Future<void> Function()? beforeLoad;

  @override
  Future<ByteData> load(String key) async {
    final bytes = pem.codeUnits;
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    await beforeLoad?.call();
    return pem;
  }
}

class _FakeHttpService extends AppHttpService {
  _FakeHttpService(this.responsePem, {this.error, this.beforeGet})
    : super(AppHttpModel('https://example.com'));

  final String responsePem;
  final Object? error;
  final Future<void> Function()? beforeGet;
  int callCount = 0;

  @override
  Future<ApiResponse<Response>> get(
    String path, {
    Codable? query,
    Options? options,
    ProgressCallback? onReceiveProgress,
    bool isSensitiveRequest = false,
  }) async {
    callCount++;
    await beforeGet?.call();
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

  for (final source in ['local', 'remote']) {
    group('$source cache path security', () {
      late Directory root;
      late Directory cache;
      late _FakeHttpService http;
      late _FakeAssetBundle assets;

      setUp(() {
        root = Directory.systemTemp.createTempSync('rsa_path_security_');
        cache = Directory(p.join(root.path, 'cache'))..createSync();
        http = _FakeHttpService(validPem);
        assets = _FakeAssetBundle(validPem);
      });

      tearDown(() => root.deleteSync(recursive: true));

      RsaPublicKeyPathProvider provider({
        String fileName = 'rsa_public_key.pem',
      }) => source == 'local'
          ? LocalRsaPublicKeyPathProvider(
              assetBundle: assets,
              assetPath: 'assets/public_key.pem',
              directory: cache,
              fileName: fileName,
            )
          : RemoteRsaPublicKeyPathProvider(
              httpService: http,
              endpoint: '/public-key',
              directory: cache,
              fileName: fileName,
            );

      for (final refresh in [false, true]) {
        test(
          'rejects unsafe filenames before I/O (refresh: $refresh)',
          () async {
            final outside = File(p.join(root.path, 'outside.pem'))
              ..writeAsStringSync(validPem);
            final invalidNames = [
              '',
              '.',
              '..',
              '../outside.pem',
              'nested/../../outside.pem',
              'nested/key.pem',
              r'..\outside.pem',
              r'nested\key.pem',
              outside.absolute.path,
              r'C:\outside.pem',
              r'C:outside.pem',
              r'\\server\share\key.pem',
              '%2e%2e%2foutside.pem',
              'key.pem\u0000',
              'key.pem\n',
              'key.pem\r',
              'key\t.pem',
              ' key.pem',
              'key.pem ',
              'key.',
              'CON',
              'nul.pem',
              'COM1.pem',
              'a' * 256,
            ];
            for (final name in invalidNames) {
              await expectLater(
                provider(
                  fileName: name,
                ).getPublicKeyPath(forceRefresh: refresh),
                throwsA(isA<RsaPublicKeyPathProviderException>()),
                reason: 'Must reject ${name.codeUnits}',
              );
            }
            expect(cache.listSync(), isEmpty);
            expect(outside.readAsStringSync(), validPem);
            expect(http.callCount, 0);
          },
        );

        for (final exists in [false, true]) {
          test(
            'rejects symlink (target exists: $exists, refresh: $refresh)',
            () async {
              final outside = File(p.join(root.path, 'outside.pem'));
              if (exists) outside.writeAsStringSync(validPem);
              final link = Link(p.join(cache.path, 'rsa_public_key.pem'))
                ..createSync(outside.path);

              await expectLater(
                provider().getPublicKeyPath(forceRefresh: refresh),
                throwsA(isA<RsaPublicKeyPathProviderException>()),
              );

              expect(link.existsSync(), isTrue);
              expect(outside.existsSync(), exists);
              if (exists) expect(outside.readAsStringSync(), validPem);
              expect(http.callCount, 0);
            },
          );
        }
      }

      test('rejects a symlink introduced while loading the key', () async {
        final outside = File(p.join(root.path, 'outside.pem'))
          ..writeAsStringSync('outside must not change');
        Future<void> replaceWithLink() async {
          Link(
            p.join(cache.path, 'rsa_public_key.pem'),
          ).createSync(outside.path);
        }

        assets = _FakeAssetBundle(validPem, beforeLoad: replaceWithLink);
        http = _FakeHttpService(validPem, beforeGet: replaceWithLink);

        await expectLater(
          provider().getPublicKeyPath(forceRefresh: true),
          throwsA(isA<RsaPublicKeyPathProviderException>()),
        );

        expect(outside.readAsStringSync(), 'outside must not change');
      });

      test('supports a custom filename, reuse, and forced refresh', () async {
        const name = 'Bank_RSA-2026.v2.pem';
        final keyProvider = provider(fileName: name);
        final path = await keyProvider.getPublicKeyPath();
        expect(path, p.join(cache.absolute.path, name));
        expect(File(path).readAsStringSync(), validPem);
        File(path).writeAsStringSync(
          validPem.replaceFirst('BQADSwAwSAJB', 'BQADSwAwSAJC'),
        );

        expect(await keyProvider.getPublicKeyPath(), path);
        expect(File(path).readAsStringSync(), contains('SAJC'));
        expect(await keyProvider.getPublicKeyPath(forceRefresh: true), path);
        expect(File(path).readAsStringSync(), validPem);
        if (source == 'remote') expect(http.callCount, 2);
      });

      test('creates a missing trusted cache directory', () async {
        cache = Directory(p.join(cache.path, 'new', 'keys'));
        final path = await provider().getPublicKeyPath();
        expect(File(path).readAsStringSync(), validPem);
        expect(p.isWithin(cache.absolute.path, path), isTrue);
      });
    });
  }

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
