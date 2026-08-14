/// {@category Data}
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

/// {@category Data}
/// Defines how the IV and Ciphertext are packaged or demarcated in the wire payload.
enum AppCryptoPayloadStrategy {
  /// Contiguous byte buffer: `[IV (12 bytes)] + [Ciphertext + AuthTag]`
  /// packed into a single byte array and encoded via [AppCryptoMode].
  contiguous,

  /// Colon-delimited: `${encode(IV)}:${encode(Ciphertext + AuthTag)}`
  /// where each segment is independently encoded via [AppCryptoMode].
  colonDelimited,

  /// Automatically resolves the packaging strategy on decryption
  /// (checks if the payload contains the `:` delimiter).
  auto;

  /// Returns `true` if this strategy is [contiguous].
  bool get isContiguous => this == .contiguous;

  /// Returns `true` if this strategy is [colonDelimited].
  bool get isColonDelimited => this == .colonDelimited;

  /// Returns `true` if this strategy is [auto].
  bool get isAuto => this == .auto;
}

