import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// A configuration service that handles the initialization of Firebase services.
///
/// This class encapsulates the setup process for Firebase, including configuring
/// the core app options and activating [FirebaseAppCheck] for security verification
/// using platform-specific providers (Play Integrity for Android, App Attest for Apple).
class AppFirebaseConfigImpl {
  /// The specific options required to initialize the Firebase application.
  final FirebaseOptions configurationOptions;

  /// Creates a new configuration instance with the provided [configurationOptions].
  AppFirebaseConfigImpl(this.configurationOptions);

  /// Initializes the Firebase app and activates the App Check provider.
  ///
  /// This should typically be called during the application startup process before
  /// any other Firebase services are accessed.
  Future<void> init() async {
    await Firebase.initializeApp(options: configurationOptions);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidPlayIntegrityProvider(),
      providerApple: AppleAppAttestProvider(),
    );
  }
}
