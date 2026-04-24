import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// A utility class for fetching and searching country data.
class AppCountryUtility {
  static List<Country> _countries = [];

  /// Fetches a list of countries from the local JSON asset.
  ///
  /// Caches the result in memory for subsequent calls.
  static Future<List<Country>> fetchCountries() async {
    try {
      if (_countries.hasValue) return _countries;

      dynamic req = await rootBundle.loadString(
        'packages/gt_mobile_foundation/assets/resources/countries.json',
        cache: true,
      );
      List rawData = await AppHelpers.parseJson(req);
      List<Country> countries = [];

      for (var it in rawData) {
        countries.tryAdd(Country.fromJson(Map.from(it)));
      }
      _countries = countries;

      return countries;
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return [];
    }
  }

  /// Searches for countries matching the given [query].
  ///
  /// Matches against both country name and country code.
  static Future<List<Country>> searchCountries(String query) async {
    try {
      if (!_countries.hasValue) await fetchCountries();

      return _countries.whereList((it) {
        final matchesName = it.countryName?.includes(query) ?? false;
        final matchesCode = "+${it.countryCode}".includes(query);

        return matchesName || matchesCode;
      });
    } catch (e, t) {
      AppLogger.severe("$e", error: e, stackTrace: t);
      return [];
    }
  }
}
