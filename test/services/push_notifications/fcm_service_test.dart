import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

@pragma('vm:entry-point')
Future<void> _topLevelHandler(RemoteMessage message) async {}

class _Handlers {
  @pragma('vm:entry-point')
  static Future<void> staticHandler(RemoteMessage message) async {}

  Future<void> instanceHandler(RemoteMessage message) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMessagingPlatform platform;
  late _RecordingCrashlytics crashlytics;
  late List<String> routes;

  // FirebaseMessaging.instance captures FirebaseMessagingPlatform.instance on
  // first access, so the fake must be installed before anything touches it.
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    platform = _FakeMessagingPlatform();
    FirebaseMessagingPlatform.instance = platform;
  });

  // The message streams are process-wide, so listeners bound by earlier tests
  // stay alive. Each test records into its own lists to stay unaffected.
  setUp(() {
    platform.reset();
    crashlytics = _RecordingCrashlytics();
    routes = [];
  });

  tearDown(() => FirebaseMessagingPlatform.onBackgroundMessage = null);

  AppFcmServiceImpl createService({
    bool skipInDebug = false,
    bool provisional = false,
    BackgroundMessageHandler? onBackgroundMessage,
  }) {
    // Capture this test's list; the closure outlives the test.
    final recorded = routes;
    return AppFcmServiceImpl(
      crashlytics,
      (String route, {BuildContext? context, Object? arguments}) =>
          recorded.add(route),
      skipInDebug: skipInDebug,
      provisional: provisional,
      onBackgroundMessage: onBackgroundMessage,
    );
  }

  Future<void> tap(String link) async {
    FirebaseMessagingPlatform.onMessageOpenedApp.add(
      RemoteMessage(data: {'link': link}),
    );
    await pumpEventQueue();
  }

  group('AppFcmServiceImpl.initialiseMessaging', () {
    test('runs in debug builds by default', () async {
      await createService().initialiseMessaging();

      expect(platform.permissionRequests, 1);
      await tap('/home');
      expect(routes, ['/home']);
    });

    test('does nothing in debug builds when skipInDebug is set', () async {
      await createService(
        skipInDebug: true,
        onBackgroundMessage: _topLevelHandler,
      ).initialiseMessaging();

      expect(platform.permissionRequests, 0);
      expect(platform.backgroundHandler, isNull);
      await tap('/home');
      expect(routes, isEmpty);
    });

    test('prompts for permission by default', () async {
      await createService().initialiseMessaging();

      expect(platform.lastProvisional, isFalse);
    });

    test('requests provisional permission when configured', () async {
      await createService(provisional: true).initialiseMessaging();

      expect(platform.lastProvisional, isTrue);
    });

    for (final status in AuthorizationStatus.values) {
      test('binds tap navigation when permission is ${status.name}', () async {
        platform.status = status;

        await createService().initialiseMessaging();
        await tap('/offers');

        expect(routes, ['/offers']);
      });
    }

    test('binds listeners when requesting permission throws', () async {
      platform.permissionError = FirebaseException(
        plugin: 'firebase_messaging',
        code: 'apns-token-not-set',
      );

      await createService().initialiseMessaging();
      await tap('/offers');

      expect(routes, ['/offers']);
      expect(crashlytics.errors, [platform.permissionError]);
    });

    test('does not navigate for foreground messages', () async {
      await createService().initialiseMessaging();

      FirebaseMessagingPlatform.onMessage.add(
        const RemoteMessage(data: {'link': '/offers'}),
      );
      await pumpEventQueue();

      expect(routes, isEmpty);
    });

    test('binds listeners once across repeated calls', () async {
      final service = createService();

      await service.initialiseMessaging();
      await service.initialiseMessaging();
      await tap('/offers');

      expect(routes, ['/offers']);
      expect(platform.permissionRequests, 2);
    });

    test('registers no background handler by default', () async {
      await createService().initialiseMessaging();

      expect(platform.backgroundHandler, isNull);
    });

    test('registers a top-level background handler', () async {
      await createService(
        onBackgroundMessage: _topLevelHandler,
      ).initialiseMessaging();

      expect(platform.backgroundHandler, same(_topLevelHandler));
      expect(crashlytics.errors, isEmpty);
    });

    test('registers a static background handler', () async {
      await createService(
        onBackgroundMessage: _Handlers.staticHandler,
      ).initialiseMessaging();

      expect(platform.backgroundHandler, same(_Handlers.staticHandler));
      expect(crashlytics.errors, isEmpty);
    });

    test('reports a background handler without a callback handle', () async {
      await createService(
        onBackgroundMessage: _Handlers().instanceHandler,
      ).initialiseMessaging();

      expect(platform.backgroundHandler, isNull);
      expect(crashlytics.errors, [isA<ArgumentError>()]);
      await tap('/offers');
      expect(routes, ['/offers']);
    });
  });

  group('AppFcmServiceImpl topics', () {
    final error = FirebaseException(
      plugin: 'firebase_messaging',
      code: 'apns-token-not-set',
    );

    test('watchTopic reports subscription errors', () async {
      platform.topicError = error;

      await createService().watchTopic(topic: 'offers');

      expect(crashlytics.errors, [error]);
    });

    test('unwatchTopic reports unsubscription errors', () async {
      platform.topicError = error;

      await createService().unwatchTopic(topic: 'offers');

      expect(crashlytics.errors, [error]);
    });
  });
}

class _RecordingCrashlytics implements AppCrashlyticsService {
  final errors = <Object?>[];

  @override
  Future<void> init() async {}

  @override
  trackError(
    String message, {
    Object? error,
    StackTrace? trace,
    bool fatal = false,
  }) {
    errors.add(error);
  }

  @override
  identifyUser({
    required dynamic id,
    required String accountNumber,
    String? name,
  }) {}
}

class _FakeMessagingPlatform extends FirebaseMessagingPlatform
    with MockPlatformInterfaceMixin {
  AuthorizationStatus status = AuthorizationStatus.authorized;
  Object? permissionError;
  Object? topicError;
  int permissionRequests = 0;
  bool? lastProvisional;
  BackgroundMessageHandler? backgroundHandler;

  void reset() {
    status = AuthorizationStatus.authorized;
    permissionError = null;
    topicError = null;
    permissionRequests = 0;
    lastProvisional = null;
    backgroundHandler = null;
  }

  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) => this;

  @override
  void registerBackgroundMessageHandler(BackgroundMessageHandler handler) {
    backgroundHandler = handler;
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    permissionRequests++;
    lastProvisional = provisional;
    if (permissionError case final error?) throw error;
    return NotificationSettings(
      authorizationStatus: status,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (topicError case final error?) throw error;
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (topicError case final error?) throw error;
  }
}
