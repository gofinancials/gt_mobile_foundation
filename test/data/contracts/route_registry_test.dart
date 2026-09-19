import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class _TestRegistry implements RouteRegistry {
  _TestRegistry({required this.basePath, required this.routes, this.unguarded});

  @override
  final String basePath;

  final Map<String, WidgetBuilder> routes;
  final List<String>? unguarded;

  @override
  List<String> get unguardedRoutes => unguarded ?? const [];

  @override
  Map<String, WidgetBuilder> get staticRoutes => routes;

  @override
  Route<dynamic> dynamicRoutes(RouteSettings settings, Route fallbackRoute) {
    return fallbackRoute;
  }
}

class _TestRootRegistry extends RootRouteRegistry with RootRouteRegistryMixin {
  _TestRootRegistry(this.routeRegistries);

  @override
  final List<RouteRegistry> routeRegistries;

  @override
  Route<dynamic>? dynamicRoutes(RouteSettings settings) => null;

  @override
  List<Route<dynamic>> initialRoutes(String path) => const [];
}

Widget _builder(BuildContext context) => const SizedBox.shrink();

void main() {
  group('RootRouteRegistry', () {
    test('exposes the aggregated routes through the contract', () {
      final RootRouteRegistry registry = _TestRootRegistry([
        _TestRegistry(
          basePath: '/auth',
          routes: {'/auth/login': _builder, '/auth/register': _builder},
        ),
        _TestRegistry(basePath: '/home', routes: {'/home': _builder}),
      ]);

      expect(registry.staticRoutes.keys, [
        '/auth/login',
        '/auth/register',
        '/home',
      ]);
    });

    test('exposes the aggregated unguarded routes through the contract', () {
      final RootRouteRegistry registry = _TestRootRegistry([
        _TestRegistry(
          basePath: '/auth',
          routes: {'/auth/login': _builder},
          unguarded: ['/auth/login'],
        ),
        _TestRegistry(basePath: '/home', routes: {'/home': _builder}),
      ]);

      expect(registry.unguardedRoutes, ['/auth/login']);
    });

    test('a registry with nothing registered aggregates to empty', () {
      final RootRouteRegistry registry = _TestRootRegistry([]);

      expect(registry.staticRoutes, isEmpty);
      expect(registry.unguardedRoutes, isEmpty);
    });
  });
}
