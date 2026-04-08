import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AppAnalyticsServiceImpl implements AppAnalyticsService {
  final AppCrashlyticsService _crashlyticsService;

  AppAnalyticsServiceImpl(this._crashlyticsService);

  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  _reportError(Object e, StackTrace t) {
    _crashlyticsService.trackError("$e", error: e, trace: t);
  }

  @override
  identifyUser({required id, required String email, String? name}) async {
    try {
      await Future.wait([
        analytics.setUserId(id: "$id"),
        analytics.setUserProperty(name: "user_email", value: email),
        if (name != null)
          analytics.setUserProperty(name: "user_name", value: name),
        analytics.setDefaultEventParameters({"id": id, "email": email}),
      ]);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

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

  @override
  trackNavigation(String path, {String? widgetClass}) async {
    try {
      await analytics.logScreenView(screenName: path, screenClass: widgetClass);
    } catch (e, t) {
      _reportError(e, t);
    }
  }

  @override
  RouteObserver? get navigatorObserver {
    return FirebaseAnalyticsObserver(
      analytics: analytics,
      nameExtractor: (settings) => settings.name,
    );
  }
}
