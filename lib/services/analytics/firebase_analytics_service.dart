import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// An implementation of [AppAnalyticsService] that utilizes Firebase Analytics.
///
/// This service encapsulates all Firebase Analytics interactions, including
/// user identification, event tracking, and screen navigation logging. 
/// Any exceptions that occur during these operations are automatically caught 
/// and forwarded to the provided [AppCrashlyticsService].
class AppAnalyticsServiceImpl implements AppAnalyticsService {
  final AppCrashlyticsService _crashlyticsService;

  /// Creates a new instance of the analytics service.
  ///
  /// Requires an injected [_crashlyticsService] to handle any non-fatal errors
  /// that occur during analytics tracking.
  AppAnalyticsServiceImpl(this._crashlyticsService);

  /// Provides direct access to the underlying [FirebaseAnalytics] instance.
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  _reportError(Object e, StackTrace t) {
    _crashlyticsService.trackError("$e", error: e, trace: t);
  }

  /// Identifies the current user and sets their profile properties in Firebase.
  ///
  /// This method sets the primary user [id] and also associates optional 
  /// properties such as [accountNumber], [name], [email], [telephone], and [bvn]
  /// with the user's future analytics events. It also establishes these values 
  /// as default event parameters.
  @override
  identifyUser({
    required id,
    String? accountNumber,
    String? name,
    String? email,
    String? telephone,
    String? bvn,
  }) async {
    try {
      await Future.wait([
        analytics.setUserId(id: "$id"),
        if (accountNumber.hasValue)
          analytics.setUserProperty(
            name: "account_number",
            value: accountNumber,
          ),
        if (name.hasValue)
          analytics.setUserProperty(name: "user_name", value: name),
        if (email.hasValue)
          analytics.setUserProperty(name: "user_email", value: email),
        if (telephone.hasValue)
          analytics.setUserProperty(name: "user_telephone", value: telephone),
        if (bvn.hasValue)
          analytics.setUserProperty(name: "user_bvn", value: bvn),
        analytics.setDefaultEventParameters({
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

  /// Logs a custom application event to Firebase Analytics.
  ///
  /// The [eventData] contains the event name and any associated parameters.
  /// Note: The event name will have any spaces automatically replaced with 
  /// underscores to comply with Firebase naming conventions.
  @override
  trackEvent(AppAnalyticsData eventData) async {
    try {
      await analytics.logEvent(
        name: eventData.event.name.replaceAll(" ", "_"),
        parameters: eventData.toJson(),
      );
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Logs a screen view navigation event to Firebase Analytics.
  ///
  /// Records that the user has navigated to the specified [path] route. 
  /// An optional [widgetClass] can be provided to specify the UI component rendered.
  @override
  trackNavigation(String path, {String? widgetClass}) async {
    try {
      await analytics.logScreenView(screenName: path, screenClass: widgetClass);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  /// Returns a [RouteObserver] configured to automatically track screen views.
  ///
  /// This observer can be added to the `navigatorObservers` list in a `MaterialApp`
  /// or `CupertinoApp` to automatically track navigation events across the app.
  @override
  RouteObserver? get navigatorObserver {
    return FirebaseAnalyticsObserver(
      analytics: analytics,
      nameExtractor: (settings) => settings.name,
    );
  }
}
