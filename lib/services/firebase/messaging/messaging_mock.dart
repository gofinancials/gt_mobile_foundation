import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppFcmMockService implements AppFcmService {
  @override
  Future<String?> get token async => "mock-token";

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    return const RemoteMessage(
      notification: RemoteNotification(
        title: "Mock Message",
        body: "Mock Message Body",
      ),
    );
  }

  @override
  Future<void> initialiseMessaging() async {}

  @override
  Future<void> disableMessaging() async {}

  @override
  Future<void> unwatchTopic({required String topic}) async {}

  @override
  Future<void> watchTopic({required String topic}) async {}
}
