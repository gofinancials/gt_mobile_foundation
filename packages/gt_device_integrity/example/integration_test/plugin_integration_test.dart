import 'package:flutter_test/flutter_test.dart';
import 'package:gt_device_integrity/gt_device_integrity.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the native checks on a device or emulator. An emulator or simulator
/// must say so; a stock one is not rooted.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the platform answers with a report', (tester) async {
    final report = await const GtDeviceIntegrity().report();

    expect(report.platform, anyOf('android', 'ios'));
    expect(report.packageName, isNotEmpty);
    expect(report.frida, isFalse);
    expect(report.hookingFramework, isNotNull);
    expect(report.debuggerAttached, isNotNull);
    expect(report.instrumentationEvidence, isNotNull);
    if (report.platform == 'android') {
      expect(report.cloneEnvironment, isNotNull);
      expect(report.iosAppOnMac, isNull);
      expect(report.developerMode, isNotNull);
      expect(report.signature, isNotNull);
    } else {
      expect(report.developerMode, isNull);
      expect(report.installer, isNull);
      expect(report.iosAppOnMac, isNotNull);
    }
  });

  testWidgets('App Attest answers not_supported on the simulator', (
    tester,
  ) async {
    final report = await const GtDeviceIntegrity().report();
    final isSimulator = report.platform == 'ios' && report.emulator;

    if (!isSimulator) return;

    final problem = await const GtDeviceIntegrity().prepareAttestation();
    final token = await const GtDeviceIntegrity().attestationToken(data: 'd');

    expect(problem, isA<GtAttestationUnavailable>());
    expect(problem?.reason, 'not_supported');
    expect(token, isA<GtAttestationUnavailable>());
  });
}
