import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

SessionData _session({
  String? biometricToken = 'bio-token',
  int? biometricTokenExpiresAt = 1700000003,
  String? userRole = 'customer',
  String? userName = 'ada',
  String? userId = 'user-1',
}) {
  return SessionData(
    accessToken: 'access-token',
    accessTokenExpiresAt: 1700000001,
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: 1700000002,
    deviceId: 'device-1',
    lastLoginTime: 1700000000,
    hasEnabledBioAuth: true,
    isTwoFactorEnabled: true,
    biometricToken: biometricToken,
    biometricTokenExpiresAt: biometricTokenExpiresAt,
    userRole: userRole,
    userName: userName,
    userId: userId,
  );
}

void _expectSameSession(SessionData actual, SessionData expected) {
  expect(actual.accessToken, expected.accessToken);
  expect(actual.refreshToken, expected.refreshToken);
  expect(actual.biometricToken, expected.biometricToken);
  expect(actual.lastLoginTime, expected.lastLoginTime);
  expect(actual.accessTokenExpiresAt, expected.accessTokenExpiresAt);
  expect(actual.refreshTokenExpiresAt, expected.refreshTokenExpiresAt);
  expect(actual.biometricTokenExpiresAt, expected.biometricTokenExpiresAt);
  expect(actual.hasEnabledBioAuth, expected.hasEnabledBioAuth);
  expect(actual.deviceId, expected.deviceId);
  expect(actual.userRole, expected.userRole);
  expect(actual.userName, expected.userName);
  expect(actual.userId, expected.userId);
  expect(actual.isTwoFactorEnabled, expected.isTwoFactorEnabled);
}

void main() {
  group('SessionData cache round trip', () {
    test('a full session survives the round trip', () {
      final session = _session();

      _expectSameSession(SessionData.fromCache(session.toCache()), session);
    });

    test('an absent optional field stays absent', () {
      final session = _session(
        biometricToken: null,
        biometricTokenExpiresAt: null,
        userRole: null,
        userName: null,
        userId: null,
      );

      final restored = SessionData.fromCache(session.toCache());

      _expectSameSession(restored, session);
      expect(restored.biometricTokenExpiresAt, isNull);
    });

    test('a null field is stored as null, not the string "null"', () {
      final cache = _session(biometricTokenExpiresAt: null).toCache();

      expect(cache[AppStorageKey.biometricTokenExpiresAt], isNull);
    });

    test('every cache key is written', () {
      final cache = _session().toCache();

      expect(cache.keys, containsAll(AppStorageKey.cacheKeys));
      expect(cache.keys.length, AppStorageKey.cacheKeys.length);
    });
  });

  group('SessionData.fromCache', () {
    test('reads an int the storage layer handed back as an int', () {
      final restored = SessionData.fromCache({
        AppStorageKey.lastLoginTime: 1700000000,
        AppStorageKey.accessTokenExpiresAt: 1700000001,
      });

      expect(restored.lastLoginTime, 1700000000);
      expect(restored.accessTokenExpiresAt, 1700000001);
    });

    test('reads a bool the storage layer handed back as a bool', () {
      final restored = SessionData.fromCache({
        AppStorageKey.hasEnabledBioAuth: true,
        AppStorageKey.isTwoFactorEnabled: false,
      });

      expect(restored.hasEnabledBioAuth, isTrue);
      expect(restored.isTwoFactorEnabled, isFalse);
    });

    test('falls back rather than throwing on an unparseable number', () {
      final restored = SessionData.fromCache({
        AppStorageKey.lastLoginTime: 'not-a-number',
      });

      expect(restored.lastLoginTime, 0);
    });

    test('an empty cache reads as an empty session', () {
      final restored = SessionData.fromCache({});

      expect(restored.accessToken, '');
      expect(restored.refreshToken, '');
      expect(restored.deviceId, '');
      expect(restored.lastLoginTime, 0);
      expect(restored.hasEnabledBioAuth, isFalse);
      expect(restored.isTwoFactorEnabled, isFalse);
      expect(restored.biometricToken, isNull);
      expect(restored.biometricTokenExpiresAt, isNull);
    });
  });

  group('AppStorageKey groups', () {
    test('credentials are the tokens a request authenticates with', () {
      expect(AppStorageKey.credentialKeys, [
        AppStorageKey.accessToken,
        AppStorageKey.refreshToken,
        AppStorageKey.accessTokenExpiresAt,
        AppStorageKey.refreshTokenExpiresAt,
      ]);
    });

    test('every credential key is also cleared by a sign-out', () {
      expect(
        AppStorageKey.clearanceKeys,
        containsAll(AppStorageKey.credentialKeys),
      );
    });

    test('a sign-out clears the cache but for the device and last login', () {
      expect(
        AppStorageKey.cacheKeys.toSet().difference(
          AppStorageKey.clearanceKeys.toSet(),
        ),
        {AppStorageKey.deviceId, AppStorageKey.lastLoginTime},
      );
    });

    test('no group holds a key twice', () {
      for (final group in [
        AppStorageKey.credentialKeys,
        AppStorageKey.cacheKeys,
        AppStorageKey.clearanceKeys,
      ]) {
        expect(group.toSet().length, group.length);
      }
    });
  });
}
