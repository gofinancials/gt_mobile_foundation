import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class AppFcmMockService implements AppPushNotificationService<String> {
  @override
  Future<String?> get token async => "mock-token";

  @override
  Future<String?> getInitialMessage() async {
    return "Mock Message Body";
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
