import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// {@category Services}
/// Calls [onShake] when the device is shaken, for shake-to-hide.
///
/// The accelerometer is read only while [enabled] is true and the app is in
/// the foreground. Call [attach] once its owner is mounted and [dispose] when
/// it goes. The thresholds are NewMobileChannel's: a jolt is at least 17 m/s²
/// with gravity removed, a shake is two jolts at least 150 ms apart within one
/// second, and a shake is followed by a one-second rest.
///
/// A shake should only ever hide; revealing still takes a deliberate tap.
/// Haptic feedback, if wanted, belongs in [onShake].
class AppShakeDetector {
  /// Creates a detector. [events] and [clock] exist for tests; they default to
  /// the device's user accelerometer and [DateTime.now].
  AppShakeDetector({
    required this.enabled,
    required this.onShake,
    Stream<UserAccelerometerEvent> Function()? events,
    DateTime Function()? clock,
  }) : _events = events ?? _accelerometer,
       _clock = clock ?? DateTime.now;

  /// The shake-to-hide setting.
  final ValueListenable<bool> enabled;

  /// What a shake does.
  final VoidCallback onShake;

  final Stream<UserAccelerometerEvent> Function() _events;
  final DateTime Function() _clock;

  static const double _joltThreshold = 17;
  static const int _joltsPerShake = 2;
  static const Duration _minJoltGap = Duration(milliseconds: 150);
  static const Duration _shakeWindow = Duration(seconds: 1);
  static const Duration _cooldown = Duration(seconds: 1);

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  AppLifecycleListener? _lifecycle;
  final List<DateTime> _jolts = [];
  DateTime? _lastShake;

  /// Whether the accelerometer is being read now.
  bool get isListening => _subscription != null;

  /// Starts following [enabled] and the app lifecycle.
  void attach() {
    if (_lifecycle != null) return;
    enabled.addListener(_sync);
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _sync());
    _sync();
  }

  /// Stops listening for good.
  void dispose() {
    enabled.removeListener(_sync);
    _lifecycle?.dispose();
    _lifecycle = null;
    _stop();
  }

  static Stream<UserAccelerometerEvent> _accelerometer() {
    return userAccelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    );
  }

  void _sync() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final foreground = lifecycle == null || lifecycle == .resumed;
    if (enabled.value && foreground) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_subscription != null) return;
    try {
      _subscription = _events().listen(
        _onEvent,
        onError: (_) => _stop(),
        cancelOnError: true,
      );
    } catch (_) {
      // No accelerometer on this device.
      _subscription = null;
    }
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    _jolts.clear();
  }

  void _onEvent(UserAccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < _joltThreshold) return;

    final now = _clock();
    final lastShake = _lastShake;
    if (lastShake != null && now.difference(lastShake) < _cooldown) return;
    if (_jolts.isNotEmpty && now.difference(_jolts.last) < _minJoltGap) return;

    _jolts
      ..removeWhere((jolt) => now.difference(jolt) > _shakeWindow)
      ..add(now);
    if (_jolts.length < _joltsPerShake) return;

    _jolts.clear();
    _lastShake = now;
    onShake();
  }
}
