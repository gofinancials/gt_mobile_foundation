/// What the platform answered when asked for an attestation token.
///
/// A token is only worth anything to a server that verifies it: Google's
/// `decodeIntegrityToken` for Play Integrity, or Apple's attestation and
/// assertion checks for App Attest. This package produces tokens; it never
/// judges them.
sealed class GtAttestationResult {
  const GtAttestationResult();

  /// Parses the map the platform sends back. An unknown or missing `status`
  /// reads as [GtAttestationFailed] with reason `malformed_result`.
  factory GtAttestationResult.fromMap(Map<String, Object?> map) {
    final status = map['status'];
    final reason = map['reason'] as String? ?? 'unknown';
    final code = map['code'] as int?;

    return switch (status) {
      'token' => GtAttestationToken.fromMap(map),
      'unavailable' => GtAttestationUnavailable(reason, code: code),
      'failed' => GtAttestationFailed(reason, code: code),
      _ => const GtAttestationFailed('malformed_result'),
    };
  }
}

/// A token for the app to send to its backend.
final class GtAttestationToken extends GtAttestationResult {
  const GtAttestationToken({
    required this.platform,
    required this.token,
    this.keyId,
  });

  factory GtAttestationToken.fromMap(Map<String, Object?> map) {
    final platform = map['platform'] as String? ?? '';
    final token = map['token'] as String? ?? '';
    final keyId = map['keyId'] as String?;

    return GtAttestationToken(platform: platform, token: token, keyId: keyId);
  }

  /// `android` or `ios`.
  final String platform;

  /// Android: the Play Integrity token. iOS: the App Attest attestation
  /// object (from `attest`) or assertion (from `attestationToken`), base64.
  final String token;

  /// iOS: the App Attest key the token was made with, which the server keys
  /// its stored public key by. Null on Android.
  final String? keyId;
}

/// Why no token was produced.
sealed class GtAttestationProblem extends GtAttestationResult {
  const GtAttestationProblem(this.reason, {this.code});

  /// A snake_case reason, listed on [GtAttestationUnavailable] and
  /// [GtAttestationFailed].
  final String reason;

  /// The platform's own error code, when it gave one: a Play Integrity
  /// `IntegrityErrorCode` / `StandardIntegrityErrorCode`, or a `DCError` code.
  final int? code;
}

/// This device cannot attest at all, so asking again will not help.
///
/// Reasons:
/// - `not_supported`: App Attest is not supported (the simulator, an iPhone
///   app on a Mac, some older devices).
/// - `play_services_not_found`, `play_store_not_found`: no Google Play, as on
///   Huawei and other non-GMS phones.
/// - `play_services_outdated`, `play_store_outdated`: Google Play is too old.
/// - `api_not_available`: the Play Integrity API is not available here.
/// - `missing_plugin`: no native implementation on this platform.
final class GtAttestationUnavailable extends GtAttestationProblem {
  const GtAttestationUnavailable(super.reason, {super.code});
}

/// The device should be able to attest, but this attempt failed.
///
/// Reasons:
/// - `attestation_required`: iOS has no attested key; call `attest` first.
/// - `key_invalidated`: iOS rejected the stored key (a reinstall or restore).
///   It has been deleted; call `attest` again.
/// - `cloud_project_number_required`: Android standard requests need the
///   Google Cloud project number.
/// - `network_error`, `too_many_requests`, `server_unavailable`,
///   `transient_error`: worth retrying later.
/// - `play_integrity_error`, `app_attest_error`: anything else; see [code].
/// - `timeout`, `malformed_result`, `error`: raised on the Dart side.
final class GtAttestationFailed extends GtAttestationProblem {
  const GtAttestationFailed(super.reason, {super.code});
}
