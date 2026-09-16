import 'package:flutter/foundation.dart';

/// {@category Data}
/// Tracks whether a [ChangeNotifier] has been disposed, so that writes
/// arriving after disposal (e.g. from a request that resolves after its
/// screen has closed) can be silently ignored instead of tripping the
/// "used after being disposed" assertion.
mixin DisposalAware on ChangeNotifier {
  bool _isDisposed = false;

  /// Whether [dispose] has already been called on this instance.
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// {@category Data}
/// A foundational state class that provides a standardized loading flag for ViewModels.
abstract class StateModel extends ChangeNotifier with DisposalAware {
  bool _isLoading = false;

  set isLoading(bool state) {
    if (isDisposed) return;
    _isLoading = state;
    notifyListeners();
  }

  get isLoading => _isLoading;

  reset() {
    if (isDisposed) return;
    _isLoading = false;
    notifyListeners();
  }
}
