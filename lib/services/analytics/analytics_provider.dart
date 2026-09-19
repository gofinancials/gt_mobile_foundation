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
    String? firstName,
    String? lastName,
    String? email,
    String? telephone,
    String? bvn,
  });

  /// Clears the currently identified user and any attributes set by [identifyUser].
  ///
  /// Call this on logout so the next user on the same device is not merged
  /// into the previous one's analytics profile.
  Future<void> resetUser();

  /// Logs a custom event to the analytics provider.
  Future<void> trackEvent(AppAnalyticsData eventData);

  /// Logs a navigation screen view event to the analytics provider.
  Future<void> trackNavigation(String path, {String? widgetClass});
}
