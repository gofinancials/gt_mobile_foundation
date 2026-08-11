import 'package:flutter/material.dart';
import 'analytics_interface.dart';

/// A [NavigatorObserver] that forwards route navigation events to an [AppAnalyticsService].
class AppAnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final AppAnalyticsService _analyticsService;

  /// Creates an observer with the given [_analyticsService].
  AppAnalyticsRouteObserver(this._analyticsService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _sendScreenView(previousRoute);
    }
  }

  void _sendScreenView(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      _analyticsService.trackNavigation(name);
    }
  }
}
