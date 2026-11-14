import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Produces attestation tokens through `gt_device_integrity`: Play Integrity
/// on Android, App Attest on iOS.
///
/// Unlike [AppDeviceIntegrityService], nothing here is judged on the device. A
/// token means something only once the app's backend verifies it, and a
/// device that cannot produce one answers with a [GtAttestationProblem] for
/// the backend to judge. Send problems to the backend too: one that never sees
/// a token cannot tell a failed attempt from a hooked app that skipped it.
abstract class AppDeviceAttestationService {
  /// Gets the platform ready, ideally at app start, and returns null when it
  /// is. Optional: [token] prepares on first use.
  Future<GtAttestationProblem?> prepare();

  /// The one-off check, bound to [challenge], a single-use value the server
  /// issued. Use it at registration or login. On iOS it registers a new key
  /// whose ID comes back in [GtAttestationToken.keyId]; call it again after a
  /// `key_invalidated` or `attestation_required` problem.
  Future<GtAttestationResult> attest({required String challenge});

  /// The per-request check, bound to [data], the request being made (for
  /// example a transfer's canonical body). Both platforms hash it with
  /// SHA-256 on the device; the server reproduces the hash.
  Future<GtAttestationResult> token({required String data});
}
