import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Downloads an RSA public-key PEM using the existing HTTP service and caches it locally.
///
/// The endpoint and response provide key content only; neither supplies the
/// cache filename. [RsaPublicKeyPemValidator.cacheFile] validates the configured
/// destination before cache lookup and again after the request, before writing.
/// Forced refreshes use the same checks. The cache directory and its ancestors
/// must remain under application control. Configure a trusted HTTPS endpoint
/// and retain certificate validation on [httpService]; PEM framing checks
/// alone do not authenticate a downloaded public key.
final class RemoteRsaPublicKeyPathProvider implements RsaPublicKeyPathProvider {
  final AppHttpService httpService;
  final String endpoint;

  /// Trusted app-private cache directory; must not be controlled by user input.
  final Directory directory;
  final String fileName;
  final Options? options;

  const RemoteRsaPublicKeyPathProvider({
    required this.httpService,
    required this.endpoint,
    required this.directory,
    this.fileName = "rsa_public_key.pem",
    this.options,
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
      final response = await httpService.get(
        endpoint,
        options: options ?? Options(responseType: ResponseType.plain),
      );
      final pem = _extractPem(response);
      RsaPublicKeyPemValidator.ensureValid(pem, source: "remote:$endpoint");
      // Loading the asset or response may have allowed the cache entry to change.
      final writeTarget = RsaPublicKeyPemValidator.cacheFile(
        directory,
        fileName: fileName,
      );
      await writeTarget.writeAsString(pem);
      return writeTarget.absolute.path;
    } catch (e, t) {
      if (e is RsaPublicKeyPathProviderException) rethrow;
      throw RsaPublicKeyPathProviderException(
        "Failed to download RSA public key.",
        error: e,
        stackTrace: t,
      );
    }
  }

  String _extractPem(ApiResponse<Response> response) {
    final payload = response.data ?? response.rawResponse?.data;

    if (payload is String) return payload;
    if (payload is List<int>) return String.fromCharCodes(payload);
    if (payload is Map && payload["data"] is String) {
      return payload["data"] as String;
    }
    if (payload is Map && payload["pem"] is String) {
      return payload["pem"] as String;
    }

    throw RsaPublicKeyPathProviderException(
      "Remote RSA public key response was empty.",
    );
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
