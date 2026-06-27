import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppCryptoServiceImpl Tests', () {
    const tag = "OneBankProDevMobileApiKey00001";
    const testKey = "01234567890123456789012345678901";
    late AppCryptoServiceImpl cryptoService;

    setUp(() {
      cryptoService = AppCryptoServiceImpl(
        aesKey: testKey,
        appTag: tag,
        tamperProof: true,
      );
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

      test('decryption should fail gracefully when appTag (AAD) is incorrect', () {
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
      });

      group('TamperProof Configurations', () {
        test('decryption succeeds when tamperProof is true on both sides (AAD match)', () {
          final service = AppCryptoServiceImpl(
            aesKey: testKey,
            appTag: tag,
            tamperProof: true,
          );
          const plainText = 'sensitive data';
          final encrypted = service.encrypt(plainText, mode: .base16);
          final decrypted = service.decrypt(encrypted, mode: .base16);

          expect(decrypted, equals(plainText));
        });

        test('decryption succeeds when tamperProof is false on both sides (no AAD)', () {
          final service = AppCryptoServiceImpl(
            aesKey: testKey,
            appTag: tag,
            tamperProof: false,
          );
          const plainText = 'sensitive data';
          final encrypted = service.encrypt(plainText, mode: .base16);
          final decrypted = service.decrypt(encrypted, mode: .base16);

          expect(decrypted, equals(plainText));
        });

        test('decryption fails gracefully when encrypted WITH tamperProof, but decrypted WITHOUT tamperProof', () {
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
        });

        test('decryption fails gracefully when encrypted WITHOUT tamperProof, but decrypted WITH tamperProof', () {
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
        });
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
  });
}
