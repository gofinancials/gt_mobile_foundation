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
  });

  test('leaves unmeasured iOS signals null instead of guessing', () async {
    answer(
      (_) => {
        'platform': 'ios',
        'packageName': 'ng.sterling.onebankpersonal',
        'rooted': false,
        'emulator': true,
      },
    );

    final report = await const GtDeviceIntegrity().report();

    expect(report.emulator, isTrue);
    expect(report.rooted, isFalse);
    expect(report.cloneEnvironment, isNull);
    expect(report.developerMode, isNull);
    expect(report.installer, isNull);
    expect(report.signature, isNull);
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
    );

    final copy = GtDeviceIntegrityReport.fromMap(report.toMap());

    expect(copy.toMap(), report.toMap());
  });
}
