import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A secure implementation of [AppStorageService] utilizing `flutter_secure_storage`.
///
/// This service encrypts all stored data, making it suitable for sensitive
/// information such as authentication tokens and user credentials. On iOS, it uses
/// the Keychain. On Android, it uses EncryptedSharedPreferences.
class AppSecureStorageService implements AppStorageService {
  /// The underlying secure storage mechanism.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<Map<AppStorageKey, String?>> getItems(List<AppStorageKey> keys) async {
    try {
      final result = await Future.wait(keys.map((it) => _getItemMap(it)));
      return result.fold<Map<AppStorageKey, String?>>({}, (previous, element) {
        return previous..addAll(element);
      });
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return {};
    }
  }

  /// Internal helper to retrieve a single secure key and format it as a map entry.
  Future<Map<AppStorageKey, String?>> _getItemMap(AppStorageKey key) async {
    final value = await getItem(key);
    return {key: value};
  }

  @override
  Future<String?> getItem(AppStorageKey key) async {
    try {
      return await _storage.read(key: key.key);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return null;
    }
  }

  @override
  void watchItem(AppStorageKey key, OnChanged<String?> callback) {
    try {
      _storage.registerListener(key: key.key, listener: callback);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  Future<bool> hasItem(AppStorageKey key) async {
    try {
      return await _storage.containsKey(key: key.key);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return false;
    }
  }

  @override
  Future<void> removeItems(List<AppStorageKey> keys) async {
    try {
      await Future.wait(keys.map((it) => removeItem(it)));
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  Future<void> removeItem(AppStorageKey key) async {
    try {
      await _storage.delete(key: key.key);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  Future<void> setItem(AppStorageKey key, String data) async {
    try {
      await _storage.write(key: key.key, value: data);
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  @override
  Future<void> setItems(Map<AppStorageKey, String> items) async {
    try {
      await Future.wait(items.entries.map((it) => setItem(it.key, it.value)));
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  /// Clears all encrypted data managed by this storage mechanism.
  @override
  Future clearDb() async {
    try {
      await _storage.deleteAll();
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }

  /// Unregisters all listeners.
  @override
  Future closeDb() async {
    try {
      _storage.unregisterAllListeners();
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
    }
  }
}
