/// Defines the supported cryptographic encoding modes.
enum AppCryptoMode {
  /// Base16 (Hexadecimal) encoding.
  base16,

  /// Base64 encoding.
  base64;

  /// Returns `true` if this mode is [base16].
  bool get isBase16 => this == .base16;

  /// Returns `true` if this mode is [base64].
  bool get isBase64 => this == .base64;
}
