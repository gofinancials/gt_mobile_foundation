import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock implementation of [AppPermissionService] for testing.
class AppPermissionServiceMock implements AppPermissionService {
  @override
  Future<bool> isPermissionGranted(AppPermissions permissions) async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> requestPermission(AppPermissions permissions) async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> openAppPermissionsSettings() async {
    return AppHelpers.randomBool;
  }

  @override
  Future<bool> requestPermissions(List<AppPermissions> permissions) async {
    return AppHelpers.randomBool;
  }
}
