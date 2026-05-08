import 'package:flutter/foundation.dart';

/// {@category Data}
/// A foundational state class that provides a standardized loading flag for ViewModels.
abstract class StateModel extends ChangeNotifier {
  bool _isLoading = false;

  set isLoading(bool state) {
    _isLoading = state;
    notifyListeners();
  }

  get isLoading => _isLoading;

  reset() {
    _isLoading = false;
    notifyListeners();
  }
}
