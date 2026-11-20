import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Utilities}
/// A utility class for fetching and searching Nigerian states, their local
/// government areas (LGAs) and towns.
///
/// State names are matched case-insensitively and ignore surrounding spaces,
/// so `" akwa ibom"` finds `Akwa Ibom`. Searches are case-insensitive
/// substring matches; an empty query returns everything.
class AppNigerianStateUtility {
  static const _resources = 'packages/gt_mobile_foundation/assets/resources';
  static const _assetPath = '$_resources/states_lgs_towns.json';

  static List<NigerianState> _states = [];

  /// Fetches every Nigerian state from the local JSON asset.
  ///
  /// Caches the result in memory for subsequent calls.
  static Future<List<NigerianState>> fetchStates() async {
    try {
      if (_states.hasValue) return _states;

      final raw = await rootBundle.loadString(_assetPath, cache: true);
      final List rawData = (await AppHelpers.parseJson(raw)) ?? [];
      final List<NigerianState> states = [];

      for (var it in rawData) {
        states.tryAdd(NigerianState.fromJson(Map.from(it)));
      }
      _states = states;

      return states;
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return [];
    }
  }

  /// Searches for states whose name or capital matches [query].
  static Future<List<NigerianState>> searchStates(String query) async {
    final states = await fetchStates();

    return states.whereList((it) {
      final matchesName = it.name.includes(query);
      final matchesCapital = it.capital?.includes(query) ?? false;

      return matchesName || matchesCapital;
    });
  }

  /// Returns the state named [stateName], or `null` if there is none.
  static Future<NigerianState?> findState(String stateName) async {
    final states = await fetchStates();

    return states.tryFirstWhere((it) => it.name.equals(stateName));
  }

  /// Returns the state that has an LGA named [lgaName], or `null` if none does.
  static Future<NigerianState?> findStateByLga(String lgaName) async {
    final states = await fetchStates();

    return states.tryFirstWhere((it) => _hasName(it.lgas, lgaName));
  }

  /// Returns the LGAs of the state named [stateName], or an empty list if
  /// there is no such state.
  static Future<List<String>> fetchLgas(String stateName) async {
    final state = await findState(stateName);

    return state?.lgas ?? [];
  }

  /// Searches the LGAs of the state named [stateName] for [query].
  static Future<List<String>> searchLgas(String stateName, String query) async {
    final lgas = await fetchLgas(stateName);

    return lgas.whereList((it) => it.includes(query));
  }

  /// Returns the towns of the state named [stateName], or an empty list if
  /// there is no such state.
  static Future<List<String>> fetchTowns(String stateName) async {
    final state = await findState(stateName);

    return state?.towns ?? [];
  }

  /// Searches the towns of the state named [stateName] for [query].
  static Future<List<String>> searchTowns(
    String stateName,
    String query,
  ) async {
    final towns = await fetchTowns(stateName);

    return towns.whereList((it) => it.includes(query));
  }

  static bool _hasName(List<String> names, String name) {
    return names.any((it) => it.equals(name));
  }
}
