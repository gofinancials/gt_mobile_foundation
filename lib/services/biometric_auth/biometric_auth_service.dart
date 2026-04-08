abstract class BiometricAuthService {
  Future<bool> authenticate({required String title});
  Future<bool> hasBioCapabilities();
}
