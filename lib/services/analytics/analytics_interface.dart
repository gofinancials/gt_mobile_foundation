import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Services}
/// The interface definition for application analytics tracking.
abstract class AppAnalyticsService {
  /// Initializes all registered analytics providers.
  Future<void> initialize();

  /// Associates the current analytics session with a specific user [id], [accountNumber], and optional [name].
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  });

  /// Returns the [RouteObserver] to track navigation events across providers.
  RouteObserver? get navigatorObserver;

  /// Tracks a navigation event to the specified [path] with an optional [widgetClass].
  Future<void> trackNavigation(String path, {String? widgetClass});

  /// Tracks a custom analytics event using the provided [eventData].
  Future<void> trackEvent(AppAnalyticsData eventData);

  /// Registers an additional [AnalyticsProvider] at runtime.
  void addProvider(AnalyticsProvider provider);

  /// Unregisters an [AnalyticsProvider] at runtime.
  void removeProvider(AnalyticsProvider provider);
}

/// {@category Services}
/// The base abstraction (Adapter contract) for individual third-party analytics providers.
abstract class AnalyticsProvider {
  /// Initializes the underlying analytics SDK.
  Future<void> initialize();

  /// Identifies the user and sets user attributes in the analytics provider.
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  });

  /// Logs a custom event to the analytics provider.
  Future<void> trackEvent(AppAnalyticsData eventData);

  /// Logs a navigation screen view event to the analytics provider.
  Future<void> trackNavigation(String path, {String? widgetClass});
}
