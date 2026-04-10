enum AppCryptoMode {
  base16,
  base64;

  bool get isBase16 => this == .base16;
  bool get isBase64 => this == .base64;
}
