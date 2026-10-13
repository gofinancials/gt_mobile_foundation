import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Whether this device may run the app, and the readings behind the decision.
///
/// The rules are NewMobileChannel's: only device-integrity signals block.
/// Developer mode, the installer and the signature are reported but never
/// block, because pilot builds ship through Firebase App Distribution and
/// testers keep USB debugging on.
class AppDeviceIntegrityVerdict {
  /// Creates a verdict from readings already judged by
  /// [AppDeviceIntegrityService].
  const AppDeviceIntegrityVerdict({
    required this.enforced,
    this.rooted = false,
    this.cloneEnvironment = false,
    this.emulator = false,
    this.developerMode = false,
    this.unsafeInstaller = false,
    this.signatureInvalid = false,
    this.platform = '',
    this.failureReason,
    this.report,
    this.debugBuild = kDebugMode,
  });

  /// A verdict that lets the app run, used when the device could not be read.
  const AppDeviceIntegrityVerdict.unread({
    required this.enforced,
    required String this.failureReason,
    this.platform = '',
  }) : rooted = false,
       cloneEnvironment = false,
       emulator = false,
       developerMode = false,
       unsafeInstaller = false,
       signatureInvalid = false,
       report = null,
       debugBuild = kDebugMode;

  /// Whether this build blocks a failing device. When false nothing blocks.
  final bool enforced;

  /// Rooted (Android) or jailbroken (iOS).
  final bool rooted;

  /// Running inside a cloning app (Android).
  final bool cloneEnvironment;

  /// An Android emulator or the iOS simulator.
  final bool emulator;

  /// Developer options are on (Android). Reported only.
  final bool developerMode;

  /// Installed by a package outside the trusted set (Android). Reported only.
  final bool unsafeInstaller;

  /// Signed by a certificate outside the allow-list (Android). Reported only.
  final bool signatureInvalid;

  /// `android` or `ios`, or empty when the device was not read.
  final String platform;

  /// Why the device could not be read: `security_timeout` or
  /// `security_error`. Null when it was read.
  final String? failureReason;

  /// The readings this verdict was judged from; null when unread.
  final GtDeviceIntegrityReport? report;

  /// Whether this is a debug build. A debug build on an emulator is a
  /// developer's machine, and emulator images often carry `su`.
  final bool debugBuild;

  /// Whether the app must not run on this device.
  bool get isBlocked {
    if (!enforced) return false;
    if (emulator) return !debugBuild;
    return rooted || cloneEnvironment;
  }

  /// Every signal that was raised, blocking or not, for logs and analytics.
  List<String> get signals => [
    if (rooted) 'root_or_jailbreak',
    if (developerMode) 'developer_mode',
    if (cloneEnvironment) 'clone_environment',
    if (unsafeInstaller) 'unsafe_installer',
    if (signatureInvalid) 'signature_mismatch',
    if (emulator) 'emulator',
  ];

  /// One line for logs: `device_approved`, or what blocked it.
  String get summary {
    if (!isBlocked) return 'device_approved';
    if (signals.isEmpty) return failureReason ?? 'security_blocked';
    return signals.join(', ');
  }
}
