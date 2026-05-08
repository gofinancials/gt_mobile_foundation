import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:pointycastle/pointycastle.dart';

/// {@category Services}
/// The standard implementation of [AppCryptoService] using AES and RSA algorithms.
class AppCryptoServiceImpl implements AppCryptoService {
  /// The symmetric key used for AES encryption.
  final String aesKey;

  /// The initialization vector (IV) used for AES encryption.
  final String aesVector;

  /// Optional file path to the RSA public key for asymmetric encryption.
  final String? rsaPublicKeyPath;

  /// Internal RSA encrypter instance.
  Encrypter? _rsaCipher;

  /// Internal RSA public key instance.
  RSAPublicKey? _rsaPublicKey;

  /// Internal AES encrypter instance.
  late final Encrypter _aesCipher;

  /// Internal IV instance for AES.
  late final IV _iv;

  /// Initializes the service with [aesKey], [aesVector], and an optional [rsaPublicKeyPath].
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
