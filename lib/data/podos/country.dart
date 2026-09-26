import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

// ignore: must_be_immutable
/// {@category Data}
/// A model class representing a country and its metadata (e.g., dial code, ISO code, flags).
class Country extends Equatable {
  final String? countryId;
  final String? capital;
  final String? continent;
  final String? countryName;
  final String? dS;
  final String? dial;
  final String? eDGAR;
  final String? fIFA;
  final String? fIPS;
  final String? gAUL;
  final String? geoNameID;
  final String? iOC;
  final String? iSO31661Alpha2;
  final String? iSO31661Alpha3;
  final String? iSO4217CurrencyAlphabeticCode;
  final String? iSO4217CurrencyCountryName;
  final int? iSO4217CurrencyMinorUnit;
  final String? iSO4217CurrencyName;
  final int? iSO4217CurrencyNumericCode;
  final String? iTU;
  final String? isIndependent;
  final String? languages;
  final int? m49;
  final String? mARC;

  /// The number of digits a mobile number can have after the country calling
  /// code, with no trunk `0` — `[10]` for Nigeria, `[9]` for Ghana, `[10, 11]`
  /// for Germany. `null` where no numbering plan is published.
  ///
  /// Measured from the ITU calling code, so for the North American entries
  /// whose [dial] carries an area code (`1-876`) the area code is counted.
  ///
  /// Sourced from Google's libphonenumber metadata (Apache-2.0).
  final List<int>? mobileNumberLengths;
  final String? officialNameEnglish;
  final String? tLD;
  final String? wMO;

  const Country({
    this.countryId,
    this.capital,
    this.continent,
    this.countryName,
    this.dS,
    this.dial,
    this.eDGAR,
    this.fIFA,
    this.fIPS,
    this.gAUL,
    this.geoNameID,
    this.iOC,
    this.iSO31661Alpha2,
    this.iSO31661Alpha3,
    this.iSO4217CurrencyAlphabeticCode,
    this.iSO4217CurrencyCountryName,
    this.iSO4217CurrencyMinorUnit,
    this.iSO4217CurrencyName,
    this.iSO4217CurrencyNumericCode,
    this.iTU,
    this.isIndependent,
    this.languages,
    this.m49,
    this.mARC,
    this.mobileNumberLengths,
    this.officialNameEnglish,
    this.tLD,
    this.wMO,
  });

  String? get isoCode {
    return iSO31661Alpha2 ?? mARC;
  }

  String get countryCode {
    if (dial == null) return "";
    if (dial.value.startsWith("+")) return dial!;
    return "+$dial";
  }

  String get combinedNameAndCode {
    return "${isoCode?.toUpperCase() ?? ''} ($countryCode)";
  }

  String get displayName {
    return countryName ?? officialNameEnglish ?? combinedNameAndCode;
  }

  String get rasterFlagUrl {
    if (!isoCode.hasValue) return "";
    return "https://flagcdn.com/w40/${isoCode?.lower ?? 'ng'}.webp";
  }

  String get circleSvgFlagUrl {
    if (!isoCode.hasValue) return "";
    return "https://hatscripts.github.io/circle-flags/flags/${isoCode?.lower ?? 'ng'}.svg";
  }

  String get svgFlagUrl {
    if (!isoCode.hasValue) return "";
    return "https://flagcdn.com/${isoCode?.lower ?? 'ng'}.svg";
  }

  factory Country.fromJson(Map json) {
    final numCode =
        (json['ISO4217_Currency_Numeric_Code'] ??
        json['ISO4217CurrencyNumericCode']);
    return Country(
      countryId: json['CountryId'],
      capital: json['Capital'],
      continent: json['Continent'],
      countryName: json['Country_Name'] ?? json['CountryName'],
      dS: json['DS'],
      dial: json['Dial'],
      eDGAR: json['EDGAR'],
      fIFA: json['FIFA'],
      fIPS: json['FIPS'],
      gAUL: json['GAUL'],
      geoNameID: json['Geo_Name_ID'] ?? json["GeoNameId"],
      iOC: json['IOC'],
      iSO31661Alpha2: json['ISO3166_1_Alpha_2'],
      iSO31661Alpha3: json['ISO3166_1_Alpha_3'],
      iSO4217CurrencyAlphabeticCode:
          json['ISO4217_Currency_Alphabetic_Code'] ??
          json['ISO4217CurrencyAlphabeticCode'],
      iSO4217CurrencyCountryName: json['ISO4217_Currency_Country_Name'],
      iSO4217CurrencyMinorUnit: json['ISO4217_Currency_Minor_Unit'],
      iSO4217CurrencyName: json['ISO4217_Currency_Name'],
      iSO4217CurrencyNumericCode: numCode is int?
          ? numCode
          : int.tryParse(numCode),
      iTU: json['ITU'],
      isIndependent: json['Is_Independent'],
      languages: json['Languages'],
      m49: json['M49'],
      mARC: json['MARC'],
      mobileNumberLengths: _parseLengths(
        json['Mobile_Number_Lengths'] ?? json['MobileNumberLengths'],
      ),
      officialNameEnglish:
          json['Official_Name_English'] ?? json['officialNameEnglish'],
      tLD: json['TLD'],
      wMO: json['WMO'],
    );
  }

  static List<int>? _parseLengths(dynamic lengths) {
    if (lengths is! List) return null;
    return List.unmodifiable(lengths.whereType<num>().map((it) => it.toInt()));
  }

  @override
  List<Object?> get props => [
    countryName,
    capital,
    capital,
    dial,
    iSO31661Alpha2,
    tLD,
    mARC,
  ];
}
