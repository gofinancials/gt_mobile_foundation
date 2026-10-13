import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<UserAccelerometerEvent> events;
  late ValueNotifier<bool> enabled;
  late DateTime now;
  late int shakes;
  late AppShakeDetector detector;

  setUp(() {
    events = StreamController.broadcast();
    enabled = ValueNotifier(true);
    now = DateTime(2026, 10, 13, 12);
    shakes = 0;
    detector = AppShakeDetector(
      enabled: enabled,
      onShake: () => shakes++,
      events: () => events.stream,
      clock: () => now,
    )..attach();
  });

  tearDown(() {
    detector.dispose();
    events.close();
    enabled.dispose();
  });

  /// A reading of [force] m/s², [after] the previous one.
  Future<void> jolt({double force = 18, int after = 200}) async {
    now = now.add(Duration(milliseconds: after));
    events.add(UserAccelerometerEvent(force, 0, 0, now));
    await Future<void>.delayed(Duration.zero);
  }

  test('two jolts within a second are a shake', () async {
    await jolt();
    expect(shakes, 0);

    await jolt();
    expect(shakes, 1);
  });

  test('readings under 17 m/s² are not jolts', () async {
    await jolt(force: 16.9);
    await jolt(force: 16.9);

    expect(shakes, 0);
  });

  test('jolts closer than 150 ms count once', () async {
    await jolt();
    await jolt(after: 100);
    expect(shakes, 0);

    await jolt(after: 100);
    expect(shakes, 1);
  });

  test('jolts more than a second apart are not a shake', () async {
    await jolt();
    await jolt(after: 1100);

    expect(shakes, 0);
  });

  test('rests for a second after a shake', () async {
    await jolt();
    await jolt();
    await jolt();
    await jolt();
    expect(shakes, 1);

    await jolt(after: 1000);
    await jolt();
    expect(shakes, 2);
  });

  test('reads the accelerometer only while the setting is on', () async {
    expect(detector.isListening, isTrue);

    enabled.value = false;
    expect(detector.isListening, isFalse);
    await jolt();
    await jolt();
    expect(shakes, 0);

    enabled.value = true;
    expect(detector.isListening, isTrue);
  });

  test('stops in the background and resumes in the foreground', () {
    final binding = TestWidgetsFlutterBinding.instance;

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(detector.isListening, isFalse);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(detector.isListening, isTrue);
  });

  test('a sensor error stops it without throwing', () async {
    events.addError(PlatformException(code: 'NO_SENSOR'));
    await Future<void>.delayed(Duration.zero);

    expect(detector.isListening, isFalse);
  });

  test('dispose stops it for good', () {
    detector.dispose();
    enabled.value = false;
    enabled.value = true;

    expect(detector.isListening, isFalse);
  });
}
