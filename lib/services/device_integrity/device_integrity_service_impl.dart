import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// The standard [AppDeviceIntegrityService], over the `gt_device_integrity`
/// plugin, with NewMobileChannel's rules.
class AppDeviceIntegrityServiceImpl implements AppDeviceIntegrityService {
  /// Creates the service. [trustedInstallers] and [signatureAllowList] only
  /// feed reported signals; neither blocks.
  const AppDeviceIntegrityServiceImpl({
    this.plugin = const GtDeviceIntegrity(),
    this.trustedInstallers = const {'com.android.vending'},
    this.signatureAllowList = const {},
    this.timeout = const Duration(seconds: 3),
  });

  /// The plugin that reads the device.
  final GtDeviceIntegrity plugin;

  /// Installers that are not reported as unsafe. An unknown installer is
  /// never reported.
  final Set<String> trustedInstallers;

  /// Upper-case SHA-256 signing-certificate digests the build may carry.
  /// Empty means the signature is not checked.
  final Set<String> signatureAllowList;

  /// How long to wait for the platform before letting the device through.
  final Duration timeout;

  @override
  Future<AppDeviceIntegrityVerdict> evaluate({required bool enforced}) async {
    try {
      final report = await plugin.report().timeout(timeout);
      final verdict = _judge(report, enforced: enforced);
      AppLogger.info('Device integrity: ${verdict.summary}');
      return verdict;
    } on TimeoutException catch (e, t) {
      AppLogger.severe('Device integrity timed out', error: e, stackTrace: t);
      return .unread(enforced: enforced, failureReason: 'security_timeout');
    } catch (e, t) {
      AppLogger.severe('Device integrity failed', error: e, stackTrace: t);
      return .unread(enforced: enforced, failureReason: 'security_error');
    }
  }

  AppDeviceIntegrityVerdict _judge(
    GtDeviceIntegrityReport report, {
    required bool enforced,
  }) {
    final installer = report.installer;
    final signature = report.signature;
    return AppDeviceIntegrityVerdict(
      enforced: enforced,
      rooted: report.rooted,
      cloneEnvironment: report.cloneEnvironment ?? false,
      emulator: report.emulator,
      developerMode: report.developerMode ?? false,
      unsafeInstaller:
          installer.hasValue && !trustedInstallers.contains(installer),
      signatureInvalid:
          signatureAllowList.isNotEmpty &&
          !signatureAllowList.contains(signature),
      platform: report.platform,
      report: report,
    );
  }
}
