import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Reads the device through `gt_device_integrity` and judges whether the app
/// may run on it.
abstract class AppDeviceIntegrityService {
  /// Reads and judges the device. When [enforced] is false the verdict never
  /// blocks, though the readings are still taken and logged.
  ///
  /// Never throws: a device that cannot be read is let through, with
  /// [AppDeviceIntegrityVerdict.failureReason] saying why.
  Future<AppDeviceIntegrityVerdict> evaluate({required bool enforced});
}
