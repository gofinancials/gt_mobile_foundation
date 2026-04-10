import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

class AppAnalyticsMockService implements AppAnalyticsService {
  @override
  identifyUser({required id, required String email, String? name}) async {}

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
