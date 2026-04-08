import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class AppFirebaseConfigImpl implements AppFirebaseConfig {
  FirebaseOptions confugurationOptions;

  AppFirebaseConfigImpl(this.confugurationOptions);

  @override
  Future<void> init() async {
    await Firebase.initializeApp(options: confugurationOptions);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidPlayIntegrityProvider(),
      providerApple: AppleAppAttestProvider(),
    );
  }
}
