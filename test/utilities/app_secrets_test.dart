import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppSecretCodec Tests', () {
    test('encode and decode cycle', () {
      const original = 'test_api_secret_12345';
      final encoded = AppSecretCodec.encode(original);
      expect(encoded, isNotEmpty);
      expect(encoded.length % 3, equals(0));

      final decoded = AppSecretCodec.decode(encoded);
      expect(decoded, equals(original));
    });

    test('decode empty string returns empty string', () {
      expect(AppSecretCodec.decode(''), equals(''));
    });

    test('decode throws FormatException for non-multiple of 3', () {
      expect(() => AppSecretCodec.decode('1234'), throwsFormatException);
    });

    test('resolve returns decoded masked when present, plain otherwise', () {
      final masked = AppSecretCodec.encode('masked_value');
      expect(
        AppSecretCodec.resolve(masked: masked, plain: 'plain_value'),
        equals('masked_value'),
      );
      expect(
        AppSecretCodec.resolve(masked: '', plain: 'plain_value'),
        equals('plain_value'),
      );
    });

    test('redact keeps trailing visible chars and obscures rest', () {
      expect(AppSecretCodec.redact(''), equals(''));
      expect(AppSecretCodec.redact('123', visible: 4), equals('***'));
      expect(AppSecretCodec.redact('12345678', visible: 4), equals('****5678'));
    });
  });

  group('AppStringMaskUtils Tests', () {
    test('maskPhoneNumber normalizes and masks Nigerian phone numbers', () {
      expect(
        AppStringMaskUtils.maskPhoneNumber('08100115314'),
        equals('0810*****14'),
      );
      expect(
        AppStringMaskUtils.maskPhoneNumber('+2348100115314'),
        equals('0810*****14'),
      );
      expect(
        AppStringMaskUtils.maskPhoneNumber('2348100115314'),
        equals('0810*****14'),
      );
      expect(AppStringMaskUtils.maskPhoneNumber(null), equals(''));
      expect(AppStringMaskUtils.maskPhoneNumber(''), equals(''));
    });

    test('maskOtpPhone shorthand', () {
      expect(
        AppStringMaskUtils.maskOtpPhone('+2348100115314'),
        equals('0810*****14'),
      );
      expect(AppStringMaskUtils.maskOtpPhone(null), equals(''));
    });

    test('mask handles arbitrary strings safely and gracefully scales', () {
      expect(AppStringMaskUtils.mask(null), equals(''));
      expect(AppStringMaskUtils.mask(''), equals(''));
      expect(AppStringMaskUtils.mask('a'), equals('*'));
      expect(AppStringMaskUtils.mask('ab'), equals('**'));
      expect(
        AppStringMaskUtils.mask(
          'SecretToken12345',
          startVisible: 3,
          endVisible: 3,
        ),
        equals('Sec**********345'),
      );
      expect(
        AppStringMaskUtils.mask('Short', startVisible: 4, endVisible: 4),
        isNot(equals('Short')),
      );
    });

    test('maskEmail obscures username while retaining domain', () {
      expect(
        AppStringMaskUtils.maskEmail('user@example.com'),
        equals('u**r@example.com'),
      );
      expect(
        AppStringMaskUtils.maskEmail('john.doe@example.com'),
        equals('j******e@example.com'),
      );
      expect(AppStringMaskUtils.maskEmail('a@b.com'), equals('*@b.com'));
      expect(AppStringMaskUtils.maskEmail(null), equals(''));
      expect(AppStringMaskUtils.maskEmail(''), equals(''));
      expect(AppStringMaskUtils.maskEmail('no-at-sign'), equals('n********n'));
    });

    test('maskAccountNumber obscures account number', () {
      expect(
        AppStringMaskUtils.maskAccountNumber('0123456789'),
        equals('012****789'),
      );
      expect(AppStringMaskUtils.maskAccountNumber(null), equals(''));
    });

    test('maskBvn obscures BVN / NIN', () {
      expect(AppStringMaskUtils.maskBvn('22233344455'), equals('222******55'));
      expect(AppStringMaskUtils.maskBvn(null), equals(''));
    });

    test('maskCardPan strips spaces and obscures PAN', () {
      expect(
        AppStringMaskUtils.maskCardPan('1234 5678 1234 5678'),
        equals('123456******5678'),
      );
      expect(
        AppStringMaskUtils.maskCardPan('1234567812345678'),
        equals('123456******5678'),
      );
      expect(AppStringMaskUtils.maskCardPan(null), equals(''));
    });
  });

  group('StringMaskExtension & NullableStringMaskExtension Tests', () {
    test('non-nullable string getters and methods', () {
      const phone = '08100115314';
      expect(phone.asMaskedOtpPhone, equals('0810*****14'));
      expect(phone.maskedOtpPhone, equals('0810*****14'));
      expect(phone.asMaskedPhone, equals('0810*****14'));
      expect(phone.maskedPhone, equals('0810*****14'));
      expect(phone.maskPhoneNumber(), equals('0810*****14'));
      expect(phone.maskOtpPhone(), equals('0810*****14'));

      const email = 'john.doe@example.com';
      expect(email.asMaskedEmail, equals('j******e@example.com'));
      expect(email.maskedEmail, equals('j******e@example.com'));
      expect(email.maskEmail(), equals('j******e@example.com'));

      const acct = '0123456789';
      expect(acct.asMaskedAccountNumber, equals('012****789'));
      expect(acct.maskedAccountNumber, equals('012****789'));
      expect(acct.maskAccountNumber(), equals('012****789'));

      const bvn = '22233344455';
      expect(bvn.asMaskedBvn, equals('222******55'));
      expect(bvn.maskedBvn, equals('222******55'));
      expect(bvn.asMaskedNin, equals('222******55'));
      expect(bvn.maskedNin, equals('222******55'));
      expect(bvn.maskBvn(), equals('222******55'));
      expect(bvn.maskNin(), equals('222******55'));

      const card = '1234567812345678';
      expect(card.asMaskedCard, equals('123456******5678'));
      expect(card.asMaskedCardPan, equals('123456******5678'));
      expect(card.maskedCard, equals('123456******5678'));
      expect(card.maskedCardPan, equals('123456******5678'));
      expect(card.maskCard(), equals('123456******5678'));
      expect(card.maskCardPan(), equals('123456******5678'));

      const secret = 'my_secret_token';
      expect(secret.asRedactedSecret, equals('***********oken'));
      expect(secret.redactSecret(visible: 2), equals('*************en'));
      final encoded = secret.asSecretEncoded;
      expect(encoded.asSecretDecoded, equals(secret));
    });

    test('nullable string getters and methods', () {
      const String? nullString = null;
      expect(nullString.asMaskedOtpPhone, equals(''));
      expect(nullString.maskedPhoneOtp, equals(''));
      expect(nullString.maskedOtpPhone, equals(''));
      expect(nullString.asMaskedPhone, equals(''));
      expect(nullString.maskedPhone, equals(''));
      expect(nullString.asMaskedEmail, equals(''));
      expect(nullString.maskedEmail, equals(''));
      expect(nullString.asMaskedAccountNumber, equals(''));
      expect(nullString.maskedAccountNumber, equals(''));
      expect(nullString.asMaskedBvn, equals(''));
      expect(nullString.maskedBvn, equals(''));
      expect(nullString.asMaskedNin, equals(''));
      expect(nullString.maskedNin, equals(''));
      expect(nullString.asMaskedCard, equals(''));
      expect(nullString.asMaskedCardPan, equals(''));
      expect(nullString.maskedCard, equals(''));
      expect(nullString.maskedCardPan, equals(''));
      expect(nullString.asRedactedSecret, equals(''));
      expect(nullString.asSecretDecoded, equals(''));
      expect(nullString.mask(), equals(''));
      expect(nullString.maskWith(), equals(''));
      expect(nullString.maskCustom(), equals(''));
      expect(nullString.maskPhoneNumber(), equals(''));
      expect(nullString.maskOtpPhone(), equals(''));
      expect(nullString.maskEmail(), equals(''));
      expect(nullString.maskAccountNumber(), equals(''));
      expect(nullString.maskBvn(), equals(''));
      expect(nullString.maskNin(), equals(''));
      expect(nullString.maskCardPan(), equals(''));
      expect(nullString.maskCard(), equals(''));
      expect(nullString.redactSecret(), equals(''));

      final nonNullString = '08100115314' as String?;
      expect(nonNullString.asMaskedOtpPhone, equals('0810*****14'));
      expect(nonNullString.maskedPhoneOtp, equals('0810*****14'));
      expect(nonNullString.maskedOtpPhone, equals('0810*****14'));
      expect(nonNullString.asMaskedPhone, equals('0810*****14'));
      expect(nonNullString.maskedPhone, equals('0810*****14'));
    });
  });
}
