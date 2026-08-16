import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock implementation of [AppAnalyticsService] for testing purposes.
class AppAnalyticsMockService implements AppAnalyticsService {
  final MockAnalyticsAdapter mockAdapter = MockAnalyticsAdapter();

  @override
  Future<void> initialize() async {
    await mockAdapter.initialize();
  }

  @override
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  }) async {
    await mockAdapter.identifyUser(
      id: id,
      accountNumber: accountNumber,
      name: name,
      email: email,
      telephone: telephone,
      bvn: bvn,
    );
  }

  @override
  Future<void> trackEvent(AppAnalyticsData eventData) async {
    await mockAdapter.trackEvent(eventData);
  }

  @override
  Future<void> trackNavigation(String path, {String? widgetClass}) async {
    await mockAdapter.trackNavigation(path, widgetClass: widgetClass);
  }

  @override
  void addProvider(AnalyticsProvider provider) {}

  @override
  void removeProvider(AnalyticsProvider provider) {}
}
