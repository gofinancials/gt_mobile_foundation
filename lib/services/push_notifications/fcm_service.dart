import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// An implementation of [AppPushNotificationService] using Firebase Cloud Messaging (FCM).
///
/// This service handles the initialization of push notifications, retrieving FCM tokens,
/// managing topic subscriptions, and processing incoming messages (both in the foreground
/// and background). It leverages an injected [OnNavigate] callback to automatically route
/// users when they tap on a notification containing a deep link.
class AppFcmServiceImpl implements AppPushNotificationService {
  final AppCrashlyticsService _crashlyticsService;
  final OnNavigate _navigateTo;

  /// Creates a new instance of the FCM service.
  ///
  /// Requires an [_crashlyticsService] for logging non-fatal errors, and an
  /// [_navigateTo] callback function to handle routing when notifications are opened.
  AppFcmServiceImpl(this._crashlyticsService, this._navigateTo);

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  _reportError(Object e, StackTrace t) {
    _crashlyticsService.trackError("$e", error: e, trace: t);
  }

  /// Retrieves the unique Firebase Cloud Messaging token for this device.
  ///
  /// This token is used by the backend to target push notifications specifically
  /// to this installation of the app. Returns `null` if the token cannot be fetched.
  @override
  Future<String?> get token async {
    try {
      return await _fcm.getToken();
    } catch (e, t) {
      _reportError(e, t);
      return null;
    }
  }

  /// Retrieves the initial message that caused the application to open from a terminated state.
  ///
  /// This is useful for handling deep links or specific routing instructions immediately
  /// upon app startup if the user launched the app by tapping a notification.
  @override
  Future<RemoteMessage?> getInitialMessage() async {
    return await _fcm.getInitialMessage();
  }

  /// Requests notification permissions and initializes message listeners.
  ///
  /// In debug mode, this setup is skipped to prevent unnecessary background processing.
  /// In release, it requests provisional permissions and, if granted, binds handlers
  /// for foreground messages, background messages, and app-open events.
  @override
  Future<void> initialiseMessaging() async {
    if (kDebugMode) return;
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        provisional: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onBackgroundMessage(_onMessageReceived);
        FirebaseMessaging.onMessage.listen(_onMessageReceived);
        FirebaseMessaging.onMessageOpenedApp.listen(
          (message) => _onMessageReceived(message, canNavigate: true),
        );
      }
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Deletes the current FCM token, effectively opting the device out of targeted notifications.
  ///
  /// This is typically called when a user logs out or disables notifications from settings.
  @override
  Future<void> disableMessaging() async {
    try {
      await _fcm.deleteToken();
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Internal handler for processing incoming [RemoteMessage]s.
  ///
  /// Logs the incoming payload. If [canNavigate] is `true` (e.g., the user tapped
  /// the notification) and the payload contains a valid `link` string, the service
  /// triggers the [_navigateTo] callback to route the user appropriately.
  Future<void> _onMessageReceived(
    RemoteMessage message, {
    bool canNavigate = false,
  }) async {
    AppLogger.info(
      "FCM MESSAGE RECEIVED: ${message.messageId}, DATA: ${message.data}",
    );
    if (!canNavigate) return;
    final data = message.data;
    if (!data.containsKey("link")) return;
    final link = data["link"];
    if (link is! String || !link.hasValue) return;
    _navigateTo(link);
  }

  /// Unsubscribes the device from a specific FCM broadcast [topic].
  @override
  Future<void> unwatchTopic({required String topic}) async {
    try {
      _fcm.unsubscribeFromTopic(topic);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Subscribes the device to a specific FCM broadcast [topic] to receive group notifications.
  @override
  Future<void> watchTopic({required String topic}) async {
    try {
      _fcm.subscribeToTopic(topic);
    } catch (e, t) {
      _reportError(e, t);
    }
  }
}
