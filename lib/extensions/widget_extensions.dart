import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Extensions}
/// Extension on [Widget] providing context-free utilities.
extension WidgetExtensions on Widget {
  /// Launches the provided [url] using the central [AppUrlHandler].
  launchUrl(String url) {
    try {
      AppUrlHandler.openUrl(url);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}

/// {@category Extensions}
/// Extension on [State] providing UI and navigational utilities bound to widget state.
extension WidgetStateExtensions<T extends StatefulWidget> on State<T> {
  /// Dynamically sets the [SystemUiOverlayStyle] for the system chrome.
  setOverlayStyle(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// Launches the provided [url] using the central [AppUrlHandler].
  launchUrl(String url) {
    try {
      AppUrlHandler.openUrl(url);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}
