import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Mixins}
/// A mixin that provides simplified access to the [AppAnalyticsService]
/// for tracking user events and navigation within any class.
///
/// Classes mixing in [AppAnalyticsMixin] can dispatch events and screen views
/// directly via [trackEvent] and [trackNavigation] without manually resolving
/// the service locator.
mixin AppAnalyticsMixin {
  /// The injected instance of [AppAnalyticsService], or `null` if the service
  /// has not yet been registered in the service [locator].
  AppAnalyticsService? get analytics {
    if (!locator.isRegistered<AppAnalyticsService>()) {
      AppLogger.info('Analytics service not initialized');
      return null;
    }
    return locator<AppAnalyticsService>();
  }

  /// Tracks a specific user [event].
  ///
  /// Optionally include a [description] and an associated [value] to
  /// provide more context to the analytics payload.
  ///
  /// Safe to call even if [AppAnalyticsService] is not registered; in that case,
  /// the event is ignored after logging an informational message.
  Future<void> trackEvent(
    AppEvent event, {
    String? description,
    dynamic value,
  }) async {
    await analytics?.trackEvent(
      AppAnalyticsData(event, description: description, value: value),
    );
  }

  /// Tracks a screen or page navigation event to the given [path].
  ///
  /// The optional [widgetClass] parameter can be used to explicitly define
  /// the name of the widget being rendered; otherwise, [path] is used.
  ///
  /// Safe to call even if [AppAnalyticsService] is not registered; in that case,
  /// the event is ignored after logging an informational message.
  Future<void> trackNavigation(String path, {String? widgetClass}) async {
    await analytics?.trackNavigation(path, widgetClass: widgetClass ?? path);
  }
}
