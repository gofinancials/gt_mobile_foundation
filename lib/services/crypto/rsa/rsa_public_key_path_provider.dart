import 'dart:io';

import 'package:gt_mobile_foundation/data/constants/regex.dart';
import 'package:path/path.dart' as p;

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
/// Checks public-key PEM framing and validates paths used by the key caches.
///
/// Content checks reject empty input, unsupported framing, and recognized
/// private-key headers. They do not verify the encoded key, its strength, or
/// its authenticity. Cryptographic parsing occurs in the crypto service;
/// callers must obtain public keys from a trusted asset or endpoint.
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
        .split(AppRegex.lineBreakRegex)
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

  /// Returns a cache file beneath the caller's trusted, app-private [directory].
  ///
  /// Security review (CWE-73, finding 1643): [fileName] is restricted using
  /// [AppRegex.portableFileNameRegex] and [AppRegex.windowsReservedFileNameRegex].
  /// These checks reject traversal, separators, absolute paths, control
  /// characters, reserved device names, and names longer than 255 characters.
  /// The normalized candidate must remain beneath the normalized cache root.
  /// Existing links (including dangling links) and non-file entries are
  /// rejected using a filesystem type check that does not follow links.
  ///
  /// Both production providers call this before cache lookup and again after
  /// loading the key, immediately before writing, including forced refreshes.
  /// Invalid paths fail with [RsaPublicKeyPathProviderException]. PEM content
  /// cannot choose the destination path.
  ///
  /// The caller must keep the directory and its ancestors under app control;
  /// these checks do not make an attacker-writable directory safe from races.
  static File cacheFile(
    Directory directory, {
    String fileName = "rsa_public_key.pem",
  }) {
    if (!AppRegex.portableFileNameRegex.hasMatch(fileName) ||
        AppRegex.windowsReservedFileNameRegex.hasMatch(fileName)) {
      throw const RsaPublicKeyPathProviderException(
        "Cache filename must be a single portable filename.",
      );
    }

    final root = p.normalize(directory.absolute.path);
    final path = p.normalize(p.join(root, fileName));
    if (!p.isWithin(root, path)) {
      throw const RsaPublicKeyPathProviderException(
        "Cache file must remain inside the cache directory.",
      );
    }

    try {
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.file) {
        throw const RsaPublicKeyPathProviderException(
          "Cache entry must be a regular file, not a link or directory.",
        );
      }
      return File(path);
    } on FileSystemException catch (e, t) {
      throw RsaPublicKeyPathProviderException(
        "Failed to inspect the public key cache path.",
        error: e,
        stackTrace: t,
      );
    }
  }
}
