import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// Holds session information for an authenticated user.
class SessionData {
  String accessToken;
  String refreshToken;
  String? biometricToken;
  int lastLoginTime;
  int accessTokenExpiresAt;
  int refreshTokenExpiresAt;
  int? biometricTokenExpiresAt;
  bool hasEnabledBioAuth;
  String deviceId;
  String? userRole;
  String? userName;
  String? userId;
  bool isTwoFactorEnabled;

  SessionData({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.deviceId,
    required this.lastLoginTime,
    this.hasEnabledBioAuth = false,
    this.userName,
    this.userId,
    this.userRole,
    this.biometricToken,
    this.isTwoFactorEnabled = false,
    this.biometricTokenExpiresAt,
  });

  /// This session as the flat string map [AppStorageService] stores.
  ///
  /// Keyed by [AppStorageKey] so the keys written here and the keys read back
  /// by [SessionData.fromCache] cannot drift apart.
  ///
  /// A null field is stored as a null value rather than the string "null",
  /// so it reads back as null.
  Map<String, String?> toCache() {
    return {
      AppStorageKey.accessToken: accessToken,
      AppStorageKey.refreshToken: refreshToken,
      AppStorageKey.biometricToken: biometricToken,
      AppStorageKey.lastLoginTime: lastLoginTime.toString(),
      AppStorageKey.accessTokenExpiresAt: accessTokenExpiresAt.toString(),
      AppStorageKey.refreshTokenExpiresAt: refreshTokenExpiresAt.toString(),
      AppStorageKey.biometricTokenExpiresAt: biometricTokenExpiresAt
          ?.toString(),
      AppStorageKey.hasEnabledBioAuth: hasEnabledBioAuth.toString(),
      AppStorageKey.deviceId: deviceId,
      AppStorageKey.userRole: userRole,
      AppStorageKey.userName: userName,
      AppStorageKey.userId: userId,
      AppStorageKey.isTwoFactorEnabled: isTwoFactorEnabled.toString(),
    };
  }

  /// Reads a session back out of the map [toCache] wrote.
  ///
  /// Takes a dynamic value map because a storage implementation is free to
  /// hand back what it stored — an int rather than a string, say — so every
  /// number is interpolated before it is parsed and no read can throw.
  /// A missing or unparseable value falls back to its default.
  factory SessionData.fromCache(Map<String, dynamic> cache) {
    int? intAt(String key) {
      final value = cache[key];
      if (value == null) return null;
      return "$value".asInt;
    }

    bool boolAt(String key) {
      final value = cache[key];
      if (value is bool) return value;
      return bool.tryParse("${value ?? false}") ?? false;
    }

    String? stringAt(String key) {
      final value = cache[key];
      if (value == null) return null;
      return "$value";
    }

    return SessionData(
      accessToken: stringAt(AppStorageKey.accessToken) ?? '',
      refreshToken: stringAt(AppStorageKey.refreshToken) ?? '',
      biometricToken: stringAt(AppStorageKey.biometricToken),
      lastLoginTime: intAt(AppStorageKey.lastLoginTime) ?? 0,
      accessTokenExpiresAt: intAt(AppStorageKey.accessTokenExpiresAt) ?? 0,
      refreshTokenExpiresAt: intAt(AppStorageKey.refreshTokenExpiresAt) ?? 0,
      biometricTokenExpiresAt: intAt(AppStorageKey.biometricTokenExpiresAt),
      hasEnabledBioAuth: boolAt(AppStorageKey.hasEnabledBioAuth),
      deviceId: stringAt(AppStorageKey.deviceId) ?? '',
      userRole: stringAt(AppStorageKey.userRole),
      userName: stringAt(AppStorageKey.userName),
      userId: stringAt(AppStorageKey.userId),
      isTwoFactorEnabled: boolAt(AppStorageKey.isTwoFactorEnabled),
    );
  }

  SessionData copyWith({
    String? accessToken,
    String? refreshToken,
    String? biometricToken,
    int? lastLoginTime,
    int? accessTokenExpiresAt,
    int? refreshTokenExpiresAt,
    int? biometricTokenExpiresAt,
    bool? hasEnabledBioAuth,
    String? deviceId,
    String? userName,
    String? userRole,
    String? userId,
    bool? isTwoFactorEnabled,
  }) {
    return SessionData(
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      deviceId: deviceId ?? this.deviceId,
      hasEnabledBioAuth: hasEnabledBioAuth ?? this.hasEnabledBioAuth,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      biometricToken: biometricToken ?? this.biometricToken,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      biometricTokenExpiresAt:
          biometricTokenExpiresAt ?? this.biometricTokenExpiresAt,
    );
  }
}
