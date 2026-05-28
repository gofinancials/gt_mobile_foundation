import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Services}
/// A mock implementation of [AppAnalyticsService] for testing purposes.
class AppAnalyticsMockService implements AppAnalyticsService {
  @override
  identifyUser({
    required id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  }) async {}

  @override
  trackEvent(AppAnalyticsData eventData) async {}

  @override
  RouteObserver? get navigatorObserver => RouteObserver();

  @override
  trackNavigation(
    String path, {
    String? widgetClass,
    Map<String, Object?>? arguments,
  }) {}
}
