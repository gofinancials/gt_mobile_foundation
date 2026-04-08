import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

extension ObjectExtension on Object {
  AppConfig get config => locator<AppConfig>();
  AppConfigStrings get stringKeys => config.strings;
}
