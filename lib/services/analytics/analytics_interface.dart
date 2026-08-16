import 'package:gt_mobile_foundation/foundation.dart';

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

  /// Tracks a navigation event to the specified [path] with an optional [widgetClass].
  Future<void> trackNavigation(String path, {String? widgetClass});

  /// Tracks a custom analytics event using the provided [eventData].
  Future<void> trackEvent(AppAnalyticsData eventData);

  /// Registers an additional [AnalyticsProvider] at runtime.
  void addProvider(AnalyticsProvider provider);

  /// Unregisters an [AnalyticsProvider] at runtime.
  void removeProvider(AnalyticsProvider provider);
}
