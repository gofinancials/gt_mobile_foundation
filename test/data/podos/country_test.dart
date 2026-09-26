import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('Country.mobileNumberLengths', () {
    test('reads the lengths from the asset key', () {
      final country = Country.fromJson({
        'Dial': '49',
        'Mobile_Number_Lengths': [10, 11],
      });

      expect(country.mobileNumberLengths, [10, 11]);
    });

    test('reads the lengths from the camel-case key', () {
      final country = Country.fromJson({
        'Dial': '233',
        'MobileNumberLengths': [9],
      });

      expect(country.mobileNumberLengths, [9]);
    });

    test('is null when the lengths are absent', () {
      final country = Country.fromJson({'Dial': '672'});

      expect(country.mobileNumberLengths, isNull);
    });

    test('is null when the lengths are null', () {
      final country = Country.fromJson({
        'Dial': '672',
        'Mobile_Number_Lengths': null,
      });

      expect(country.mobileNumberLengths, isNull);
    });

    test('carries the bundled lengths for known countries', () {
      final raw = File('assets/resources/countries.json').readAsStringSync();
      final countries = [
        for (final it in jsonDecode(raw) as List) Country.fromJson(it as Map),
      ];
      List<int>? lengthsOf(String iso) {
        return countries
            .firstWhere((it) => it.isoCode == iso)
            .mobileNumberLengths;
      }

      expect(lengthsOf('NG'), [10]);
      expect(lengthsOf('GH'), [9]);
      expect(lengthsOf('GB'), [10]);
      expect(lengthsOf('DE'), [10, 11]);
      expect(lengthsOf('AQ'), isNull);
    });
  });

  group('countries.json', () {
    final raw = File('assets/resources/countries.json').readAsStringSync();
    final countries = [
      for (final it in jsonDecode(raw) as List) Country.fromJson(it as Map),
    ];

    test('every dial is a calling code, with optional area codes', () {
      final wellFormed = RegExp(r'^\d{1,3}(-\d+)?(,\d{1,3}-\d+)*$');

      for (final country in countries) {
        expect(country.dial, matches(wellFormed), reason: country.countryName);
      }
    });

    test('agrees with the lengths published by calling code', () {
      for (final country in countries) {
        final lengths = country.mobileNumberLengths;
        if (lengths == null) continue;

        final callingCode = country.dial!.split(RegExp('[-,]')).first;
        expect(
          AppPhoneLengths.mobileByCallingCode[callingCode],
          containsAll(lengths),
          reason: country.countryName,
        );
      }
    });
  });
}
