import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class AppCountryUtility {
  static List<Country> _countries = [];

  static Future<List<Country>> fetchCountries() async {
    try {
      if (_countries.hasValue) return _countries;

      dynamic req = await rootBundle.loadString(
        'assets/resources/countries.json',
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
