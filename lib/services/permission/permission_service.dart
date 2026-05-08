import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// The interface definition for managing application permissions.
abstract class AppPermissionService {
  /// Checks whether the specified [permission] is currently granted.
  Future<bool> isPermissionGranted(AppPermissions permission);

  /// Requests the specified [permission] from the user.
  /// Returns `true` if granted.
  Future<bool> requestPermission(AppPermissions permission);

  /// Requests a list of [permissions] from the user.
  /// Returns `true` if all are granted.
  Future<bool> requestPermissions(List<AppPermissions> permissions);

  /// Opens the device settings page for the application permissions.
  Future<bool> openAppPermissionsSettings();
}
