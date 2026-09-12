import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// An adapter implementation of [AnalyticsProvider] that wraps Firebase Analytics SDK.
class FirebaseAnalyticsAdapter implements AnalyticsProvider {
  final AppCrashlyticsService? _crashlyticsService;
  final FirebaseAnalytics _analytics;

  /// Creates a new [FirebaseAnalyticsAdapter].
  ///
  /// Optionally accepts an [_analytics] instance (for custom configuration or testing)
  /// and a [_crashlyticsService] to capture errors.
  FirebaseAnalyticsAdapter({
    AppCrashlyticsService? crashlyticsService,
    FirebaseAnalytics? analytics,
  }) : _crashlyticsService = crashlyticsService,
       _analytics = analytics ?? FirebaseAnalytics.instance;

  /// Provides access to the underlying [FirebaseAnalytics] instance.
  FirebaseAnalytics get analytics => _analytics;

  void _reportError(Object e, StackTrace t) {
    _crashlyticsService?.trackError("$e", error: e, trace: t);
  }

  @override
  Future<void> initialize() async {
    // Firebase analytics auto-initializes on startup
  }

  @override
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  }) async {
    try {
      await Future.wait([
        _analytics.setUserId(id: "$id"),
        if (accountNumber.hasValue)
          _analytics.setUserProperty(
            name: "account_number",
            value: accountNumber,
          ),
        if (name.hasValue)
          _analytics.setUserProperty(name: "user_name", value: name),
        if (email.hasValue)
          _analytics.setUserProperty(name: "user_email", value: email),
        if (telephone.hasValue)
          _analytics.setUserProperty(name: "user_telephone", value: telephone),
        if (bvn.hasValue)
          _analytics.setUserProperty(name: "user_bvn", value: bvn),
        _analytics.setDefaultEventParameters({
          "id": id,
          "email": ?email,
          "accountNumber": ?accountNumber,
          "name": ?name,
          "telephone": ?telephone,
          "bvn": ?bvn,
        }),
      ]);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  @override
  Future<void> trackEvent(AppAnalyticsData eventData) async {
    try {
      await _analytics.logEvent(
        name: eventData.event.name.replaceAll(" ", "_"),
        parameters: eventData.toJson(),
      );
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  @override
  Future<void> trackNavigation(String path, {String? widgetClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: path,
        screenClass: widgetClass,
      );
    } catch (e, t) {
      _reportError(e, t);
    }
  }
}
