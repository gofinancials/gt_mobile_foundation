import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Defines the interface for cryptographic operations (encryption/decryption).
abstract class AppCryptoService {
  /// Encrypts the provided [data] using the specified [mode] (defaults to Base16).
  String encrypt(String data, {AppCryptoMode mode = .base16});

  /// Decrypts the provided [data] using the specified [mode] (defaults to Base16).
  String decrypt(String data, {AppCryptoMode mode = .base16});

  /// Encrypts the provided [data] using RSA algorithm and specified [mode].
  String? encryptRsa(String data, {AppCryptoMode mode = .base16});
}
