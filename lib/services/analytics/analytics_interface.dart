import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppAnalyticsService {
  identifyUser({required dynamic id, required String email, String? name});
  RouteObserver? get navigatorObserver;
  trackNavigation(String path, {String? widgetClass});
  trackEvent(AppAnalyticsData eventData);
}
