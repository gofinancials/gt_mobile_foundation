import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock [AppDeviceAttestationService] for tests and mock builds. It talks to
/// no platform and answers with [result], or a fake token.
class AppDeviceAttestationServiceMock implements AppDeviceAttestationService {
  /// Creates the mock. [result] receives the challenge or data of each call.
  AppDeviceAttestationServiceMock({this.result});

  /// Builds the answer to return; null answers a fake token that no backend
  /// will accept.
  final GtAttestationResult Function(String value)? result;

  @override
  Future<GtAttestationProblem?> prepare() async => null;

  @override
  Future<GtAttestationResult> attest({required String challenge}) async {
    return result?.call(challenge) ?? _fake('attestation:$challenge');
  }

  @override
  Future<GtAttestationResult> token({required String data}) async {
    return result?.call(data) ?? _fake('assertion:$data');
  }

  GtAttestationToken _fake(String token) {
    return GtAttestationToken(platform: 'mock', token: 'mock-$token');
  }
}
