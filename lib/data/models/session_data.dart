class SessionData {
  int id;
  String accessToken;
  String refreshToken;
  String? deviceToken;
  int createdAt;
  int expiresAt;
  int refreshAt;
  bool hasEnabledBioAuth;
  String deviceId;
  String? userUuid;
  String? lastEmail;

  SessionData({
    required this.accessToken,
    required this.expiresAt,
    required this.refreshAt,
    required this.refreshToken,
    required this.deviceId,
    this.hasEnabledBioAuth = false,
    this.lastEmail,
    this.userUuid,
    this.deviceToken,
  }) : id = 1,
       createdAt = DateTime.now().millisecondsSinceEpoch;

  SessionData copyWith({
    String? accessToken,
    String? refreshToken,
    String? deviceToken,
    int? expiresAt,
    int? refreshAt,
    bool? hasEnabledBioAuth,
    bool? hasActiveSubscription,
    bool? hasVerifiedEmail,
    String? lastEmail,
    String? userUuid,
    String? deviceId,
  }) {
    return SessionData(
      accessToken: accessToken ?? this.accessToken,
      deviceToken: deviceToken ?? this.deviceToken,
      refreshToken: refreshToken ?? this.refreshToken,
      deviceId: deviceId ?? this.deviceId,
      refreshAt: refreshAt ?? this.refreshAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hasEnabledBioAuth: hasEnabledBioAuth ?? this.hasEnabledBioAuth,
      lastEmail: lastEmail ?? this.lastEmail,
      userUuid: userUuid ?? this.userUuid,
    );
  }

  factory SessionData.loggedOut(SessionData? activeSession) {
    return SessionData(
      accessToken: "",
      deviceToken: activeSession?.deviceToken,
      deviceId: activeSession?.deviceId ?? "",
      refreshToken: "",
      expiresAt: 0,
      refreshAt: 0,
      lastEmail: activeSession?.lastEmail,
      hasEnabledBioAuth: activeSession?.hasEnabledBioAuth ?? false,
      userUuid: activeSession?.userUuid,
    );
  }
}
