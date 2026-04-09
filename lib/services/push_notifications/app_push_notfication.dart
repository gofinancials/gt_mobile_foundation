abstract class AppPushNotificationService<T> {
  Future<String?> get token;
  Future<void> initialiseMessaging();
  Future<void> disableMessaging();
  Future<void> watchTopic({required String topic});
  Future<void> unwatchTopic({required String topic});
  Future<T?> getInitialMessage();
}
