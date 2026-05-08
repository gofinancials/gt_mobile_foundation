import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Configuration}
/// Base configuration interface that provides core application settings.
///
/// Implementing this class allows overriding essential configurations
/// such as API endpoints, application metadata, and environment flags.
abstract class AppConfig {
  /// The optional specific window size for desktop/web environments.
  Size? windowSize;

  /// The default language code (e.g., 'en', 'fr') for the application.
  String get defaultLanguageCode;

  /// The unique identifier for the application (e.g., bundle ID or package name).
  String get appId;

  /// The localized or display name of the application.
  String get appName;

  /// The default database name used for local storage.
  String get dbName;

  /// The URL scheme for deep linking (e.g., `myapp://`).
  String get scheme;

  /// The base URL for network requests.
  String get baseUrl;

  /// The default [Locale] used before any user preferences are applied.
  Locale get defaultLocale;

  /// Indicates whether the app is running in a mocked/development environment.
  bool get isMock;

  /// The list of [Locale]s supported by the application.
  List<Locale> get supportedLocales;

  /// The URL endpoint for the terms of use page.
  String get termsOfUseUrl;

  /// The URL endpoint for the about us page.
  String get aboutUsUrl;

  /// The URL endpoint for the privacy policy page.
  String get privacyUrl;

  /// The URL endpoint for the support or help center page.
  String get supportUrl;

  /// The list of allowed hosts for web app functionality.
  List<String> get webAppHosts;

  /// The default country code for the application.
  String get countryCode;

  /// A collection of localized strings used globally across the foundation.
  AppConfigStrings get strings;

  /// The cipher key used for crypto operations. Can be asynchronous.
  FutureOr<String> get cipherKey;

  /// The initialization vector (IV) used for crypto operations. Can be asynchronous.
  FutureOr<String> get cipherIV;

  /// The optional asset path to the RSA public key.
  String? get rsaPublicKeyPath;
}
