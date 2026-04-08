import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppFcmServiceImpl implements AppFcmService {
  final AppCrashlyticsService _crashlyticsService;
  final OnNavigate _navigateTo;

  AppFcmServiceImpl(this._crashlyticsService, this._navigateTo);

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  _reportError(Object e, StackTrace t) {
    _crashlyticsService.trackError("$e", error: e, trace: t);
  }

  @override
  Future<String?> get token async {
    try {
      return await _fcm.getToken();
    } catch (e, t) {
      _reportError(e, t);
      return null;
    }
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    return await _fcm.getInitialMessage();
  }

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

  @override
  Future<void> disableMessaging() async {
    try {
      await _fcm.deleteToken();
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  Future<void> _onMessageReceived(
    RemoteMessage message, {
    bool canNavigate = false,
  }) async {
    AppLogger.info(
      "FCM MESSAGE RECEIVED: ${message.messageId}, DATA: ${message.data}, Notification: ${message.notification}, CanNavigate: $canNavigate",
    );
    if (!canNavigate) return;
    final data = message.data;
    if (!data.containsKey("link")) return;
    final link = data["link"];
    if (link is! String || !link.hasValue) return;
    _navigateTo(link);
  }

  @override
  Future<void> unwatchTopic({required String topic}) async {
    try {
      _fcm.unsubscribeFromTopic(topic);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  @override
  Future<void> watchTopic({required String topic}) async {
    try {
      _fcm.subscribeToTopic(topic);
    } catch (e, t) {
      _reportError(e, t);
    }
  }
}
