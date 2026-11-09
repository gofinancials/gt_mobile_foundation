import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Reads the device through `gt_device_integrity` and judges whether the app
/// may run on it.
abstract class AppDeviceIntegrityService {
  /// Reads and judges the device. When [enforced] is false the verdict never
  /// blocks, though the readings are still taken and logged.
  ///
  /// Never throws: a device that cannot be read is let through, with
  /// [AppDeviceIntegrityVerdict.failureReason] saying why. That includes a
  /// report that names no platform, which reads as `security_error` rather
  /// than a clean device.
  ///
  /// Every reading is taken on the device and can be hooked, and failing open
  /// means making the plugin throw or hang is enough to pass. Use
  /// [AppDeviceAttestationService] for a result a server can trust.
  Future<AppDeviceIntegrityVerdict> evaluate({required bool enforced});
}
