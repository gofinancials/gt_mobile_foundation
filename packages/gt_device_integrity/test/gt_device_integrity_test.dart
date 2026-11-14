import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_device_integrity/gt_device_integrity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gt_device_integrity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) reply) {
    messenger.setMockMethodCallHandler(channel, (call) async => reply(call));
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads every Android signal', () async {
    String? method;
    answer((call) {
      method = call.method;
      return {
        'platform': 'android',
        'packageName': 'ng.sterling.onebankpersonal',
        'rooted': true,
        'emulator': false,
        'cloneEnvironment': true,
        'processNameMismatch': false,
        'testKeys': false,
        'developerMode': true,
        'installer': 'com.android.vending',
        'signature': 'AB12',
      };
    });

    final report = await const GtDeviceIntegrity().report();

    expect(method, 'report');
    expect(report.platform, 'android');
    expect(report.packageName, 'ng.sterling.onebankpersonal');
    expect(report.rooted, isTrue);
    expect(report.emulator, isFalse);
    expect(report.cloneEnvironment, isTrue);
    expect(report.processNameMismatch, isFalse);
    expect(report.testKeys, isFalse);
    expect(report.developerMode, isTrue);
    expect(report.installer, 'com.android.vending');
    expect(report.signature, 'AB12');
    expect(report.iosAppOnMac, isNull);
  });

  test('leaves unmeasured iOS signals null instead of guessing', () async {
    answer(
      (_) => {
        'platform': 'ios',
        'packageName': 'ng.sterling.onebankpersonal',
        'rooted': false,
        'emulator': true,
        'iosAppOnMac': false,
      },
    );

    final report = await const GtDeviceIntegrity().report();

    expect(report.emulator, isTrue);
    expect(report.iosAppOnMac, isFalse);
    expect(report.rooted, isFalse);
    expect(report.cloneEnvironment, isNull);
    expect(report.developerMode, isNull);
    expect(report.installer, isNull);
    expect(report.signature, isNull);
  });

  test('reads an iPhone app on a Mac', () async {
    answer(
      (_) => {
        'platform': 'ios',
        'packageName': 'ng.sterling.onebankpersonal',
        'rooted': false,
        'emulator': false,
        'iosAppOnMac': true,
      },
    );

    final report = await const GtDeviceIntegrity().report();

    expect(report.iosAppOnMac, isTrue);
    expect(report.rooted, isFalse);
  });

  test('a sideloaded Android build has no installer', () async {
    answer(
      (_) => {
        'platform': 'android',
        'packageName': 'p',
        'rooted': false,
        'emulator': false,
        'installer': null,
      },
    );

    expect((await const GtDeviceIntegrity().report()).installer, isNull);
  });

  test('surfaces a platform without the plugin to the caller', () {
    expect(
      const GtDeviceIntegrity().report(),
      throwsA(isA<MissingPluginException>()),
    );
  });

  test('surfaces a platform failure to the caller', () {
    answer((_) => throw PlatformException(code: 'boom'));

    expect(
      const GtDeviceIntegrity().report(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('round-trips through toMap', () async {
    const report = GtDeviceIntegrityReport(
      platform: 'android',
      packageName: 'p',
      rooted: false,
      emulator: true,
      developerMode: false,
      iosAppOnMac: false,
    );

    final copy = GtDeviceIntegrityReport.fromMap(report.toMap());

    expect(copy.toMap(), report.toMap());
  });

  test('reads the instrumentation readings and their evidence', () async {
    const evidence = ['maps:frida', 'debugger:tracer_pid'];

    answer(
      (_) => {
        'platform': 'android',
        'packageName': 'p',
        'rooted': false,
        'emulator': false,
        'frida': true,
        'hookingFramework': false,
        'debuggerAttached': true,
        'instrumentationEvidence': evidence,
      },
    );

    final report = await const GtDeviceIntegrity().report();

    expect(report.frida, isTrue);
    expect(report.hookingFramework, isFalse);
    expect(report.debuggerAttached, isTrue);
    expect(report.instrumentationEvidence, evidence);
  });

  test('leaves instrumentation null when the platform does not send it', () {
    final report = GtDeviceIntegrityReport.fromMap(const {'platform': 'ios'});

    expect(report.frida, isNull);
    expect(report.hookingFramework, isNull);
    expect(report.debuggerAttached, isNull);
    expect(report.instrumentationEvidence, isNull);
  });

  test('rejects an answer that names no platform', () {
    final report = const GtDeviceIntegrity().report;

    answer((_) => <String, Object?>{});
    expect(report(), throwsA(isA<FormatException>()));

    answer((_) => {'platform': '', 'rooted': false});
    expect(report(), throwsA(isA<FormatException>()));
  });

  group('attestation', () {
    const plugin = GtDeviceIntegrity();

    test('attest sends the challenge and project number', () async {
      MethodCall? sent;
      answer((call) {
        sent = call;
        return {
          'status': 'token',
          'platform': 'ios',
          'token': 't',
          'keyId': 'k',
        };
      });

      final result = await plugin.attest(challenge: 'c', cloudProjectNumber: 7);
      final token = result as GtAttestationToken;

      expect(sent?.method, 'attest');
      expect(sent?.arguments, {'challenge': 'c', 'cloudProjectNumber': 7});
      expect(token.platform, 'ios');
      expect(token.token, 't');
      expect(token.keyId, 'k');
    });

    test('attestationToken sends the request data', () async {
      MethodCall? sent;
      answer((call) {
        sent = call;
        return {'status': 'token', 'platform': 'android', 'token': 't'};
      });

      final result = await plugin.attestationToken(data: 'body');
      final token = result as GtAttestationToken;

      expect(sent?.method, 'attestationToken');
      expect(sent?.arguments, {'data': 'body', 'cloudProjectNumber': null});
      expect(token.keyId, isNull);
    });

    test('reads unavailable and failed answers with their code', () async {
      const unavailableReply = {
        'status': 'unavailable',
        'reason': 'play_services_not_found',
        'code': -6,
      };
      const failedReply = {
        'status': 'failed',
        'reason': 'key_invalidated',
        'code': 2,
      };

      answer((_) => unavailableReply);
      final unavailable = await plugin.attestationToken(data: 'd');

      answer((_) => failedReply);
      final failed = await plugin.attestationToken(data: 'd');

      final unavailableProblem = unavailable as GtAttestationUnavailable;
      final failedProblem = failed as GtAttestationFailed;

      expect(unavailableProblem.reason, 'play_services_not_found');
      expect(unavailableProblem.code, -6);
      expect(failedProblem.reason, 'key_invalidated');
    });

    test('reads an unknown answer as malformed', () async {
      answer((_) => {'status': 'maybe'});

      final result = await plugin.attest(challenge: 'c');
      final problem = result as GtAttestationFailed;

      expect(problem.reason, 'malformed_result');
    });

    test('prepareAttestation answers null when ready', () async {
      answer((_) => {'status': 'ready'});
      final ready = await plugin.prepareAttestation(cloudProjectNumber: 7);

      answer((_) => {'status': 'unavailable', 'reason': 'not_supported'});
      final problem = await plugin.prepareAttestation();

      expect(ready, isNull);
      expect(problem, isA<GtAttestationUnavailable>());
      expect(problem?.reason, 'not_supported');
    });
  });
}
