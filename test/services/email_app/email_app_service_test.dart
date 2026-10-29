import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('open_mail_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const service = AppEmailAppServiceImpl();

  void answer(Object? Function(MethodCall call) reply) {
    messenger.setMockMethodCallHandler(channel, (call) async => reply(call));
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('emailApps', () {
    test('lists the mail apps on the device', () async {
      answer(
        (_) => [
          {'id': 'com.google.android.gm', 'name': 'Gmail'},
          {'id': 'com.microsoft.office.outlook', 'name': 'Outlook'},
        ],
      );

      final apps = await service.emailApps();

      expect(apps.map((app) => app.id), [
        'com.google.android.gm',
        'com.microsoft.office.outlook',
      ]);
      expect(apps.map((app) => app.name), ['Gmail', 'Outlook']);
    });

    test(
      'leaves out the iOS default entry, which opens a new message',
      () async {
        answer(
          (_) => [
            {'id': 'mailto:', 'name': 'Default Mail App', 'isDefault': true},
            {'id': 'message://', 'name': 'Mail'},
          ],
        );

        final apps = await service.emailApps();

        expect(apps.map((app) => app.id), ['message://']);
      },
    );

    test('is empty when the device has no mail app', () async {
      answer((_) => const []);

      expect(await service.emailApps(), isEmpty);
    });

    test('is empty when the platform fails', () async {
      answer((_) => throw PlatformException(code: 'boom'));

      expect(await service.emailApps(), isEmpty);
    });

    test('is empty on a platform without the plugin', () async {
      expect(await service.emailApps(), isEmpty);
    });
  });

  group('open', () {
    const gmail = AppEmailApp(id: 'com.google.android.gm', name: 'Gmail');

    test('opens the app at its inbox, with no message to compose', () async {
      MethodCall? sent;
      answer((call) {
        sent = call;
        return true;
      });

      expect(await service.open(gmail), isTrue);
      expect(sent?.method, 'openSpecificMailApp');
      expect(sent?.arguments, {'appId': 'com.google.android.gm'});
    });

    test('is false when the app did not open', () async {
      answer((_) => false);

      expect(await service.open(gmail), isFalse);
    });

    test('is false when the platform fails', () async {
      answer((_) => throw PlatformException(code: 'boom'));

      expect(await service.open(gmail), isFalse);
    });

    test('is false on a platform without the plugin', () async {
      expect(await service.open(gmail), isFalse);
    });
  });
}
