import 'package:gt_mobile_foundation/foundation.dart';

extension ObjectExtension on Object {
  AppConfig get config => locator<AppConfig>();
  AppConfigStrings get stringKeys => config.strings;
}
