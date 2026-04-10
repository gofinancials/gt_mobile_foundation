import 'package:gt_mobile_foundation/foundation.dart';

class BiometricAuthServiceMock implements BiometricAuthService {
  @override
  Future<bool> authenticate({required String title}) async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> hasBioCapabilities() async {
    return AppHelpers.randomBool;
  }
}
