/// {@category Services}
/// The interface definition for biometric authentication services.
abstract class BiometricAuthService {
  /// Authenticates the user with biometrics, displaying the provided [title].
  /// Returns `true` if authentication is successful, `false` otherwise.
  Future<bool> authenticate({required String title});

  /// Checks whether the device supports and has biometric capabilities enabled.
  Future<bool> hasBioCapabilities();
}
