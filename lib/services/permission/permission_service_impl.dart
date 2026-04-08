import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionServiceImpl implements AppPermissionService {
  @override
  Future<bool> isPermissionGranted(Permissions permissions) async {
    try {
      final permission = Permission.byValue(permissions.index);
      final status = await Future.wait([
        permission.isGranted,
        permission.isLimited,
        permission.isRestricted,
      ]);
      return status.any((it) => it == true);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission(Permissions permissions) async {
    try {
      if (await isPermissionGranted(permissions)) return true;

      final permission = Permission.byValue(permissions.index);
      final status = await permission.request();

      if (status.isPermanentlyDenied) {
        await openAppPermissionsSettings();
        return isPermissionGranted(permissions);
      }

      return [
        PermissionStatus.granted,
        PermissionStatus.limited,
        PermissionStatus.restricted,
      ].contains(status);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppPermissionsSettings() {
    return openAppSettings();
  }

  @override
  Future<bool> requestPermissions(List<Permissions> permissions) async {
    if (permissions.isEmpty) return false;
    List<bool> statuses = [];
    for (int i = 0; i < permissions.length; i++) {
      statuses.add(await requestPermission(permissions[i]));
    }
    return statuses.every((it) => it);
  }
}
