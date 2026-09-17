import 'package:gt_mobile_foundation/foundation.dart';

/// Minimal [AppConfig] exposing only what foundation utilities read; every
/// other member returns null.
///
/// Registered by [registerTestConfig] so validators and helpers that read
/// `locator<AppConfig>().strings` resolve. Each string is its own locale key,
/// which is what an uninitialised `tr()` returns, so tests assert on the key.
class _TestConfig implements AppConfig {
  /// Non-null because [noSuchMethod] returning null for a non-nullable getter
  /// throws; the phone canonicaliser reads it.
  @override
  String get countryCode => '+234';

  @override
  AppConfigStrings get strings => const AppConfigStrings(
    seconds: 'seconds',
    minutes: 'minutes',
    requestFailedUnexpectedly: 'requestFailedUnexpectedly',
    checkNetwork: 'checkNetwork',
    noInternet: 'noInternet',
    momentsAgo: 'momentsAgo',
    minutesAgo: 'minutesAgo',
    anHourAgo: 'anHourAgo',
    hoursAgo: 'hoursAgo',
    daysAgo: 'daysAgo',
    daysOld: 'daysOld',
    weeksOld: 'weeksOld',
    monthsOld: 'monthsOld',
    yearsOld: 'yearsOld',
    yesterday: 'yesterday',
    fieldRequired: 'fieldRequired',
    exactLength: 'exactLength',
    passwordRequired: 'passwordRequired',
    passwordMustHaveNChars: 'passwordMustHaveNChars',
    invalidEmail: 'invalidEmail',
    provideValidEmail: 'provideValidEmail',
    invalidPhone: 'invalidPhone',
    invalidDate: 'invalidDate',
    mustBeNYears: 'mustBeNYears',
    invalidUrl: 'invalidUrl',
    invalidAmount: 'invalidAmount',
    amountMinimum: 'amountMinimum',
    amountMaximum: 'amountMaximum',
    fieldsDontMatch: 'fieldsDontMatch',
    invalidNumber: 'invalidNumber',
    minLength: 'minLength',
    maxLength: 'maxLength',
    insufficentFunds: 'insufficentFunds',
    copiedFromClipboard: 'copiedFromClipboard',
    copiedToClipboard: 'copiedToClipboard',
    requestTimedOut: 'requestTimedOut',
    secureConnectionFailed: 'secureConnectionFailed',
    requestCancelled: 'requestCancelled',
    requestRefused: 'requestRefused',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Registers [_TestConfig] once for the current test binding.
void registerTestConfig() {
  if (locator.isRegistered<AppConfig>()) return;
  locator.registerSingleton<AppConfig>(_TestConfig());
}
