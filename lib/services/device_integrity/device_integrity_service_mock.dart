import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock [AppDeviceIntegrityService] for tests and mock builds. It reads
/// nothing and returns [verdict], or a passing one.
class AppDeviceIntegrityServiceMock implements AppDeviceIntegrityService {
  /// Creates the mock. [verdict] receives the `enforced` flag of each call.
  AppDeviceIntegrityServiceMock({this.verdict});

  /// Builds the verdict to return; null lets every device through.
  final AppDeviceIntegrityVerdict Function(bool enforced)? verdict;

  @override
  Future<AppDeviceIntegrityVerdict> evaluate({required bool enforced}) async {
    return verdict?.call(enforced) ?? .new(enforced: enforced);
  }
}
