/// {@category Configuration}
/// Defines localized or configurable strings used commonly across the framework.
///
/// Providing an instance of this class to [AppConfig] allows custom phrasing
/// and translation keys for common messages, errors, and time formatting.
class AppConfigStrings {
  /// String representation for seconds (e.g., 'seconds').
  final String seconds;

  /// String representation for minutes (e.g., 'minutes').
  final String minutes;

  /// Error message for a generic unexpected failure.
  final String requestFailedUnexpectedly;

  /// Error message prompting the user to check their network connection.
  final String checkNetwork;

  /// Error message indicating no internet connection.
  final String noInternet;

  /// Time ago formatting for moments ago (e.g., 'Moments ago').
  final String momentsAgo;

  /// Time ago formatting for minutes ago (e.g., '{} minutes ago').
  final String minutesAgo;

  /// Time ago formatting for an hour ago (e.g., 'An hour ago').
  final String anHourAgo;

  /// Time ago formatting for hours ago (e.g., '{} hours ago').
  final String hoursAgo;

  /// Time ago formatting for days ago (e.g., '{} days ago').
  final String daysAgo;

  /// Age formatting for days old.
  final String daysOld;

  /// Age formatting for weeks old.
  final String weeksOld;

  /// Age formatting for months old.
  final String monthsOld;

  /// Age formatting for years old.
  final String yearsOld;

  /// Time formatting for yesterday.
  final String yesterday;

  /// Validation message for a required field.
  final String fieldRequired;

  /// Validation message for minimum length.
  final String minLength;

  /// Validation message for maximum length.
  final String maxLength;

  /// Validation message for a required password field.
  final String passwordRequired;

  /// Validation message for password minimum character constraint.
  final String passwordMustHaveNChars;

  /// Validation message for an invalid email format.
  final String invalidEmail;

  /// Validation message prompting for a valid email.
  final String provideValidEmail;

  /// Validation message for an invalid phone number.
  final String invalidPhone;

  /// Validation message for an invalid date format.
  final String invalidDate;

  /// Validation message requiring a minimum age.
  final String mustBeNYears;

  /// Validation message for an invalid URL format.
  final String invalidUrl;

  /// Validation message for an invalid monetary amount.
  final String invalidAmount;

  /// Validation message for an amount below the minimum allowed.
  final String amountMinimum;

  /// Validation message for an amount above the maximum allowed.
  final String amountMaximum;

  /// Error message indicating insufficient funds.
  final String insufficentFunds;

  /// Validation message when matching fields do not match (e.g., passwords).
  final String fieldsDontMatch;

  /// Validation message for an invalid generic number.
  final String invalidNumber;

  /// Creates an [AppConfigStrings] instance containing localized validation and error messages.
  const AppConfigStrings({
    required this.seconds,
    required this.minutes,
    required this.requestFailedUnexpectedly,
    required this.checkNetwork,
    required this.noInternet,
    required this.momentsAgo,
    required this.minutesAgo,
    required this.anHourAgo,
    required this.hoursAgo,
    required this.daysAgo,
    required this.daysOld,
    required this.weeksOld,
    required this.monthsOld,
    required this.yearsOld,
    required this.yesterday,
    required this.fieldRequired,
    required this.passwordRequired,
    required this.passwordMustHaveNChars,
    required this.invalidEmail,
    required this.provideValidEmail,
    required this.invalidPhone,
    required this.invalidDate,
    required this.mustBeNYears,
    required this.invalidUrl,
    required this.invalidAmount,
    required this.amountMinimum,
    required this.amountMaximum,
    required this.fieldsDontMatch,
    required this.invalidNumber,
    required this.minLength,
    required this.maxLength,
    required this.insufficentFunds,
  });
}
