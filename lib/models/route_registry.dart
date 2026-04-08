import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

abstract class RouteRegistry {
  Map<String, Widget Function(BuildContext)> get staticRoutes;
  Route<dynamic> dynamicRoutes(RouteSettings settings, Route fallbackRoute);
}

abstract class RootRouteRegistry with AppAnalyticsMixin {
  List<String> get unguardedRoutes;
  Map<String, Widget Function(BuildContext)> get staticRoutes;
  Route<dynamic>? dynamicRoutes(RouteSettings settings);
  List<Route<dynamic>> initialRoutes(String path);
}

mixin RootRouteRegistryMixin on RootRouteRegistry {
  logNavigation(RouteSettings? settings) {
    if (settings == null || settings.name == null) return;
    final route = settings.name;
    AppLogger.info("NAVIGATING TO -> $route");
  }

  bool canActivateRoute(RouteSettings? settings, bool isLoggedIn) {
    final route = settings?.name;
    final isGuardedRoute = !unguardedRoutes.contains(route);
    if (!isLoggedIn && isGuardedRoute) return false;
    return true;
  }
}
