import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Extensions}
/// Extension on [Object] that provides global getters for accessing
/// the main configuration and localized strings.
extension ObjectExtension on Object {
  /// Provides quick access to the injected [AppConfig] instance.
  AppConfig get config => locator<AppConfig>();

  /// Provides quick access to the [AppConfigStrings] from the config.
  AppConfigStrings get stringKeys => config.strings;
}
