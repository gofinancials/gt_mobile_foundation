import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Loads an RSA public-key PEM from Flutter assets and caches it on disk.
final class LocalRsaPublicKeyPathProvider implements RsaPublicKeyPathProvider {
  final AssetBundle assetBundle;
  final String assetPath;
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
      await cachedFile.writeAsString(pem);
      return cachedFile.absolute.path;
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
