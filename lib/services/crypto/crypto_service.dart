import 'dart:typed_data';

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Defines the interface for cryptographic operations (encryption/decryption).
abstract class AppCryptoService {
  /// Initializes any asynchronous crypto dependencies.
  Future<void> init();

  /// Encrypts the provided [data] using the specified encoding [mode] and packaging [strategy] (defaults to service's [defaultStrategy]).
  String encrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  });

  /// Decrypts the provided [data] using the specified encoding [mode] and packaging [strategy] (defaults to auto-detection).
  String decrypt(
    String data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  });

  /// Safely attempts to decrypt the provided [data], returning the original value if decryption fails or if [data] is null/empty.
  String? tryDecrypt(
    String? data, {
    AppCryptoMode mode = .base16,
    AppCryptoPayloadStrategy strategy = .auto,
    Uint8List? associatedData,
  });

  /// Encrypts the provided [data] using RSA algorithm and specified [mode].
  String? encryptRsa(String data, {AppCryptoMode mode = .base16});

  /// The application tag used for encryption.
  String get appTag;

  /// The default packaging strategy for this service instance.
  AppCryptoPayloadStrategy get defaultStrategy;
}

