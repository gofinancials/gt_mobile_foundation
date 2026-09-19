import 'package:gt_mobile_foundation/foundation.dart';

/// A mock implementation of [AnalyticsProvider] for testing and fallback environments.
class MockAnalyticsAdapter implements AnalyticsProvider {
  final List<AppAnalyticsData> trackedEvents = [];
  final List<String> trackedNavigations = [];
  dynamic identifiedUserId;
  String? identifiedFirstName;
  String? identifiedLastName;
  bool resetUserCalled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? telephone,
    String? bvn,
  }) async {
    identifiedUserId = id;
    identifiedFirstName = firstName;
    identifiedLastName = lastName;
  }

  @override
  Future<void> resetUser() async {
    resetUserCalled = true;
    identifiedUserId = null;
    identifiedFirstName = null;
    identifiedLastName = null;
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
