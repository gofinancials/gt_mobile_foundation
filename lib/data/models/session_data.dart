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
    this.hasEnabledBioAuth = false,
    this.userName,
    this.userId,
    this.userRole,
    this.biometricToken,
    this.isTwoFactorEnabled = false,
    this.biometricTokenExpiresAt,
  }) : lastLoginTime = DateTime.now().millisecondsSinceEpoch;

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
      biometricTokenExpiresAt:
          biometricTokenExpiresAt ?? this.biometricTokenExpiresAt,
    )..lastLoginTime = lastLoginTime ?? this.lastLoginTime;
  }
}
