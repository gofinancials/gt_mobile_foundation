import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class AppPermissionServiceMock implements AppPermissionService {
  @override
  Future<bool> isPermissionGranted(Permissions permissions) async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> requestPermission(Permissions permissions) async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> openAppPermissionsSettings() async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> requestPermissions(List<Permissions> permissions) async {
    return AppHelpers.randomBool;
  }
}
