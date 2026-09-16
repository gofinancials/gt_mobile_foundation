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

  /// The names of every user property this adapter may set in [identifyUser],
  /// kept here so [resetUser] can clear all of them regardless of which ones
  /// were populated for the current user.
  static const _userPropertyNames = [
    "account_number",
    "user_name",
    "user_first_name",
    "user_last_name",
    "user_email",
    "user_telephone",
    "user_bvn",
  ];

  @override
  Future<void> identifyUser({
    required dynamic id,
    String? accountNumber,
    String? name,
    String? firstName,
    String? lastName,
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
        if (firstName.hasValue)
          _analytics.setUserProperty(name: "user_first_name", value: firstName),
        if (lastName.hasValue)
          _analytics.setUserProperty(name: "user_last_name", value: lastName),
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
          "firstName": ?firstName,
          "lastName": ?lastName,
          "telephone": ?telephone,
          "bvn": ?bvn,
        }),
      ]);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  @override
  Future<void> resetUser() async {
    try {
      await Future.wait([
        _analytics.setUserId(id: null),
        for (final property in _userPropertyNames)
          _analytics.setUserProperty(name: property, value: null),
        _analytics.setDefaultEventParameters(null),
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
        parameters: {
          ...eventData.toJson(),
          ..._sanitizedAttributes(eventData.attributes),
        },
      );
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Coerces [attributes] to Firebase Analytics' event parameter constraints:
  /// only `String`/`num` values are accepted, names are capped at 40
  /// characters, and string values are capped at 100 characters.
  Map<String, Object> _sanitizedAttributes(Map<String, Object>? attributes) {
    if (attributes == null) return const {};
    return attributes.map((key, value) {
      final trimmedKey = key.length > 40 ? key.substring(0, 40) : key;
      final asParam = value is String || value is num ? value : "$value";
      final trimmedValue = asParam is String && asParam.length > 100
          ? asParam.substring(0, 100)
          : asParam;
      return MapEntry(trimmedKey, trimmedValue);
    });
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
