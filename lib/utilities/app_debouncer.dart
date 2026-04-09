import 'package:flutter/foundation.dart';
import 'dart:async';

class AppDebouncer {
  final Duration delay;
  Timer? _timer;

  AppDebouncer(this.delay);

  bool get isActive => _timer?.isActive ?? false;

  run(VoidCallback action) {
    if (_timer != null) abort();
    _timer = Timer(delay, action);
  }

  void abort() {
    if (_timer == null) return;
    if (!_timer!.isActive) return;
    _timer!.cancel();
  }
}
