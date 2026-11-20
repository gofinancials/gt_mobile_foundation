import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gt_device_integrity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Future<Object?> Function(MethodCall call) reply) {
    messenger.setMockMethodCallHandler(channel, reply);
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('AppDeviceAttestationServiceImpl', () {
    const service = AppDeviceAttestationServiceImpl(cloudProjectNumber: 42);

    test('passes the project number with every call', () async {
      final sent = <MethodCall>[];
      const reply = {'status': 'token', 'platform': 'android', 'token': 't'};

      const ready = {'status': 'ready'};

      answer((call) async {
        final isPrepare = call.method == 'prepareAttestation';
        sent.add(call);
        return isPrepare ? ready : reply;
      });

      await service.prepare();
      await service.attest(challenge: 'c');
      await service.token(data: 'd');

      final numbers = sent.map((call) => call.arguments['cloudProjectNumber']);
      final methods = sent.map((call) => call.method);

      expect(methods, ['prepareAttestation', 'attest', 'attestationToken']);
      expect(numbers, everyElement(42));
    });

    test('answers null from prepare when the platform is ready', () async {
      answer((_) async => {'status': 'ready'});

      final problem = await service.prepare();

      expect(problem, isNull);
    });

    test('returns the token the platform produced', () async {
      const reply = {'status': 'token', 'platform': 'ios', 'token': 't'};

      answer((_) async => {...reply, 'keyId': 'k'});

      final result = await service.attest(challenge: 'c');
      final token = result as GtAttestationToken;

      expect(token.token, 't');
      expect(token.keyId, 'k');
    });

    test('passes a platform problem through', () async {
      const reply = {'status': 'unavailable', 'reason': 'not_supported'};

      answer((_) async => reply);

      final result = await service.token(data: 'd');
      final problem = result as GtAttestationUnavailable;

      expect(problem.reason, 'not_supported');
    });

    test('answers unavailable on a platform without the plugin', () async {
      final result = await service.token(data: 'd');
      final problem = result as GtAttestationUnavailable;

      expect(problem.reason, 'missing_plugin');
    });

    test('answers failed when the platform throws', () async {
      answer((_) async => throw PlatformException(code: 'boom'));

      final result = await service.attest(challenge: 'c');
      final problem = result as GtAttestationFailed;

      expect(problem.reason, 'error');
    });

    test('answers failed when the platform is slow', () async {
      const timeout = Duration(milliseconds: 10);
      const slow = AppDeviceAttestationServiceImpl(timeout: timeout);
      const delay = Duration(seconds: 1);

      answer((_) => Future.delayed(delay, () => {'status': 'ready'}));

      final problem = await slow.prepare();

      expect(problem, isA<GtAttestationFailed>());
      expect(problem?.reason, 'timeout');
    });
  });

  group('AppDeviceAttestationServiceMock', () {
    test('answers a fake token unless told otherwise', () async {
      final fake = AppDeviceAttestationServiceMock();
      final failing = AppDeviceAttestationServiceMock(
        result: (_) => const GtAttestationFailed('network_error'),
      );

      final token = await fake.token(data: 'd') as GtAttestationToken;
      final problem = await failing.attest(challenge: 'c');

      expect(await fake.prepare(), isNull);
      expect(token.token, 'mock-assertion:d');
      expect(problem, isA<GtAttestationFailed>());
    });
  });
}
