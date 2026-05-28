import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Services}
/// The interface definition for application analytics tracking.
abstract class AppAnalyticsService {
  /// Associates the current analytics session with a specific user [id], [accountNumber], and optional [name].
  identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  });

  /// Returns the [RouteObserver] to track navigation events.
  RouteObserver? get navigatorObserver;

  /// Tracks a navigation event to the specified [path] with an optional [widgetClass].
  trackNavigation(String path, {String? widgetClass});

  /// Tracks a custom analytics event using the provided [eventData].
  trackEvent(AppAnalyticsData eventData);
}
