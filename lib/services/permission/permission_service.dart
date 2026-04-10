import 'package:gt_mobile_foundation/foundation.dart';

abstract class AppPermissionService {
  Future<bool> isPermissionGranted(AppPermissions permission);

  Future<bool> requestPermission(AppPermissions permission);

  Future<bool> requestPermissions(List<AppPermissions> permissions);

  Future<bool> openAppPermissionsSettings();
}
