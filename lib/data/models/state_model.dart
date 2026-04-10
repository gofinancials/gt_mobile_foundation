import 'package:flutter/foundation.dart';

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
