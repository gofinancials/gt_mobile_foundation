import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:pointycastle/pointycastle.dart';

class AppCryptoServiceImpl implements AppCryptoService {
  final String aesKey;
  final String aesVector;

  final String? rsaPublicKeyPath;

  Encrypter? _rsaCipher;
  RSAPublicKey? _rsaPublicKey;

  late final Encrypter _aesCipher;
  late final IV _iv;

  AppCryptoServiceImpl({
    required this.aesKey,
    required this.aesVector,
    this.rsaPublicKeyPath,
  }) {
    _aesCipher = Encrypter(AES(Key.fromUtf8(aesKey), mode: .cbc));
    _iv = IV.fromUtf8(aesVector);
    _initRsaCipher();
  }

  @override
  String encrypt(String data, {AppCryptoMode mode = .base16}) {
    try {
      final cipherText = _aesCipher.encrypt(data, iv: _iv);
      return switch (mode) {
        AppCryptoMode.base16 => cipherText.base16.toUpperCase(),
        AppCryptoMode.base64 => cipherText.base64,
      };
    } catch (e, t) {
      AppLogger.severe("Encryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String decrypt(String data, {AppCryptoMode mode = .base16}) {
    try {
      return switch (mode) {
        AppCryptoMode.base16 => _aesCipher.decrypt16(data, iv: _iv),
        AppCryptoMode.base64 => _aesCipher.decrypt64(data, iv: _iv),
      };
    } catch (e, t) {
      AppLogger.severe("Dencryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String? encryptRsa(String data, {AppCryptoMode mode = .base16}) {
    try {
      final encrypted = _rsaCipher?.encrypt(data);
      return switch (mode) {
        AppCryptoMode.base16 => encrypted?.base16.toUpperCase(),
        AppCryptoMode.base64 => encrypted?.base64,
      };
    } catch (e, t) {
      AppLogger.severe("RSA encryption failed: $e", stackTrace: t, error: e);
      return null;
    }
  }

  _initRsaCipher() async {
    try {
      if (!rsaPublicKeyPath.hasValue) return;

      if (rsaPublicKeyPath.hasValue) {
        _rsaPublicKey = await parseKeyFromFile(rsaPublicKeyPath!);
      }

      if (_rsaPublicKey == null) return;

      _rsaCipher = Encrypter(RSA(publicKey: _rsaPublicKey!));
    } catch (e, t) {
      AppLogger.severe(
        "Failed to initialize RSA cipher: $e",
        stackTrace: t,
        error: e,
      );
    }
  }
}
