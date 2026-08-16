import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// Defines the modular contract for feature-level route configuration and resolution.
abstract class RouteRegistry {
  /// The base route prefix or namespace for routes defined in this registry.
  String get basePath;

  /// The list of route names within this module that do not require authentication or authorization.
  List<String> get unguardedRoutes;

  /// The static route mapping of route names to their respective [WidgetBuilder] functions.
  Map<String, Widget Function(BuildContext)> get staticRoutes;

  /// Resolves dynamic or parameterized routes based on the provided [settings],
  /// falling back to [fallbackRoute] if no match is found.
  Route<dynamic> dynamicRoutes(RouteSettings settings, Route fallbackRoute);
}

/// {@category Data}
/// Defines the top-level route registry contract that coordinates application-wide navigation,
/// manages nested feature [RouteRegistry] instances, and integrates with [AppAnalyticsMixin].
abstract class RootRouteRegistry with AppAnalyticsMixin {
  /// The collection of modular [RouteRegistry] instances registered in the application.
  List<RouteRegistry> get routeRegistries;

  /// Resolves dynamic routes for top-level or child registry routes based on [settings].
  Route<dynamic>? dynamicRoutes(RouteSettings settings);

  /// Generates the initial route stack to push when opening the application at the given [path].
  List<Route<dynamic>> initialRoutes(String path);
}

/// {@category Mixins}
/// Provides default helper implementations for [RootRouteRegistry], including navigation logging
/// and route guarding checks.
mixin RootRouteRegistryMixin on RootRouteRegistry {
  /// The aggregated list of all route names across the application that do not require authentication.
  List<String> get unguardedRoutes => [
    ...routeRegistries.expand((registry) => registry.unguardedRoutes),
  ];

  /// Aggregates the static route mappings across all registered [routeRegistries].
  Map<String, Widget Function(BuildContext)> get staticRoutes => {
    for (final registry in routeRegistries) ...registry.staticRoutes,
  };

  /// Logs route navigation transitions using [AppLogger] if [settings] contains a valid route name.
  void logNavigation(RouteSettings? settings) {
    if (settings == null || !settings.name.hasValue) return;
    final route = settings.name;
    AppLogger.info("NAVIGATING TO -> $route");
  }

  /// Determines whether a route defined in [settings] can be activated based on whether
  /// the user [isLoggedIn] and whether the route is marked as unguarded in [unguardedRoutes].
  bool canActivateRoute(RouteSettings? settings, bool isLoggedIn) {
    final route = settings?.name;
    final isGuardedRoute = !unguardedRoutes.contains(route);
    if (!isLoggedIn && isGuardedRoute) return false;
    return true;
  }
}
