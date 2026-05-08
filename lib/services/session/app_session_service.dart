import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Defines the interface for managing user sessions, including token lifecycle and biometric states.
abstract class AppSessionService {
  /// Retrieves the current session data, if any.
  SessionData? get sessionData;

  /// Creates a new session with the provided [authData].
  Future createSession({required SessionData authData});

  /// Modifies the existing session with [update]. If [ephemeral] is true, the changes won't persist across restarts.
  Future modifySession({required SessionData? update, bool ephemeral = false});

  /// Disables biometric login capabilities for the current user.
  Future disableBioLogin();

  /// Enables biometric login capabilities, requiring a [deviceToken].
  Future enableBioLogin(String deviceToken);

  /// Closes the active session, typically used on logout.
  Future closeSession();

  /// Clears all session data permanently.
  Future clearSessionData();

  /// Retrieves the active access token.
  String? get accessToken;

  /// Retrieves the device token used for push notifications and biometrics.
  String? get deviceToken;

  /// Retrieves the refresh token to renew the session.
  String? get refreshToken;

  /// Retrieves the last email address used to log in.
  String? get lastEmail;

  /// Retrieves the unique device identifier.
  FutureOr<String> get deviceId;

  /// Checks if the current session token has expired.
  bool get isExpired;

  /// Checks if the current session token is nearing expiration and needs refreshing.
  bool get shouldBeRefreshed;

  /// Checks if a token is present in the session.
  bool get hasToken;

  /// Checks if the user is currently logged in with a valid session.
  bool get isLoggedIn;

  /// Checks if biometric authentication is enabled and allowed for this session.
  bool get allowsBiometricAuth;

  /// Checks if any session data exists.
  bool get hasSession;
}
