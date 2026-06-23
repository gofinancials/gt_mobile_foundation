import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Defines the interface for managing user sessions, including token lifecycle and biometric states.
abstract class AppSessionService {
  /// Retrieves the current session data, if any.
  SessionData? get sessionData;

  /// Creates a new session with the provided [data].
  Future createSession({required SessionData data});

  /// Modifies the existing session with [update]. If [ephemeral] is true, the changes won't persist across restarts.
  Future modifySession({required SessionData? update, bool ephemeral = false});

  /// Disables biometric login capabilities for the current user.
  Future disableBioLogin();

  /// Enables biometric login capabilities, requiring a [biometricToken].
  Future enableBioLogin(String token);

  /// Closes the active session, typically used on logout.
  Future closeSession();

  /// Clears all session data permanently.
  Future clearSessionData();

  /// Retrieves the active access token.
  String? get accessToken;

  /// Retrieves the biometric token.
  String? get biometricToken;

  /// Retrieves the refresh token to renew the session.
  String? get refreshToken;

  /// Retrieves the last user name used to log in.
  String? get userName;

  /// Retrieves the user id used to log in.
  String? get userId;

  /// Retrieves the user role used to log in.
  String? get userRole;

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
}
