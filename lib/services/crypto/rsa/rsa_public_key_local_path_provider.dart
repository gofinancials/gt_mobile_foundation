import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Loads an RSA public-key PEM from Flutter assets and caches it on disk.
///
/// Cache destinations come from the configured [directory] and [fileName],
/// not the asset's contents. [RsaPublicKeyPemValidator.cacheFile] validates the
/// path before cache lookup and revalidates it after asset loading, before
/// writing. Forced refreshes use the same checks. The directory and its
/// ancestors must remain under application control.
final class LocalRsaPublicKeyPathProvider implements RsaPublicKeyPathProvider {
  final AssetBundle assetBundle;
  final String assetPath;

  /// Trusted app-private cache directory; must not be controlled by user input.
  final Directory directory;
  final String fileName;

  const LocalRsaPublicKeyPathProvider({
    required this.assetBundle,
    required this.assetPath,
    required this.directory,
    this.fileName = "rsa_public_key.pem",
  });

  @override
  Future<String> getPublicKeyPath({bool forceRefresh = false}) async {
    final cachedFile = RsaPublicKeyPemValidator.cacheFile(
      directory,
      fileName: fileName,
    );

    if (!forceRefresh && await _hasValidCachedCopy(cachedFile)) {
      return cachedFile.absolute.path;
    }

    try {
      await directory.create(recursive: true);
      final pem = await assetBundle.loadString(assetPath);
      RsaPublicKeyPemValidator.ensureValid(pem, source: "asset:$assetPath");
      // Loading the asset or response may have allowed the cache entry to change.
      final writeTarget = RsaPublicKeyPemValidator.cacheFile(
        directory,
        fileName: fileName,
      );
      await writeTarget.writeAsString(pem);
      return writeTarget.absolute.path;
    } catch (e, t) {
      throw RsaPublicKeyPathProviderException(
        "Failed to load RSA public key from asset.",
        error: e,
        stackTrace: t,
      );
    }
  }

  Future<bool> _hasValidCachedCopy(File file) async {
    try {
      if (!await file.exists()) return false;
      final pem = await file.readAsString();
      return RsaPublicKeyPemValidator.isValid(pem);
    } catch (_) {
      return false;
    }
  }
}
