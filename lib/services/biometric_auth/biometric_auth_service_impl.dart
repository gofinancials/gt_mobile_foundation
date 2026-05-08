import 'package:gt_mobile_foundation/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// {@category Services}
/// The standard implementation of [BiometricAuthService] utilizing the
/// `local_auth` package for device-level biometrics.
class BiometricAuthServiceImpl implements BiometricAuthService {
  /// Cached value representing if the device has biometric capabilities.
  static bool? _hasBioCapabilities;

  /// The local authentication instance.
  late final LocalAuthentication _auth = LocalAuthentication();

  /// Creates a new instance of [BiometricAuthServiceImpl].
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
