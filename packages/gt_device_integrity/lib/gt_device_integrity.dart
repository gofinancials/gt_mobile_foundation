import 'package:flutter/services.dart';

/// What the device says about itself.
///
/// Every field is a measurement, not a judgement: gt_mobile_foundation decides
/// which signals block the app. A field is null where the platform cannot
/// measure it (iOS reports only [rooted] and [emulator]).
class GtDeviceIntegrityReport {
  const GtDeviceIntegrityReport({
    required this.platform,
    required this.packageName,
    required this.rooted,
    required this.emulator,
    this.cloneEnvironment,
    this.processNameMismatch,
    this.testKeys,
    this.developerMode,
    this.installer,
    this.signature,
  });

  factory GtDeviceIntegrityReport.fromMap(Map<String, Object?> map) {
    return GtDeviceIntegrityReport(
      platform: map['platform'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      rooted: map['rooted'] == true,
      emulator: map['emulator'] == true,
      cloneEnvironment: map['cloneEnvironment'] as bool?,
      processNameMismatch: map['processNameMismatch'] as bool?,
      testKeys: map['testKeys'] as bool?,
      developerMode: map['developerMode'] as bool?,
      installer: map['installer'] as String?,
      signature: map['signature'] as String?,
    );
  }

  /// `android` or `ios`.
  final String platform;

  /// The application ID (Android) or bundle identifier (iOS).
  final String packageName;

  /// Rooted (Android: su binaries, Magisk, test-keys) or jailbroken (iOS:
  /// jailbreak files, or a write outside the sandbox that succeeds). Always
  /// false on the iOS simulator.
  final bool rooted;

  /// An Android emulator or the iOS simulator.
  final bool emulator;

  /// Android: running inside a cloning app (a parallel-space sandbox path, a
  /// renamed process, or a known cloning app installed).
  final bool? cloneEnvironment;

  /// Android: the process name differs from [packageName]. Also counted in
  /// [cloneEnvironment]; reported alone for diagnostics.
  final bool? processNameMismatch;

  /// Android: the system image is signed with test keys. Also counted in
  /// [rooted]; reported alone for diagnostics.
  final bool? testKeys;

  /// Android: Developer options are switched on.
  final bool? developerMode;

  /// Android: the package that installed the app (`com.android.vending` for
  /// Google Play), or null when Android does not say, as for a sideload.
  final String? installer;

  /// Android: SHA-256 of the first signing certificate, upper-case hex.
  final String? signature;

  Map<String, Object?> toMap() => {
    'platform': platform,
    'packageName': packageName,
    'rooted': rooted,
    'emulator': emulator,
    'cloneEnvironment': cloneEnvironment,
    'processNameMismatch': processNameMismatch,
    'testKeys': testKeys,
    'developerMode': developerMode,
    'installer': installer,
    'signature': signature,
  };
}

/// Asks the platform for a [GtDeviceIntegrityReport].
class GtDeviceIntegrity {
  const GtDeviceIntegrity({
    MethodChannel channel = const MethodChannel('gt_device_integrity'),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// Reads the device. Throws [MissingPluginException] on a platform without
  /// an implementation, and [PlatformException] if the platform fails; the
  /// caller chooses whether that fails open.
  Future<GtDeviceIntegrityReport> report() async {
    final map = await _channel.invokeMapMethod<String, Object?>('report');
    return GtDeviceIntegrityReport.fromMap(map ?? const {});
  }
}
