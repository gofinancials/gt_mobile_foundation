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
/// Defines the packaging strategy for formatted crypto payloads.
enum AppCryptoPayloadStrategy {
  /// Contiguous bytes: `[IV (12 bytes)] + [Ciphertext + AuthTag]` as a single block.
  contiguous,

  /// Colon-delimited format: `${encode(IV)}:${encode(Ciphertext + AuthTag)}`.
  colonDelimited,

  /// Automatically resolves the strategy on decryption (or uses the service default on encryption).
  auto;

  /// Returns `true` if this strategy is [contiguous].
  bool get isContiguous => this == .contiguous;

  /// Returns `true` if this strategy is [colonDelimited].
  bool get isColonDelimited => this == .colonDelimited;

  /// Returns `true` if this strategy is [auto].
  bool get isAuto => this == .auto;
}

