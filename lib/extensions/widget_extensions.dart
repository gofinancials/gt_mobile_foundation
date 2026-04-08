import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

extension WidgetExtensions on Widget {
  launchUrl(String url) {
    try {
      AppUrlHandler.openUrl(url);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}

extension WidgetStateExtensions<T extends StatefulWidget> on State<T> {
  setOverlayStyle(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  launchUrl(String url) {
    try {
      AppUrlHandler.openUrl(url);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}
