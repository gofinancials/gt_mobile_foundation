import 'package:gt_mobile_foundation/foundation.dart';

/// A mock implementation of [AnalyticsProvider] for testing and fallback environments.
class MockAnalyticsAdapter implements AnalyticsProvider {
  final List<AppAnalyticsData> trackedEvents = [];
  final List<String> trackedNavigations = [];
  dynamic identifiedUserId;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  }) async {
    identifiedUserId = id;
  }

  @override
  Future<void> trackEvent(AppAnalyticsData eventData) async {
    trackedEvents.add(eventData);
  }

  @override
  Future<void> trackNavigation(String path, {String? widgetClass}) async {
    trackedNavigations.add(path);
  }
}
