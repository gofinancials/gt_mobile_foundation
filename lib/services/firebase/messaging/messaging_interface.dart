import 'package:firebase_messaging/firebase_messaging.dart';

abstract class AppFcmService {
  Future<String?> get token;
  Future<void> initialiseMessaging();
  Future<void> disableMessaging();
  Future<void> watchTopic({required String topic});
  Future<void> unwatchTopic({required String topic});
  Future<RemoteMessage?> getInitialMessage();
}
