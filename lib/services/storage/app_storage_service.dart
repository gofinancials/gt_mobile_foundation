import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

/// Base class for all local storage keys used within the application.
///
/// By using a sealed class, we gain type safety and discoverability for common keys,
/// while retaining the ability to create new keys via [CustomStorageKey] without modifying
/// this core file.
sealed class AppStorageKey {
  /// The underlying string representation of the key used for actual storage operations.
  final String key;
  const AppStorageKey(this.key);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppStorageKey && key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Storage key for the user's authentication access token.
class AccessTokenKey extends AppStorageKey {
  const AccessTokenKey() : super('accessToken');
}

/// Storage key for the user's authentication refresh token.
class RefreshTokenKey extends AppStorageKey {
  const RefreshTokenKey() : super('refreshToken');
}

/// Storage key for the biometric authentication token.
class BiometricTokenKey extends AppStorageKey {
  const BiometricTokenKey() : super('biometricToken');
}

/// Storage key for the timestamp of the user's last successful login.
class LastLoginTimeKey extends AppStorageKey {
  const LastLoginTimeKey() : super('lastLoginTime');
}

/// Storage key for the expiration date/time of the access token.
class AccessTokenExpiresAtKey extends AppStorageKey {
  const AccessTokenExpiresAtKey() : super('accessTokenExpiresAt');
}

/// Storage key for the expiration date/time of the refresh token.
class RefreshTokenExpiresAtKey extends AppStorageKey {
  const RefreshTokenExpiresAtKey() : super('refreshTokenExpiresAt');
}

/// Storage key for the expiration date/time of the biometric token.
class BiometricTokenExpiresAtKey extends AppStorageKey {
  const BiometricTokenExpiresAtKey() : super('biometricTokenExpiresAt');
}

/// Storage key indicating whether the user has enabled biometric authentication.
class HasEnabledBioAuthKey extends AppStorageKey {
  const HasEnabledBioAuthKey() : super('hasEnabledBioAuth');
}

/// Storage key for a unique, generated device identifier.
class DeviceIdKey extends AppStorageKey {
  const DeviceIdKey() : super('deviceId');
}

/// Storage key for the user's assigned role.
class UserRoleKey extends AppStorageKey {
  const UserRoleKey() : super('userRole');
}

/// Storage key for the authenticated user's display name or username.
class UserNameKey extends AppStorageKey {
  const UserNameKey() : super('userName');
}

/// Storage key for the authenticated user's unique identifier.
class UserIdKey extends AppStorageKey {
  const UserIdKey() : super('userId');
}

/// Storage key indicating whether the user has two-factor authentication enabled.
class IsTwoFactorEnabledKey extends AppStorageKey {
  const IsTwoFactorEnabledKey() : super('isTwoFactorEnabled');
}

/// Storage key for the user's preferred theme mode (e.g., light, dark, system).
class ThemeModeKey extends AppStorageKey {
  const ThemeModeKey() : super('themeMode');
}

/// Storage key for the user's preferred application language/locale.
class LanguageKey extends AppStorageKey {
  const LanguageKey() : super('language');
}

/// A custom storage key allowing any module to define its own key dynamically
/// without modifying the core [AppStorageKey] sealed class.
class CustomStorageKey extends AppStorageKey {
  const CustomStorageKey(super.key);
}

/// Abstract contract defining the core operations for local application storage.
///
/// Implementations of this service (like secure storage or shared preferences)
/// handle the actual reading and writing of data.
abstract class AppStorageService {
  /// Checks whether a specific [key] exists in storage.
  /// 
  /// Returns `true` if the key exists, otherwise `false`.
  Future<bool> hasItem(AppStorageKey key);

  /// Retrieves the value associated with the provided [key].
  /// 
  /// Returns the string value if found, or `null` if the key does not exist.
  Future<String?> getItem(AppStorageKey key);

  /// Retrieves multiple values simultaneously for the given [keys].
  /// 
  /// Returns a map where each key is paired with its corresponding value (or `null`).
  Future<Map<AppStorageKey, String?>> getItems(List<AppStorageKey> keys);

  /// Saves or updates the [data] associated with the given [key].
  Future<void> setItem(AppStorageKey key, String data);

  /// Saves or updates multiple [items] simultaneously.
  Future<void> setItems(Map<AppStorageKey, String> items);

  /// Registers a [callback] that fires whenever the value for the given [key] changes.
  void watchItem(AppStorageKey key, OnChanged<String?> callback);

  /// Deletes the item associated with the provided [key] from storage.
  Future<void> removeItem(AppStorageKey key);

  /// Deletes multiple items matching the provided [keys] from storage.
  Future<void> removeItems(List<AppStorageKey> keys);

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
