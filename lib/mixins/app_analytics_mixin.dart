import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Mixins}
/// A mixin that provides simplified access to the [AppAnalyticsService]
/// for tracking user events and navigation within any class.
mixin AppAnalyticsMixin {
  /// The injected instance of the analytics service.
  AppAnalyticsService get analytics => locator<AppAnalyticsService>();

  /// Tracks a specific user [event].
  ///
  /// Optionally include a [description] and an associated [value] to
  /// provide more context to the analytics payload.
  trackEvent(AppEvent event, {String? description, dynamic value}) async {
    analytics.trackEvent(
      AppAnalyticsData(event, description: description, value: value),
    );
  }

  /// Tracks a screen or page navigation event to the given [path].
  ///
  /// The optional [widgetClass] parameter can be used to explicitly define
  /// the name of the widget being rendered; otherwise, [path] is used.
  trackNavigation(String path, {String? widgetClass}) async {
    analytics.trackNavigation(path, widgetClass: widgetClass ?? path);
  }
}
