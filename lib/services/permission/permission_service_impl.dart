import 'package:gt_mobile_foundation/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Implementation of [AppPermissionService] using the `permission_handler` package.
class AppPermissionServiceImpl implements AppPermissionService {
  /// Checks if the given [permissions] are granted, limited, or restricted.
  @override
  Future<bool> isPermissionGranted(AppPermissions permissions) async {
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

  /// Requests the given [permissions].
  ///
  /// Opens the app settings if the permission is permanently denied.
  @override
  Future<bool> requestPermission(AppPermissions permissions) async {
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

  /// Opens the application settings screen.
  @override
  Future<bool> openAppPermissionsSettings() {
    return openAppSettings();
  }

  /// Requests multiple [permissions] sequentially.
  ///
  /// Returns `true` if all permissions are granted.
  @override
  Future<bool> requestPermissions(List<AppPermissions> permissions) async {
    if (permissions.isEmpty) return false;
    List<bool> statuses = [];
    for (int i = 0; i < permissions.length; i++) {
      statuses.add(await requestPermission(permissions[i]));
    }
    return statuses.every((it) => it);
  }
}
