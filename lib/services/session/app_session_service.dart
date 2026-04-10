import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

abstract class AppSessionService {
  SessionData? get sessionData;

  Future createSession({required SessionData authData});

  Future modifySession({required SessionData? update, bool ephemeral = false});

  Future disableBioLogin();

  Future enableBioLogin(String deviceToken);

  Future closeSession();

  Future clearSessionData();

  String? get accessToken;

  String? get deviceToken;

  String? get refreshToken;

  String? get lastEmail;

  FutureOr<String> get deviceId;

  bool get isExpired;

  bool get shouldBeRefreshed;

  bool get hasToken;

  bool get isLoggedIn;

  bool get allowsBiometricAuth;

  bool get hasSession;
}
