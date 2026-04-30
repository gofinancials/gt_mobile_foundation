import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

abstract class AppConfig {
  Size? windowSize;

  String get defaultLanguageCode;

  String get appId;

  String get appName;

  String get dbName;

  String get scheme;

  String get baseUrl;

  Locale get defaultLocale;

  bool get isMock;

  List<Locale> get supportedLocales;

  String get termsOfUseUrl;

  String get aboutUsUrl;

  String get privacyUrl;

  String get supportUrl;

  List<String> get webAppHosts;

  String get countryCode;

  AppConfigStrings get strings;

  FutureOr<String> get cipherKey;

  FutureOr<String> get cipherIV;

  String? get rsaPublicKeyPath;
}
