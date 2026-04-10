import 'package:gt_mobile_foundation/foundation.dart';

mixin AppAnalyticsMixin {
  AppAnalyticsService get analytics => locator<AppAnalyticsService>();

  trackEvent(AppEvent event, {String? description, dynamic value}) async {
    analytics.trackEvent(
      AppAnalyticsData(event, description: description, value: value),
    );
  }

  trackNavigation(String path, {String? widgetClass}) async {
    analytics.trackNavigation(path, widgetClass: widgetClass ?? path);
  }
}
