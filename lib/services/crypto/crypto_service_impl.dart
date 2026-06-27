import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:pointycastle/pointycastle.dart';

/// {@category Services}
/// The standard implementation of [AppCryptoService] using AES and RSA algorithms.
class AppCryptoServiceImpl implements AppCryptoService {
  /// The application tag used as Associated Authenticated Data (AAD) in AES-GCM encryption.
  @override
  final String appTag;

  /// The symmetric key used for AES encryption.
  final String aesKey;

  /// Optional file path to the RSA public key for asymmetric encryption.
  final String? rsaPublicKeyPath;

  /// If [true], the [appTag] will be used as Associated Authenticated Data (AAD) in AES-GCM encryption.
  /// This is used to detect tampering with the encrypted data.
  final bool tamperProof;

  /// Internal RSA encrypter instance.
  late final Encrypter? _rsaCipher;

  /// Internal RSA public key instance.
  late final RSAPublicKey? _rsaPublicKey;

  /// Internal AES encrypter instance.
  late final Encrypter _aesCipher;

  /// Initializes the service with [aesKey], [appTag], and an optional [rsaPublicKeyPath].
  AppCryptoServiceImpl({
    required this.aesKey,
    required this.appTag,
    this.rsaPublicKeyPath,
    required this.tamperProof,
  }) {
    _aesCipher = Encrypter(AES(Key.fromUtf8(aesKey), mode: .gcm));
    _initRsaCipher();
  }

  @override
  String encrypt(String data, {AppCryptoMode mode = .base16}) {
    try {
      final iv = IV.fromSecureRandom(12);
      final cipher = _aesCipher.encrypt(
        data,
        iv: iv,
        associatedData: _associatedData,
      );
      final resolvedCipher = _resolveCipherBytes(cipher.bytes, iv);

      return switch (mode) {
        .base16 => resolvedCipher.base16,
        .base64 => resolvedCipher.base64,
      };
    } catch (e, t) {
      AppLogger.severe("Encryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String decrypt(String data, {AppCryptoMode mode = .base16}) {
    try {
      Uint8List cipherBytes = switch (mode) {
        .base16 => Encrypted.fromBase16(data).bytes,
        .base64 => Encrypted.fromBase64(data).bytes,
      };

      if (cipherBytes.length < 12) {
        throw Exception("Invalid ciphertext length for AES-GCM");
      }

      final iv = IV(cipherBytes.sublist(0, 12));
      cipherBytes = cipherBytes.sublist(12);

      return _aesCipher.decrypt(
        Encrypted(cipherBytes),
        iv: iv,
        associatedData: _associatedData,
      );
    } catch (e, t) {
      AppLogger.severe("Decryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String? encryptRsa(String data, {AppCryptoMode mode = .base16}) {
    try {
      final encrypted = _rsaCipher?.encrypt(data);
      return switch (mode) {
        .base16 => encrypted?.base16.upper,
        .base64 => encrypted?.base64,
      };
    } catch (e, t) {
      AppLogger.severe("RSA encryption failed: $e", stackTrace: t, error: e);
      return null;
    }
  }

  /// Converts the [appTag] into a [Uint8List] to be used as Associated Data (AAD) for AES-GCM.
  Uint8List? get _associatedData {
    if (!tamperProof) return null;
    return Uint8List.fromList(appTag.codeUnits);
  }

  /// Resolves the ciphertext bytes by optionally prepending the initialization vector (IV).
  ///
  /// If an [iv] is provided, it is prepended to the ciphertext [bytes] so it can be extracted during decryption.
  Encrypted _resolveCipherBytes(Uint8List bytes, IV? iv) {
    if (iv == null) return Encrypted(bytes);

    return Encrypted(Uint8List.fromList(iv.bytes + bytes));
  }

  /// Asynchronously initializes the RSA cipher by parsing the public key from [rsaPublicKeyPath].
  _initRsaCipher() async {
    try {
      if (!rsaPublicKeyPath.hasValue) return;

      if (rsaPublicKeyPath.hasValue) {
        _rsaPublicKey = await parseKeyFromFile(rsaPublicKeyPath!);
      }

      if (_rsaPublicKey == null) return;

      _rsaCipher = Encrypter(RSA(publicKey: _rsaPublicKey));
    } catch (e, t) {
      AppLogger.severe(
        "Failed to initialize RSA cipher: $e",
        stackTrace: t,
        error: e,
      );
    }
  }
}
