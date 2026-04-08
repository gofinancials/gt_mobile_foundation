import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthServiceImpl implements BiometricAuthService {
  static bool? _hasBioCapabilities;
  late final LocalAuthentication _auth = LocalAuthentication();

  BiometricAuthServiceImpl();

  @override
  Future<bool> authenticate({required String title}) async {
    try {
      if (!await hasBioCapabilities()) return false;

      return await _auth.authenticate(
        localizedReason: title,
        options: const AuthenticationOptions(
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return false;
    }
  }

  @override
  Future<bool> hasBioCapabilities() async {
    try {
      if (_hasBioCapabilities != null) return _hasBioCapabilities!;
      return _auth.isDeviceSupported();
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return false;
    }
  }
}
