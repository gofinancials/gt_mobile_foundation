import 'package:gt_mobile_foundation/foundation.dart';

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
