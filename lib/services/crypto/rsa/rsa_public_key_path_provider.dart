import 'dart:io';

/// {@category Services}
/// Describes a reusable source of a readable RSA public-key PEM file path.
abstract interface class RsaPublicKeyPathProvider {
  /// Returns the absolute path to a readable `.pem` file.
  Future<String> getPublicKeyPath({bool forceRefresh = false});
}

/// {@category Services}
/// Thrown when a public-key provider cannot return a valid PEM file path.
class RsaPublicKeyPathProviderException implements Exception {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const RsaPublicKeyPathProviderException(
    this.message, {
    this.error,
    this.stackTrace,
  });

  @override
  String toString() => "RsaPublicKeyPathProviderException: $message";
}

/// {@category Services}
/// Validates RSA public-key PEM content without doing a full cryptographic parse.
final class RsaPublicKeyPemValidator {
  static const _publicKeyHeader = "-----BEGIN PUBLIC KEY-----";
  static const _publicKeyFooter = "-----END PUBLIC KEY-----";
  static const _rsaPublicKeyHeader = "-----BEGIN RSA PUBLIC KEY-----";
  static const _rsaPublicKeyFooter = "-----END RSA PUBLIC KEY-----";
  static const _privateKeyHeader = "-----BEGIN PRIVATE KEY-----";
  static const _rsaPrivateKeyHeader = "-----BEGIN RSA PRIVATE KEY-----";

  const RsaPublicKeyPemValidator();

  /// Returns `true` if [content] looks like a valid RSA public-key PEM.
  static bool isValid(String? content) {
    if (content == null || content.trim().isEmpty) return false;

    final trimmed = content.trim();

    if (trimmed.contains(_privateKeyHeader) ||
        trimmed.contains(_rsaPrivateKeyHeader)) {
      return false;
    }

    final hasStandardKey =
        trimmed.contains(_publicKeyHeader) &&
        trimmed.contains(_publicKeyFooter);
    final hasRsaKey =
        trimmed.contains(_rsaPublicKeyHeader) &&
        trimmed.contains(_rsaPublicKeyFooter);

    if (!hasStandardKey && !hasRsaKey) return false;

    final lines = trimmed
        .split(RegExp(r"\r?\n"))
        .where((line) => line.isNotEmpty);
    final firstLine = lines.isNotEmpty ? lines.first : "";
    final lastLine = lines.isNotEmpty ? lines.last : "";

    return switch ((firstLine, lastLine)) {
      (_publicKeyHeader, _publicKeyFooter) => true,
      (_rsaPublicKeyHeader, _rsaPublicKeyFooter) => true,
      _ => false,
    };
  }

  /// Throws a [RsaPublicKeyPathProviderException] if [content] is not valid.
  static void ensureValid(String content, {required String source}) {
    if (isValid(content)) return;
    throw RsaPublicKeyPathProviderException(
      "Invalid RSA public-key PEM from $source.",
    );
  }

  /// Returns a file-safe copy of [path] suitable for writing into a cache directory.
  static File cacheFile(
    Directory directory, {
    String fileName = "rsa_public_key.pem",
  }) {
    return File("${directory.path}/$fileName");
  }
}
