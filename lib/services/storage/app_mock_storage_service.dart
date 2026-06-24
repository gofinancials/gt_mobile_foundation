import 'dart:async';

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock implementation of [AppStorageService] used primarily for testing,
/// development, or preview environments where persistent local storage is not required.
///
/// This service keeps all data in an ephemeral, in-memory `Map`. All data is lost
/// when the application is closed or restarted.
class AppMockStorageService extends AppStorageService {
  /// The underlying in-memory map storing all mocked storage data.
  final _storage = <String, String?>{};

  @override
  Future<Map<String, String?>> getItems(List<String> keys) async {
    try {
      final result = await Future.wait(keys.map((it) => _getItemMap(it)));
      return result.fold<Map<String, String?>>({}, (previous, element) {
        return previous..addAll(element);
      });
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return {};
    }
  }

  /// Internal helper to retrieve a single key and format it as a map entry.
  Future<Map<String, String?>> _getItemMap(String key) async {
    final value = await getItem(key);
    return {key: value};
  }

  @override
  Future<String?> getItem(String key) async {
    return _storage[key];
  }

  @override
  Future<void> setItem(String key, String data) async {
    _storage[key] = data;
  }

  @override
  Future<void> removeItem(String key) async {
    _storage.remove(key);
  }

  @override
  Future<bool> hasItem(String key) async {
    return _storage.containsKey(key);
  }

  /// Registers a callback to watch for changes.
  ///
  /// **Note**: In this mock implementation, `watchItem` is intentionally a no-op
  /// as the underlying `Map` does not support stream-based listening out of the box.
  @override
  void watchItem(String key, [void Function(String? value)? onChanged]) {}

  @override
  Future<void> setItems(Map<String, String> items) async {
    _storage.addAll(items);
  }

  @override
  Future<void> removeItems(List<String> keys) async {
    _storage.removeWhere((key, value) => keys.contains(key));
  }

  /// Clears all data from the in-memory map.
  @override
  Future<void> clearDb() async {
    _storage.clear();
  }

  /// Closes the database by clearing all in-memory data.
  @override
  Future<void> closeDb() async {
    clearDb();
  }
}
