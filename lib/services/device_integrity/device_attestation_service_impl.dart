import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// The standard [AppDeviceAttestationService], over the `gt_device_integrity`
/// plugin.
///
/// Never throws. A missing plugin answers [GtAttestationUnavailable] with
/// `missing_plugin`; a timeout or any other error answers
/// [GtAttestationFailed] with `timeout` or `error`. Tokens are never logged.
class AppDeviceAttestationServiceImpl implements AppDeviceAttestationService {
  /// Creates the service. Android needs [cloudProjectNumber], the Google
  /// Cloud project linked to the app in Play Console, for [prepare] and
  /// [token]; iOS ignores it.
  const AppDeviceAttestationServiceImpl({
    this.plugin = const GtDeviceIntegrity(),
    this.cloudProjectNumber,
    this.timeout = const Duration(seconds: 15),
  });

  /// The plugin that talks to Play Integrity or App Attest.
  final GtDeviceIntegrity plugin;

  /// The Google Cloud project number linked in Play Console.
  final int? cloudProjectNumber;

  /// How long to wait for the platform. Preparing Play Integrity and
  /// attesting an App Attest key both go to a server, so this is longer than
  /// the device integrity timeout.
  final Duration timeout;

  @override
  Future<GtAttestationProblem?> prepare() async {
    final result = await _run('prepare', _prepare);

    if (result is GtAttestationProblem) return result;

    return null;
  }

  @override
  Future<GtAttestationResult> attest({required String challenge}) async {
    final result = await _run('attest', () => _attest(challenge));

    return result ?? const GtAttestationFailed('malformed_result');
  }

  @override
  Future<GtAttestationResult> token({required String data}) async {
    final result = await _run('token', () => _token(data));

    return result ?? const GtAttestationFailed('malformed_result');
  }

  Future<GtAttestationProblem?> _prepare() {
    return plugin.prepareAttestation(cloudProjectNumber: cloudProjectNumber);
  }

  Future<GtAttestationResult> _attest(String challenge) {
    final number = cloudProjectNumber;

    return plugin.attest(challenge: challenge, cloudProjectNumber: number);
  }

  Future<GtAttestationResult> _token(String data) {
    final number = cloudProjectNumber;

    return plugin.attestationToken(data: data, cloudProjectNumber: number);
  }

  Future<GtAttestationResult?> _run(
    String action,
    Future<GtAttestationResult?> Function() call,
  ) async {
    try {
      final result = await call().timeout(timeout);
      AppLogger.info('Device attestation $action: ${_describe(result)}');
      return result;
    } on TimeoutException catch (e, t) {
      AppLogger.severe('Device attestation timed out', error: e, stackTrace: t);
      return const GtAttestationFailed('timeout');
    } on MissingPluginException {
      return const GtAttestationUnavailable('missing_plugin');
    } catch (e, t) {
      AppLogger.severe('Device attestation failed', error: e, stackTrace: t);
      return const GtAttestationFailed('error');
    }
  }

  String _describe(GtAttestationResult? result) {
    return switch (result) {
      null => 'ready',
      GtAttestationToken() => 'token',
      GtAttestationUnavailable(:final reason) => 'unavailable ($reason)',
      GtAttestationFailed(:final reason) => 'failed ($reason)',
    };
  }
}
