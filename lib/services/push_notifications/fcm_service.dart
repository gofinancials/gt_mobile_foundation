import 'dart:ui' show PluginUtilities;

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

  /// Whether [initialiseMessaging] does nothing in debug builds.
  ///
  /// Defaults to `false`, so push notifications can be tested in development.
  final bool skipInDebug;

  /// Whether to request provisional permission on iOS instead of prompting the user.
  ///
  /// Provisional permission is granted without a prompt, and notifications are
  /// delivered quietly to Notification Center, with no banner or sound, until the
  /// user chooses otherwise. Defaults to `false`, which shows the permission prompt.
  /// Ignored on Android.
  final bool provisional;

  /// Handles messages received while the app is in the background or terminated.
  ///
  /// On Android this runs in a separate isolate that can't reach this service or
  /// the app's dependency injection, so it must be a top-level or static function
  /// annotated with `@pragma('vm:entry-point')`. Initialise Firebase inside it
  /// before using other Firebase services:
  ///
  /// ```dart
  /// @pragma('vm:entry-point')
  /// Future<void> onBackgroundMessage(RemoteMessage message) async {
  ///   await Firebase.initializeApp();
  ///   // Handle the message.
  /// }
  /// ```
  ///
  /// When `null`, no background handler is registered. The system still shows
  /// notification messages, and tapping one still opens the app.
  final BackgroundMessageHandler? onBackgroundMessage;

  bool _listenersBound = false;

  /// Creates a new instance of the FCM service.
  ///
  /// Requires an [_crashlyticsService] for logging non-fatal errors, and an
  /// [_navigateTo] callback function to handle routing when notifications are opened.
  AppFcmServiceImpl(
    this._crashlyticsService,
    this._navigateTo, {
    this.skipInDebug = false,
    this.provisional = false,
    this.onBackgroundMessage,
  });

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

  /// Binds message listeners and requests notification permission.
  ///
  /// The first call binds handlers for foreground messages, notification taps and,
  /// if [onBackgroundMessage] is set, background messages. They are bound whatever
  /// permission the user grants, since permission only controls whether
  /// notifications are shown. Every call requests permission, as set by
  /// [provisional]; once the user has answered, this returns the current status
  /// without prompting again.
  ///
  /// Does nothing in debug builds when [skipInDebug] is `true`.
  @override
  Future<void> initialiseMessaging() async {
    if (skipInDebug && kDebugMode) return;
    // Bind before awaiting permission so a failed request can't skip it. The
    // native events only reach these streams once FirebaseMessaging.instance is
    // used, which requestPermission does synchronously below.
    _bindListeners();
    try {
      final settings = await _fcm.requestPermission(provisional: provisional);
      AppLogger.info("FCM PERMISSION: ${settings.authorizationStatus}");
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  void _bindListeners() {
    if (_listenersBound) return;
    _listenersBound = true;
    try {
      FirebaseMessaging.onMessage.listen(_onMessageReceived);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _onMessageReceived(message, canNavigate: true),
      );
      _registerBackgroundHandler();
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  void _registerBackgroundHandler() {
    final handler = onBackgroundMessage;
    if (handler == null) return;
    // On Android, FlutterFire looks the handler up by callback handle. Without
    // one it throws asynchronously, where no try/catch here can reach it.
    if (PluginUtilities.getCallbackHandle(handler) == null) {
      throw ArgumentError.value(
        handler,
        "onBackgroundMessage",
        "Must be a top-level or static function annotated with "
            "@pragma('vm:entry-point')",
      );
    }
    FirebaseMessaging.onBackgroundMessage(handler);
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
      await _fcm.unsubscribeFromTopic(topic);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Subscribes the device to a specific FCM broadcast [topic] to receive group notifications.
  @override
  Future<void> watchTopic({required String topic}) async {
    try {
      await _fcm.subscribeToTopic(topic);
    } catch (e, t) {
      _reportError(e, t);
    }
  }
}
