import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

/// Base class for all local storage keys used within the application.
///
/// We use a class with static strings to provide easy access and discoverability
/// for common keys, while allowing any module to define its own key dynamically
class AppStorageKey {
  /// Storage key for the user's authentication access token.
  static const String accessToken = 'accessToken';

  /// Storage key for the user's authentication refresh token.
  static const String refreshToken = 'refreshToken';

  /// Storage key for the biometric authentication token.
  static const String biometricToken = 'biometricToken';

  /// Storage key for the timestamp of the user's last successful login.
  static const String lastLoginTime = 'lastLoginTime';

  /// Storage key for the expiration date/time of the access token.
  static const String accessTokenExpiresAt = 'accessTokenExpiresAt';

  /// Storage key for the expiration date/time of the refresh token.
  static const String refreshTokenExpiresAt = 'refreshTokenExpiresAt';

  /// Storage key for the expiration date/time of the biometric token.
  static const String biometricTokenExpiresAt = 'biometricTokenExpiresAt';

  /// Storage key indicating whether the user has enabled biometric authentication.
  static const String hasEnabledBioAuth = 'hasEnabledBioAuth';

  /// Storage key for a unique, generated device identifier.
  static const String deviceId = 'deviceId';

  /// Storage key for the user's assigned role.
  static const String userRole = 'userRole';

  /// Storage key for the authenticated user's display name or username.
  static const String userName = 'userName';

  /// Storage key for the authenticated user's unique identifier.
  static const String userId = 'userId';

  /// Storage key indicating whether the user has two-factor authentication enabled.
  static const String isTwoFactorEnabled = 'isTwoFactorEnabled';

  /// Storage key for the user's preferred theme mode (e.g., light, dark, system).
  static const String themeMode = 'themeMode';

  /// Storage key for the user's preferred application language/locale.
  static const String language = 'language';
}

/// Abstract contract defining the core operations for local application storage.
///
/// Implementations of this service (like secure storage or shared preferences)
/// handle the actual reading and writing of data.
abstract class AppStorageService {
  /// Checks whether a specific [key] exists in storage.
  ///
  /// Returns `true` if the key exists, otherwise `false`.
  Future<bool> hasItem(String key);

  /// Retrieves the value associated with the provided [key].
  ///
  /// Returns the string value if found, or `null` if the key does not exist.
  Future<String?> getItem(String key);

  /// Retrieves multiple values simultaneously for the given [keys].
  ///
  /// Returns a map where each key is paired with its corresponding value (or `null`).
  Future<Map<String, String?>> getItems(List<String> keys);

  /// Saves or updates the [data] associated with the given [key].
  Future<void> setItem(String key, String data);

  /// Saves or updates multiple [items] simultaneously.
  Future<void> setItems(Map<String, String> items);

  /// Registers a [callback] that fires whenever the value for the given [key] changes.
  void watchItem(String key, OnChanged<String?> callback);

  /// Deletes the item associated with the provided [key] from storage.
  Future<void> removeItem(String key);

  /// Deletes multiple items matching the provided [keys] from storage.
  Future<void> removeItems(List<String> keys);

  /// Clears all stored data managed by this service.
  ///
  /// **Warning**: This action is irreversible and should be used with caution
  /// (e.g., during user logout or app reset).
  Future clearDb();

  /// Closes the underlying database or storage connection.
  ///
  /// Also clears the database, depending on the implementation.
  Future closeDb();
}
