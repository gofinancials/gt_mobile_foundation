import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Downloads an RSA public-key PEM using the existing HTTP service and caches it locally.
final class RemoteRsaPublicKeyPathProvider implements RsaPublicKeyPathProvider {
  final AppHttpService httpService;
  final String endpoint;
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
      await cachedFile.writeAsString(pem);
      return cachedFile.absolute.path;
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
