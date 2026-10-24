import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gt_device_integrity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Future<Object?> Function() reply) {
    messenger.setMockMethodCallHandler(channel, (_) => reply());
  }

  Map<String, Object?> android({
    bool rooted = false,
    bool clone = false,
    bool emulator = false,
    bool developerMode = false,
    String? installer = 'com.android.vending',
    String? signature = 'AB12',
  }) => {
    'platform': 'android',
    'packageName': 'ng.sterling.onebankpersonal',
    'rooted': rooted,
    'emulator': emulator,
    'cloneEnvironment': clone,
    'developerMode': developerMode,
    'installer': installer,
    'signature': signature,
  };

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('AppDeviceIntegrityVerdict', () {
    AppDeviceIntegrityVerdict verdict({
      bool enforced = true,
      bool rooted = false,
      bool clone = false,
      bool emulator = false,
      bool developerMode = false,
      bool unsafeInstaller = false,
      bool signatureInvalid = false,
      bool debugBuild = false,
    }) => AppDeviceIntegrityVerdict(
      enforced: enforced,
      rooted: rooted,
      cloneEnvironment: clone,
      emulator: emulator,
      developerMode: developerMode,
      unsafeInstaller: unsafeInstaller,
      signatureInvalid: signatureInvalid,
      debugBuild: debugBuild,
    );

    test('blocks rooted or jailbroken and cloned environments', () {
      expect(verdict(rooted: true).isBlocked, isTrue);
      expect(verdict(clone: true).isBlocked, isTrue);
      expect(verdict(rooted: true).summary, 'root_or_jailbreak');
    });

    test(
      'reports developer mode, installer and signature without blocking',
      () {
        final reported = verdict(
          developerMode: true,
          unsafeInstaller: true,
          signatureInvalid: true,
        );

        expect(reported.isBlocked, isFalse);
        expect(reported.signals, [
          'developer_mode',
          'unsafe_installer',
          'signature_mismatch',
        ]);
        expect(reported.summary, 'device_approved');
      },
    );

    test('blocks an emulator except in a debug build, even with su', () {
      expect(verdict(emulator: true).isBlocked, isTrue);
      expect(verdict(emulator: true, debugBuild: true).isBlocked, isFalse);
      expect(
        verdict(emulator: true, rooted: true, debugBuild: true).isBlocked,
        isFalse,
      );
    });

    test('never blocks when the build does not enforce', () {
      expect(verdict(enforced: false, rooted: true).isBlocked, isFalse);
      expect(verdict(enforced: false, emulator: true).isBlocked, isFalse);
    });

    test('an unread device runs, and says why', () {
      const unread = AppDeviceIntegrityVerdict.unread(
        enforced: true,
        failureReason: 'security_timeout',
      );

      expect(unread.isBlocked, isFalse);
      expect(unread.failureReason, 'security_timeout');
    });
  });

  group('AppDeviceIntegrityServiceImpl', () {
    test('judges the report the plugin returns', () async {
      answer(() async => android(clone: true, developerMode: true));

      final verdict = await const AppDeviceIntegrityServiceImpl().evaluate(
        enforced: true,
      );

      expect(verdict.isBlocked, isTrue);
      expect(verdict.cloneEnvironment, isTrue);
      expect(verdict.developerMode, isTrue);
      expect(verdict.platform, 'android');
      expect(verdict.report?.packageName, 'ng.sterling.onebankpersonal');
      expect(verdict.failureReason, isNull);
    });

    test(
      'trusts Play, and never reports an installer Android does not name',
      () async {
        const service = AppDeviceIntegrityServiceImpl();

        answer(() async => android());
        expect(
          (await service.evaluate(enforced: true)).unsafeInstaller,
          isFalse,
        );

        answer(() async => android(installer: null));
        expect(
          (await service.evaluate(enforced: true)).unsafeInstaller,
          isFalse,
        );

        answer(() async => android(installer: 'com.sideload.store'));
        expect(
          (await service.evaluate(enforced: true)).unsafeInstaller,
          isTrue,
        );
      },
    );

    test('checks the signature only against a configured allow-list', () async {
      answer(() async => android(signature: 'FF00'));

      final unchecked = await const AppDeviceIntegrityServiceImpl().evaluate(
        enforced: true,
      );
      final checked = await const AppDeviceIntegrityServiceImpl(
        signatureAllowList: {'AB12'},
      ).evaluate(enforced: true);

      expect(unchecked.signatureInvalid, isFalse);
      expect(checked.signatureInvalid, isTrue);
      expect(checked.isBlocked, isFalse);
    });

    test('lets the device through when the platform fails', () async {
      answer(() async => throw PlatformException(code: 'boom'));

      final verdict = await const AppDeviceIntegrityServiceImpl().evaluate(
        enforced: true,
      );

      expect(verdict.isBlocked, isFalse);
      expect(verdict.failureReason, 'security_error');
    });

    test('lets the device through on a platform without the plugin', () async {
      final verdict = await const AppDeviceIntegrityServiceImpl().evaluate(
        enforced: true,
      );

      expect(verdict.failureReason, 'security_error');
    });

    test('lets the device through when the platform is slow', () async {
      answer(() => Future.delayed(const Duration(seconds: 1), android));

      final verdict = await const AppDeviceIntegrityServiceImpl(
        timeout: Duration(milliseconds: 10),
      ).evaluate(enforced: true);

      expect(verdict.isBlocked, isFalse);
      expect(verdict.failureReason, 'security_timeout');
    });
  });

  test('the mock passes every device unless told otherwise', () async {
    final pass = await AppDeviceIntegrityServiceMock().evaluate(enforced: true);
    final block = await AppDeviceIntegrityServiceMock(
      verdict: (enforced) => .new(enforced: enforced, rooted: true),
    ).evaluate(enforced: true);

    expect(pass.isBlocked, isFalse);
    expect(block.isBlocked, isTrue);
  });
}
