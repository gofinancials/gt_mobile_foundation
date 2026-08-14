import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';



class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this.pem);

  final String pem;

  @override
  Future<ByteData> load(String key) async {
    return ByteData.view(Uint8List.fromList(pem.codeUnits).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => pem;
}

void main() {
  group('AppCryptoServiceImpl Tests', () {
    const tag = "OneBankProDevMobileApiKey00001";
    const testKey = "01234567890123456789012345678901";
    const rsaPem =
        '-----BEGIN PUBLIC KEY-----\n'
        'MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALdUOQ9I5nqz4c7L0zq4fO4Xb4K6xK1S\n'
        'xjQk1a3k8uQ4Qp8w9q2P8sJ6g4p1t8YxQGm5m2zG3x0CAwEAAQ==\n'
        '-----END PUBLIC KEY-----\n';
    late AppCryptoServiceImpl cryptoService;
    late Directory rsaTempDir;
    late LocalRsaPublicKeyPathProvider rsaPublicKeyPathProvider;

    setUp(() async {
      rsaTempDir = Directory.systemTemp.createTempSync('crypto_rsa_');
      rsaPublicKeyPathProvider = LocalRsaPublicKeyPathProvider(
        assetBundle: _FakeAssetBundle(rsaPem),
        assetPath: 'assets/rsa_public_key.pem',
        directory: rsaTempDir,
      );
      cryptoService = AppCryptoServiceImpl(
        aesKey: testKey,
        appTag: tag,
        rsaPublicKeyPathProvider: rsaPublicKeyPathProvider,
        tamperProof: true,
      );
      await cryptoService.init();
    });

    tearDown(() {
      if (rsaTempDir.existsSync()) {
        rsaTempDir.deleteSync(recursive: true);
      }
    });

    test('should successfully encrypt and decrypt data using Base16 mode', () {
      const plainText = 'hello world';
      final encrypted = cryptoService.encrypt(plainText, mode: .base16);
      AppLogger.info('--- Base16 Test ---');
      AppLogger.info('Input: $plainText');
      AppLogger.info('Encrypted: $encrypted');

      expect(encrypted, isNot(plainText));
      expect(encrypted, isNotEmpty);

      final decrypted = cryptoService.decrypt(encrypted, mode: .base16);
      AppLogger.info('Decrypted: $decrypted');
      expect(decrypted, equals(plainText));
    });

    test('should successfully encrypt and decrypt data using Base64 mode', () {
      const plainText = 'hello world';
      final encrypted = cryptoService.encrypt(plainText, mode: .base64);
      AppLogger.info('--- Base64 Test ---');
      AppLogger.info('Input: $plainText');
      AppLogger.info('Encrypted: $encrypted');

      expect(encrypted, isNot(plainText));
      expect(encrypted, isNotEmpty);

      final decrypted = cryptoService.decrypt(encrypted, mode: .base64);
      AppLogger.info('Decrypted: $decrypted');
      expect(decrypted, equals(plainText));
    });

    test(
      'encryption should produce different ciphertexts for the same plaintext due to random IV',
      () {
        const plainText = 'same text';
        final encrypted1 = cryptoService.encrypt(plainText);
        final encrypted2 = cryptoService.encrypt(plainText);

        expect(encrypted1, isNot(equals(encrypted2)));

        // Both should still decrypt to the same plaintext
        expect(cryptoService.decrypt(encrypted1), equals(plainText));
        expect(cryptoService.decrypt(encrypted2), equals(plainText));
      },
    );

    group('Edge Cases', () {
      test(
        'decryption should fail gracefully and return original text when ciphertext is too short',
        () {
          // "short" base16 encoded is 73686f7274, less than 12 bytes
          const invalidCiphertext = '73686f7274';
          final decrypted = cryptoService.decrypt(
            invalidCiphertext,
            mode: .base16,
          );

          // As per current implementation, on catch it returns original data
          expect(decrypted, equals(invalidCiphertext));
        },
      );

      test(
        'decryption should fail gracefully and return original text when data is invalid base16',
        () {
          const invalidCiphertext = 'Not a valid base16 string!!!';
          final decrypted = cryptoService.decrypt(
            invalidCiphertext,
            mode: .base16,
          );

          expect(decrypted, equals(invalidCiphertext));
        },
      );

      test(
        'decryption should fail gracefully and return original text when data is tampered with',
        () {
          const plainText = 'sensitive data';
          final encrypted = cryptoService.encrypt(plainText, mode: .base16);

          // Tamper with the ciphertext by changing the last character
          final tampered =
              encrypted.substring(0, encrypted.length - 1) +
              (encrypted.endsWith('A') ? 'B' : 'A');

          final decrypted = cryptoService.decrypt(tampered, mode: .base16);
          expect(decrypted, equals(tampered));
        },
      );

      test('should handle empty string correctly', () {
        const plainText = '';
        final encrypted = cryptoService.encrypt(plainText);
        final decrypted = cryptoService.decrypt(encrypted);

        expect(decrypted, equals(plainText));
      });

      test(
        'decryption should fail gracefully when appTag (AAD) is incorrect',
        () {
          const plainText = 'sensitive data';
          final encrypted = cryptoService.encrypt(plainText, mode: .base16);

          // Create a new crypto service with a wrong appTag
          final wrongTagService = AppCryptoServiceImpl(
            aesKey: testKey,
            appTag: 'wrong_tag_0000000000000000',
            tamperProof: true,
          );

          final decrypted = wrongTagService.decrypt(encrypted, mode: .base16);

          // It should return the original ciphertext string on failure
          expect(decrypted, equals(encrypted));
        },
      );

      group('TamperProof Configurations', () {
        test(
          'decryption succeeds when tamperProof is true on both sides (AAD match)',
          () {
            final service = AppCryptoServiceImpl(
              aesKey: testKey,
              appTag: tag,
              tamperProof: true,
            );
            const plainText = 'sensitive data';
            final encrypted = service.encrypt(plainText, mode: .base16);
            final decrypted = service.decrypt(encrypted, mode: .base16);

            expect(decrypted, equals(plainText));
          },
        );

        test(
          'decryption succeeds when tamperProof is false on both sides (no AAD)',
          () {
            final service = AppCryptoServiceImpl(
              aesKey: testKey,
              appTag: tag,
              tamperProof: false,
            );
            const plainText = 'sensitive data';
            final encrypted = service.encrypt(plainText, mode: .base16);
            final decrypted = service.decrypt(encrypted, mode: .base16);

            expect(decrypted, equals(plainText));
          },
        );

        test(
          'decryption fails gracefully when encrypted WITH tamperProof, but decrypted WITHOUT tamperProof',
          () {
            final secureService = AppCryptoServiceImpl(
              aesKey: testKey,
              appTag: tag,
              tamperProof: true,
            );
            final insecureService = AppCryptoServiceImpl(
              aesKey: testKey,
              appTag: tag,
              tamperProof: false,
            );
            const plainText = 'sensitive data';
            final encrypted = secureService.encrypt(plainText, mode: .base16);

            // Insecure service tries to decrypt without AAD
            final decrypted = insecureService.decrypt(encrypted, mode: .base16);

            expect(decrypted, equals(encrypted)); // Fails gracefully
          },
        );

        test(
          'decryption fails gracefully when encrypted WITHOUT tamperProof, but decrypted WITH tamperProof',
          () {
            final insecureService = AppCryptoServiceImpl(
              aesKey: testKey,
              appTag: tag,
              tamperProof: false,
            );
            final secureService = AppCryptoServiceImpl(
              aesKey: testKey,
              appTag: tag,
              tamperProof: true,
            );
            const plainText = 'sensitive data';
            final encrypted = insecureService.encrypt(plainText, mode: .base16);

            // Secure service tries to decrypt with AAD
            final decrypted = secureService.decrypt(encrypted, mode: .base16);

            expect(decrypted, equals(encrypted)); // Fails gracefully
          },
        );
      });
    });

    group('Interceptor / JSON Payloads', () {
      test('should encrypt and decrypt a typical JSON map payload', () async {
        const map = {
          "status": "success",
          "message": "Operation successful",
          "data": {"id": 1001, "name": "John Doe"},
        };
        final jsonPayload = await AppHelpers.encodeJson(map);

        final encrypted = cryptoService.encrypt(jsonPayload, mode: .base16);
        AppLogger.info('--- JSON Map Test ---');
        AppLogger.info('Input Payload: $jsonPayload');
        AppLogger.info('Encrypted: $encrypted');

        expect(encrypted, isNot(jsonPayload));

        final decrypted = cryptoService.decrypt(encrypted, mode: .base16);
        AppLogger.info('Decrypted Payload: $decrypted');

        expect(decrypted, equals(jsonPayload));
      });

      test(
        'should encrypt and decrypt a typical JSON map payload with base64',
        () async {
          const map = {
            "status": "success",
            "message": "Operation successful",
            "data": {"id": 1001, "name": "John Doe"},
          };
          final jsonPayload = await AppHelpers.encodeJson(map);

          final encrypted = cryptoService.encrypt(jsonPayload, mode: .base64);
          AppLogger.info('--- JSON Map Test ---');
          AppLogger.info('Input Payload: $jsonPayload');
          AppLogger.info('Encrypted: $encrypted');

          expect(encrypted, isNot(jsonPayload));

          final decrypted = cryptoService.decrypt(encrypted, mode: .base64);
          AppLogger.info('Decrypted Payload: $decrypted');

          expect(decrypted, equals(jsonPayload));
        },
      );

      test('should encrypt and decrypt a JSON list payload', () async {
        const list = [
          {
            "status": "success",
            "message": "Operation successful",
            "data": {"id": 1001, "name": "John Doe"},
          },
        ];
        final jsonPayload = await AppHelpers.encodeJson(list);

        final encrypted = cryptoService.encrypt(jsonPayload, mode: .base16);
        AppLogger.info('--- JSON List Test ---');
        AppLogger.info('Input Payload: $jsonPayload');
        AppLogger.info('Encrypted: $encrypted');

        expect(encrypted, isNot(jsonPayload));

        final decrypted = cryptoService.decrypt(encrypted, mode: .base16);
        AppLogger.info('Decrypted Payload: $decrypted');

        expect(decrypted, equals(jsonPayload));
      });

      test('should use a local RSA public key provider path', () async {
        final pemPath = await rsaPublicKeyPathProvider.getPublicKeyPath();

        expect(File(pemPath).existsSync(), isTrue);
        expect(pemPath, endsWith('rsa_public_key.pem'));
      });

      test(
        'should encrypt and decrypt a JSON list payload with base64',
        () async {
          const list = [
            {
              "status": "success",
              "message": "Operation successful",
              "data": {"id": 1001, "name": "John Doe"},
            },
          ];
          final jsonPayload = await AppHelpers.encodeJson(list);

          final encrypted = cryptoService.encrypt(jsonPayload, mode: .base64);
          AppLogger.info('--- JSON List Test ---');
          AppLogger.info('Input Payload: $jsonPayload');
          AppLogger.info('Encrypted: $encrypted');

          expect(encrypted, isNot(jsonPayload));

          final decrypted = cryptoService.decrypt(encrypted, mode: .base64);
          AppLogger.info('Decrypted Payload: $decrypted');

          expect(decrypted, equals(jsonPayload));
        },
      );
    });

    group('Colon-Delimited Strategy Tests', () {
      test(
        'should encrypt and decrypt in colon-delimited format with Base64',
        () {
          const plainText = '{"data":"gcm-backend-payload"}';
          final encrypted = cryptoService.encrypt(
            plainText,
            mode: .base64,
            strategy: .colonDelimited,
          );

          expect(encrypted, contains(':'));
          final segments = encrypted.split(':');
          expect(segments.length, equals(2));
          // IV in Base64 (12 bytes) is 16 chars
          expect(segments[0].length, equals(16));
          expect(segments[1], isNotEmpty);

          final decrypted = cryptoService.decrypt(
            encrypted,
            mode: .base64,
            strategy: .colonDelimited,
          );
          expect(decrypted, equals(plainText));
        },
      );

      test(
        'should encrypt and decrypt in colon-delimited format with Base16',
        () {
          const plainText = 'passcode-1234';
          final encrypted = cryptoService.encrypt(
            plainText,
            mode: .base16,
            strategy: .colonDelimited,
          );

          expect(encrypted, contains(':'));
          final segments = encrypted.split(':');
          expect(segments.length, equals(2));
          // IV in Base16 (12 bytes) is 24 hex chars
          expect(segments[0].length, equals(24));
          expect(segments[1], isNotEmpty);

          final decrypted = cryptoService.decrypt(
            encrypted,
            mode: .base16,
            strategy: .colonDelimited,
          );
          expect(decrypted, equals(plainText));
        },
      );

      test('should auto-detect and decrypt colon-delimited Base64 payload', () {
        const plainText = 'auto-detect me!';
        final encrypted = cryptoService.encrypt(
          plainText,
          mode: .base64,
          strategy: .colonDelimited,
        );

        // Decrypt with default arguments (which defaults strategy to .auto and mode to .base16)
        final decrypted = cryptoService.decrypt(encrypted);
        expect(decrypted, equals(plainText));
      });

      test('should auto-detect and decrypt colon-delimited Base16 payload', () {
        const plainText = 'hex-auto-detect';
        final encrypted = cryptoService.encrypt(
          plainText,
          mode: .base16,
          strategy: .colonDelimited,
        );

        final decrypted = cryptoService.decrypt(
          encrypted,
          mode: .base16,
          strategy: .auto,
        );
        expect(decrypted, equals(plainText));
      });

      test(
        'should normalize URL-safe Base64 characters and missing padding',
        () {
          const plainText = 'url-safe-test';
          final encrypted = cryptoService.encrypt(
            plainText,
            mode: .base64,
            strategy: .colonDelimited,
          );

          // Convert standard base64 to url-safe base64 and strip '=' padding
          final urlSafe = encrypted
              .replaceAll('+', '-')
              .replaceAll('/', '_')
              .replaceAll('=', '');

          final decrypted = cryptoService.decrypt(
            urlSafe,
            mode: .base64,
            strategy: .colonDelimited,
          );
          expect(decrypted, equals(plainText));
        },
      );
    });

    group('Base64 Key Support & tryDecrypt', () {
      const backendKeyB64 = '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=';

      test('should work with AppCryptoServiceImpl.fromBase64Key factory', () {
        final b64Service = AppCryptoServiceImpl.fromBase64Key(
          aesKeyB64: backendKeyB64,
          appTag: tag,
          tamperProof: false,
          defaultStrategy: .colonDelimited,
        );

        const plainText = '{"auth":"token-12345"}';
        final encrypted = b64Service.encrypt(plainText, mode: .base64);

        expect(encrypted, contains(':'));
        final decrypted = b64Service.decrypt(encrypted, mode: .base64);
        expect(decrypted, equals(plainText));
      });

      test('tryDecrypt returns plaintext on valid encrypted data', () {
        const plainText = 'hello tryDecrypt';
        final encrypted = cryptoService.encrypt(plainText, mode: .base16);

        final decrypted = cryptoService.tryDecrypt(encrypted, mode: .base16);
        expect(decrypted, equals(plainText));
      });

      test('tryDecrypt returns original value on invalid data or null', () {
        expect(cryptoService.tryDecrypt(null), isNull);
        expect(cryptoService.tryDecrypt(''), equals(''));
        expect(
          cryptoService.tryDecrypt('invalid:malformed:format'),
          equals('invalid:malformed:format'),
        );
        expect(
          cryptoService.tryDecrypt('not-encrypted-string'),
          equals('not-encrypted-string'),
        );
      });

      test('supports custom associatedData per call', () {
        final customAad = Uint8List.fromList('custom-auth-context'.codeUnits);
        const plainText = 'authenticated-data';

        final encrypted = cryptoService.encrypt(
          plainText,
          mode: .base64,
          strategy: .colonDelimited,
          associatedData: customAad,
        );

        // Decrypt with matching AAD succeeds
        final decrypted = cryptoService.decrypt(
          encrypted,
          mode: .base64,
          strategy: .colonDelimited,
          associatedData: customAad,
        );
        expect(decrypted, equals(plainText));

        // Decrypt with wrong AAD fails gracefully (returns original string)
        final wrongAad = Uint8List.fromList('wrong-context'.codeUnits);
        final failedDecrypted = cryptoService.decrypt(
          encrypted,
          mode: .base64,
          strategy: .colonDelimited,
          associatedData: wrongAad,
        );
        expect(failedDecrypted, equals(encrypted));
      });
    });

    group('Interceptor Tests with Colon-Delimited Strategy', () {
      test('EncryptInterceptor encrypts body using colon-delimited Base64', () async {
        final interceptor = EncryptInterceptor(
          cryptoService,
          mode: .base64,
          strategy: .colonDelimited,
        );

        final options = RequestOptions(
          path: '/test',
          data: {"amount": 5000, "currency": "NGN"},
        );

        final reqCompleter = Completer<RequestOptions>();
        final handler = _TestRequestInterceptorHandler(
          onNext: (opt) => reqCompleter.complete(opt),
        );

        interceptor.onRequest(options, handler);
        final nextOptions = await reqCompleter.future;

        expect(nextOptions.data, isA<Map<String, dynamic>>());
        final encryptedData = nextOptions.data['data'] as String;
        expect(encryptedData, contains(':'));

        // Decrypt with DecryptInterceptor
        final decInterceptor = DecryptInterceptor(
          cryptoService,
          mode: .base64,
          strategy: .auto,
        );

        final resCompleter = Completer<Response>();
        final resHandler = _TestResponseInterceptorHandler(
          onNext: (res) => resCompleter.complete(res),
        );

        final response = Response(
          requestOptions: nextOptions,
          data: {"data": encryptedData},
        );

        decInterceptor.onResponse(response, resHandler);
        final nextResponse = await resCompleter.future;

        expect(nextResponse.data, isA<Map<String, dynamic>>());
        expect(nextResponse.data['amount'], equals(5000));
        expect(nextResponse.data['currency'], equals('NGN'));
      });
    });
  });
}

class _TestRequestInterceptorHandler extends RequestInterceptorHandler {
  _TestRequestInterceptorHandler({required this.onNext});

  final void Function(RequestOptions) onNext;

  @override
  void next(RequestOptions requestOptions) {
    onNext(requestOptions);
  }
}

class _TestResponseInterceptorHandler extends ResponseInterceptorHandler {
  _TestResponseInterceptorHandler({required this.onNext});

  final void Function(Response) onNext;

  @override
  void next(Response response) {
    onNext(response);
  }
}



