import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Composite Analytics Architecture Tests', () {
    late MockAnalyticsAdapter provider1;
    late MockAnalyticsAdapter provider2;
    late AppAnalyticsServiceImpl compositeService;

    setUp(() {
      provider1 = MockAnalyticsAdapter();
      provider2 = MockAnalyticsAdapter();
      compositeService = AppAnalyticsServiceImpl([provider1, provider2]);
    });

    test('initialize broadcasts to all providers', () async {
      await compositeService.initialize();
      expect(compositeService.providers.length, equals(2));
    });

    test(
      'identifyUser broadcasts user details to all registered providers',
      () async {
        await compositeService.identifyUser(
          id: 'user_123',
          accountNumber: '0123456789',
          name: 'John Doe',
        );

        expect(provider1.identifiedUserId, equals('user_123'));
        expect(provider2.identifiedUserId, equals('user_123'));
      },
    );

    test(
      'trackEvent broadcasts predefined event data to all registered providers',
      () async {
        final eventData = AppAnalyticsData(
          AppEvent.transferCompleted,
          description: 'Funds transfer',
          value: 500,
        );

        await compositeService.trackEvent(eventData);

        expect(provider1.trackedEvents.length, equals(1));
        expect(
          provider1.trackedEvents.first.event,
          equals(AppEvent.transferCompleted),
        );
        expect(provider2.trackedEvents.length, equals(1));
        expect(provider2.trackedEvents.first.value, equals(500));
      },
    );

    test('trackEvent supports PDF specified events', () async {
      final onboardingData = AppAnalyticsData(
        AppEvent.newUserConfirmPhoneNumber,
      );
      final transferData = AppAnalyticsData(.userTransferStart);
      final fxData = AppAnalyticsData(.userFXSwapSuccessful);

      await compositeService.trackEvent(onboardingData);
      await compositeService.trackEvent(transferData);
      await compositeService.trackEvent(fxData);

      expect(
        provider1.trackedEvents.map((e) => e.event.name),
        containsAll([
          'NewUser_cofirmPhonenumber',
          'user_Transfer_Start',
          'user_FXSwap_Successful',
        ]),
      );
    });

    test('trackEvent supports custom host application events', () async {
      final customEvent = AppEvent('custom_host_app_feature_clicked');
      final eventData = AppAnalyticsData(customEvent, value: 'custom_data');

      await compositeService.trackEvent(eventData);

      expect(
        provider1.trackedEvents.last.event,
        equals(AppEvent('custom_host_app_feature_clicked')),
      );
      expect(
        provider2.trackedEvents.last.event.name,
        equals('custom_host_app_feature_clicked'),
      );
    });

    test('AppEvent supports network events', () {
      expect(AppEvent.apiRequest.name, equals('API REQUEST'));
      expect(AppEvent.apiResponse.name, equals('API RESPONSE'));
      expect(AppEvent.apiError.name, equals('API ERROR'));
    });

    test('AppEvent equality and value representation', () {
      final eventA = AppEvent('my_event');
      final eventB = AppEvent('my_event');
      final eventC = AppEvent('other_event');

      expect(eventA, equals(eventB));
      expect(eventA == eventC, isFalse);
      expect(eventA.value, equals('my_event'));
      expect(eventA.toString(), equals('my_event'));
    });

    test(
      'trackNavigation broadcasts path to all registered providers',
      () async {
        await compositeService.trackNavigation(
          '/dashboard',
          widgetClass: 'DashboardPage',
        );

        expect(provider1.trackedNavigations, contains('/dashboard'));
        expect(provider2.trackedNavigations, contains('/dashboard'));
      },
    );

    test(
      'addProvider and removeProvider dynamically modify provider set',
      () async {
        final provider3 = MockAnalyticsAdapter();

        compositeService.addProvider(provider3);
        expect(compositeService.providers.length, equals(3));

        await compositeService.trackNavigation('/settings');
        expect(provider3.trackedNavigations, contains('/settings'));

        compositeService.removeProvider(provider3);
        expect(compositeService.providers.length, equals(2));
      },
    );
  });
}
