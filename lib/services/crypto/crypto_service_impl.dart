import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart'
    show Mac, SecretBox, SecretKeyData;
import 'package:cryptography/dart.dart' show DartAesGcm;
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:pointycastle/pointycastle.dart' show RSAPublicKey;

/// {@category Services}
/// The standard implementation of [AppCryptoService] using AES and RSA algorithms.
///
/// AES keys are supplied through configuration; this service does not derive
/// cryptographic material from [randomNumString] or [randomInt]. Each encryption
/// generates a 12-byte AES-GCM IV with [IV.fromSecureRandom]. These crypto
/// operations are separate from the non-cryptographic numeric helpers.
///
/// AES-GCM runs on `package:cryptography`'s Dart implementation, which is
/// several times faster than pointycastle's and writes the same bytes: the
/// IV, then the ciphertext, then the 16-byte tag. RSA stays on pointycastle.
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

  /// Internal AES-GCM cipher and key.
  late final _AesGcm _aes;

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
    _aes = _AesGcm(key.bytes);
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
    final aad = associatedData ?? _associatedData;
    return _aes.seal(data, aad, mode, _sealingStrategy(strategy));
  }

  /// [encrypt], run on a background isolate.
  ///
  /// AES-GCM in Dart does not yield, so sealing a body of a few megabytes,
  /// such as a document upload, would hold the UI isolate until it finished.
  /// The isolate is sent the key and [data], never this service.
  Future<String> encryptInBackground(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    final aad = associatedData ?? _associatedData;
    final packaging = _sealingStrategy(strategy);
    return _sealInBackground(_aes, data, aad, mode, packaging);
  }

  @override
  String decrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    final aad = associatedData ?? _associatedData;
    return _aes.open(data, aad, mode, strategy);
  }

  /// [decrypt], run on a background isolate, for the same reason as
  /// [encryptInBackground].
  Future<String> decryptInBackground(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  }) {
    final aad = associatedData ?? _associatedData;
    return _openInBackground(_aes, data, aad, mode, strategy);
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

  /// The packaging [encrypt] writes for [strategy].
  AppCryptoPayloadStrategy _sealingStrategy(AppCryptoPayloadStrategy strategy) {
    return strategy == .auto ? defaultStrategy : strategy;
  }

  /// Seals [data] with [aes] on a new isolate.
  ///
  /// Static, so the closure captures only its arguments and not the service,
  /// whose RSA provider and init future need not be sendable.
  static Future<String> _sealInBackground(
    _AesGcm aes,
    String data,
    Uint8List? aad,
    AppCryptoMode mode,
    AppCryptoPayloadStrategy strategy,
  ) {
    return Isolate.run(() => aes.seal(data, aad, mode, strategy));
  }

  /// Opens [data] with [aes] on a new isolate. See [_sealInBackground].
  static Future<String> _openInBackground(
    _AesGcm aes,
    String data,
    Uint8List? aad,
    AppCryptoMode mode,
    AppCryptoPayloadStrategy strategy,
  ) {
    return Isolate.run(() => aes.open(data, aad, mode, strategy));
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

/// The AES-GCM key and cipher, and the gateway's packaging around them.
///
/// It holds plain values only, so it can be sent to a background isolate.
class _AesGcm {
  _AesGcm(List<int> keyBytes)
    : _key = SecretKeyData(keyBytes),
      _cipher = DartAesGcm(secretKeyLength: _cipherKeyLength(keyBytes.length));

  final SecretKeyData _key;
  final DartAesGcm _cipher;

  /// Length in bytes of the IV the gateway expects.
  static const _ivLength = 12;

  /// Length in bytes of the GCM authentication tag.
  static const _tagLength = 16;

  /// The key length the cipher is built for.
  ///
  /// AES takes 16, 24 or 32 byte keys. Any other length gets the 32-byte
  /// cipher, which then refuses the key on every call rather than running
  /// AES with a schedule built for another size.
  static int _cipherKeyLength(int length) {
    final isAesKeyLength = const {16, 24, 32}.contains(length);
    return isAesKeyLength ? length : 32;
  }

  /// [data] encrypted under a fresh IV and packaged by [mode] and [strategy],
  /// or [data] itself when encryption fails.
  String seal(
    String data,
    Uint8List? aad,
    AppCryptoMode mode,
    AppCryptoPayloadStrategy strategy,
  ) {
    try {
      final iv = IV.fromSecureRandom(_ivLength).bytes;
      final clearText = utf8.encode(data);
      final box = _cipher.encryptSync(
        clearText,
        secretKeyData: _key,
        nonce: iv,
        aad: aad ?? const [],
      );
      final sealed = _joined(box.cipherText, box.mac.bytes);
      return switch (strategy) {
        .colonDelimited => '${_encode(iv, mode)}:${_encode(sealed, mode)}',
        _ => _encode(_joined(iv, sealed), mode),
      };
    } catch (e, t) {
      AppLogger.severe("Encryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  /// [data] decrypted, or [data] itself when decryption fails.
  String open(
    String data,
    Uint8List? aad,
    AppCryptoMode mode,
    AppCryptoPayloadStrategy strategy,
  ) {
    try {
      final (iv, sealed) = _extractIvAndCipher(data, mode, strategy);
      final box = _secretBox(iv, sealed);
      final clearText = _cipher.decryptSync(
        box,
        secretKeyData: _key,
        aad: aad ?? const [],
      );
      return utf8.decode(clearText, allowMalformed: true);
    } catch (e, t) {
      AppLogger.severe("Decryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  /// [sealed] split into the ciphertext and the tag that ends it.
  static SecretBox _secretBox(Uint8List iv, Uint8List sealed) {
    if (sealed.length < _tagLength) {
      throw const FormatException('Ciphertext is shorter than the GCM tag.');
    }
    final tagStart = sealed.length - _tagLength;
    final cipherText = Uint8List.sublistView(sealed, 0, tagStart);
    final tag = Mac(Uint8List.sublistView(sealed, tagStart));
    return SecretBox(cipherText, nonce: iv, mac: tag);
  }

  /// [first] followed by [second], in one buffer.
  static Uint8List _joined(List<int> first, List<int> second) {
    final joined = Uint8List(first.length + second.length);
    joined.setAll(0, first);
    joined.setAll(first.length, second);
    return joined;
  }

  /// Extracts the IV and Cipher bytes from [data] based on [mode] and [strategy].
  static (Uint8List, Uint8List) _extractIvAndCipher(
    String data,
    AppCryptoMode mode,
    AppCryptoPayloadStrategy strategy,
  ) {
    final trimmed = data.value;
    final packaging = _packagingOf(trimmed, strategy);
    if (packaging.isColonDelimited) return _splitColonDelimited(trimmed, mode);
    return _splitContiguous(trimmed, mode);
  }

  /// The packaging [text] uses: [strategy], or read from [text] when auto.
  static AppCryptoPayloadStrategy _packagingOf(
    String text,
    AppCryptoPayloadStrategy strategy,
  ) {
    if (strategy != .auto) return strategy;
    return text.contains(':') ? .colonDelimited : .contiguous;
  }

  /// The IV and sealed bytes of a contiguous payload.
  static (Uint8List, Uint8List) _splitContiguous(
    String text,
    AppCryptoMode mode,
  ) {
    final rawBytes = _decode(text, mode);
    if (rawBytes.length < _ivLength) {
      throw const FormatException(
        'Invalid ciphertext length for AES-GCM: minimum 12 bytes required.',
      );
    }
    final iv = Uint8List.sublistView(rawBytes, 0, _ivLength);
    final sealed = Uint8List.sublistView(rawBytes, _ivLength);
    return (iv, sealed);
  }

  /// The IV and sealed bytes of a colon-delimited payload.
  static (Uint8List, Uint8List) _splitColonDelimited(
    String text,
    AppCryptoMode mode,
  ) {
    final segments = text.split(':');
    if (segments.length != 2) {
      throw const FormatException('Invalid colon-delimited payload format.');
    }

    final ivBytes = _decodeSegment(segments[0], mode);
    if (ivBytes.length != _ivLength) {
      throw FormatException(
        'Invalid IV length for AES-GCM: expected 12 bytes, got ${ivBytes.length}.',
      );
    }

    final cipherBytes = _decodeSegment(segments[1], mode);
    return (ivBytes, cipherBytes);
  }

  /// Encodes [bytes] to string using the specified [mode].
  ///
  /// Hex goes through `package:convert`: `Encrypted.base16` builds two
  /// strings per byte, which costs more than the cipher on a large body.
  static String _encode(List<int> bytes, AppCryptoMode mode) {
    return switch (mode) {
      .base16 => hex.encode(bytes),
      .base64 => base64Encode(bytes),
    };
  }

  /// Decodes [text] to [Uint8List] using the specified [mode].
  static Uint8List _decode(String text, AppCryptoMode mode) {
    return switch (mode) {
      .base16 => _fromHex(text.value),
      .base64 => Encrypted.fromBase64(_normalizeBase64(text)).bytes,
    };
  }

  /// [text] read as hex, in either case.
  static Uint8List _fromHex(String text) {
    final bytes = hex.decode(text);
    return Uint8List.fromList(bytes);
  }

  /// Decodes a segment of a colon-delimited payload with auto-format detection and Base64 normalization.
  static Uint8List _decodeSegment(String segment, AppCryptoMode fallbackMode) {
    final trimmed = segment.value;
    if (_isLikelyBase64(trimmed, fallbackMode)) {
      try {
        return Encrypted.fromBase64(_normalizeBase64(trimmed)).bytes;
      } catch (_) {}
    }

    try {
      return _fromHex(trimmed);
    } catch (_) {
      return Encrypted.fromBase64(_normalizeBase64(trimmed)).bytes;
    }
  }

  /// Whether [segment] reads as Base64 first: always in Base64 [mode], and
  /// otherwise when it is the length of a Base64 IV or holds a character hex
  /// cannot.
  static bool _isLikelyBase64(String segment, AppCryptoMode mode) {
    if (mode.isBase64 || segment.length == 16) return true;
    return AppRegex.base64IndicatorRegex.hasMatch(segment);
  }

  /// Normalizes a Base64 string by replacing URL-safe characters and padding with `=`.
  static String _normalizeBase64(String value) {
    final normalized = value.value.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder == 0) return normalized;
    return normalized.padRight(normalized.length + (4 - remainder), '=');
  }
}
