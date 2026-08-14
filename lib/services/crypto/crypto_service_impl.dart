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

  /// Indicates whether [aesKey] is Base64 encoded.
  final bool isBase64Key;

  /// The default packaging strategy for payload formatting.
  @override
  final AppCryptoPayloadStrategy defaultStrategy;

  /// Optional file path to the RSA public key for asymmetric encryption.
  @Deprecated('Use rsaPublicKeyPathProvider instead.')
  final String? rsaPublicKeyPath;

  /// Optional provider that resolves the RSA public-key PEM file path.
  final RsaPublicKeyPathProvider? rsaPublicKeyPathProvider;

  /// If [true], the [appTag] will be used as Associated Authenticated Data (AAD) in AES-GCM encryption.
  /// This is used to detect tampering with the encrypted data.
  final bool tamperProof;

  /// Internal RSA encrypter instance.
  Encrypter? _rsaCipher;

  /// Internal RSA public key instance.
  RSAPublicKey? _rsaPublicKey;

  /// Internal AES encrypter instance.
  late final Encrypter _aesCipher;

  late final Future<void> _rsaInitFuture;

  /// Initializes the service with [aesKey], [appTag], and an optional [rsaPublicKeyPath].
  AppCryptoServiceImpl({
    required this.aesKey,
    required this.appTag,
    this.rsaPublicKeyPath,
    this.rsaPublicKeyPathProvider,
    required this.tamperProof,
    this.isBase64Key = false,
    this.defaultStrategy = .contiguous,
  }) {
    final key = isBase64Key ? Key.fromBase64(aesKey) : Key.fromUtf8(aesKey);
    _aesCipher = Encrypter(AES(key, mode: .gcm));
    _rsaInitFuture = _initRsaCipher();
  }

  /// Named constructor for Base64 encoded AES key.
  factory AppCryptoServiceImpl.fromBase64Key({
    required String aesKeyB64,
    required String appTag,
    String? rsaPublicKeyPath,
    RsaPublicKeyPathProvider? rsaPublicKeyPathProvider,
    bool tamperProof = true,
    AppCryptoPayloadStrategy defaultStrategy = .contiguous,
  }) {
    return AppCryptoServiceImpl(
      aesKey: aesKeyB64,
      appTag: appTag,
      rsaPublicKeyPath: rsaPublicKeyPath,
      rsaPublicKeyPathProvider: rsaPublicKeyPathProvider,
      tamperProof: tamperProof,
      isBase64Key: true,
      defaultStrategy: defaultStrategy,
    );
  }

  @override
  Future<void> init() => _rsaInitFuture;

  @override
  String encrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    try {
      final iv = IV.fromSecureRandom(12);
      final aad = associatedData ?? _associatedData;
      final cipher = _aesCipher.encrypt(data, iv: iv, associatedData: aad);

      final effectiveStrategy = strategy == .auto ? defaultStrategy : strategy;

      return switch (effectiveStrategy) {
        .colonDelimited =>
          '${_encode(iv.bytes, mode)}:${_encode(cipher.bytes, mode)}',
        _ => _encode(Uint8List.fromList(iv.bytes + cipher.bytes), mode),
      };
    } catch (e, t) {
      AppLogger.severe("Encryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String decrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    try {
      final (iv, cipherBytes) = _extractIvAndCipher(data, mode, strategy);
      final aad = associatedData ?? _associatedData;

      return _aesCipher.decrypt(
        Encrypted(cipherBytes),
        iv: iv,
        associatedData: aad,
      );
    } catch (e, t) {
      AppLogger.severe("Decryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String? tryDecrypt(
    String? data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    if (!data.hasValue) return data;
    try {
      return decrypt(
        data!,
        mode: mode,
        strategy: strategy,
        associatedData: associatedData,
      );
    } catch (_) {
      return data;
    }
  }

  @override
  String? encryptRsa(String data, {AppCryptoMode mode = .base16}) {
    if (_rsaCipher == null) return null;
    try {
      final encrypted = _rsaCipher!.encrypt(data);
      return switch (mode) {
        .base16 => encrypted.base16.upper,
        .base64 => encrypted.base64,
      };
    } catch (e, t) {
      AppLogger.severe("RSA encryption failed: $e", stackTrace: t, error: e);
      return null;
    }
  }

  /// Converts the [appTag] into a [Uint8List] to be used as Associated Data (AAD) for AES-GCM.
  Uint8List? get _associatedData => tamperProof ? appTag.encoded : null;

  /// Extracts the IV and Cipher bytes from [data] based on [mode] and [strategy].
  (IV, Uint8List) _extractIvAndCipher(
    String data,
    AppCryptoMode mode,
    AppCryptoPayloadStrategy strategy,
  ) {
    final trimmed = data.value;
    final AppCryptoPayloadStrategy effectiveStrategy = strategy == .auto
        ? (trimmed.contains(':') ? .colonDelimited : .contiguous)
        : strategy;

    if (!effectiveStrategy.isColonDelimited) {
      final rawBytes = _decode(trimmed, mode);
      if (rawBytes.length < 12) {
        throw const FormatException(
          'Invalid ciphertext length for AES-GCM: minimum 12 bytes required.',
        );
      }
      return (IV(rawBytes.sublist(0, 12)), rawBytes.sublist(12));
    }

    final segments = trimmed.split(':');
    if (segments.length != 2) {
      throw const FormatException('Invalid colon-delimited payload format.');
    }

    final ivBytes = _decodeSegment(segments[0], mode);
    if (ivBytes.length != 12) {
      throw FormatException(
        'Invalid IV length for AES-GCM: expected 12 bytes, got ${ivBytes.length}.',
      );
    }

    final cipherBytes = _decodeSegment(segments[1], mode);
    return (IV(ivBytes), cipherBytes);
  }

  /// Encodes [bytes] to string using the specified [mode].
  static String _encode(Uint8List bytes, AppCryptoMode mode) {
    return switch (mode) {
      .base16 => Encrypted(bytes).base16,
      .base64 => Encrypted(bytes).base64,
    };
  }

  /// Decodes [text] to [Uint8List] using the specified [mode].
  static Uint8List _decode(String text, AppCryptoMode mode) {
    return switch (mode) {
      .base16 => Encrypted.fromBase16(text.value).bytes,
      .base64 => Encrypted.fromBase64(_normalizeBase64(text)).bytes,
    };
  }

  /// Decodes a segment of a colon-delimited payload with auto-format detection and Base64 normalization.
  static Uint8List _decodeSegment(String segment, AppCryptoMode fallbackMode) {
    final trimmed = segment.value;
    final isLikelyBase64 =
        fallbackMode.isBase64 ||
        trimmed.length == 16 ||
        AppRegex.base64IndicatorRegex.hasMatch(trimmed);

    if (isLikelyBase64) {
      try {
        return Encrypted.fromBase64(_normalizeBase64(trimmed)).bytes;
      } catch (_) {}
    }

    try {
      return Encrypted.fromBase16(trimmed).bytes;
    } catch (_) {
      return Encrypted.fromBase64(_normalizeBase64(trimmed)).bytes;
    }
  }

  /// Normalizes a Base64 string by replacing URL-safe characters and padding with `=`.
  static String _normalizeBase64(String value) {
    final normalized = value.value.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder == 0) return normalized;
    return normalized.padRight(normalized.length + (4 - remainder), '=');
  }

  /// Asynchronously initializes the RSA cipher by parsing the public key from [rsaPublicKeyPath].
  Future<void> _initRsaCipher() async {
    try {
      final resolvedPath = await _resolveRsaPublicKeyPath();
      if (!resolvedPath.hasValue) return;

      _rsaPublicKey = await parseKeyFromFile<RSAPublicKey>(resolvedPath!);
      _rsaCipher = Encrypter(RSA(publicKey: _rsaPublicKey));
    } catch (e, t) {
      AppLogger.severe(
        "Failed to initialize RSA cipher: $e",
        stackTrace: t,
        error: e,
      );
    }
  }

  Future<String?> _resolveRsaPublicKeyPath() async {
    if (rsaPublicKeyPathProvider == null) return rsaPublicKeyPath;
    try {
      return await rsaPublicKeyPathProvider!.getPublicKeyPath();
    } catch (e, t) {
      AppLogger.severe(
        "Failed to resolve RSA public key path: $e",
        stackTrace: t,
        error: e,
      );
      return null;
    }
  }
}

