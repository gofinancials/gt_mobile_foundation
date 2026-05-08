/// {@category Services}
/// Defines the core interface for handling push notifications.
abstract class AppPushNotificationService<T> {
  /// The device-specific token for push notifications.
  Future<String?> get token;

  /// Initializes the messaging service to start receiving notifications.
  Future<void> initialiseMessaging();

  /// Disables the messaging service.
  Future<void> disableMessaging();

  /// Subscribes the device to the specified [topic].
  Future<void> watchTopic({required String topic});

  /// Unsubscribes the device from the specified [topic].
  Future<void> unwatchTopic({required String topic});

  /// Retrieves the initial message that caused the app to open from a terminated state.
  Future<T?> getInitialMessage();
}
