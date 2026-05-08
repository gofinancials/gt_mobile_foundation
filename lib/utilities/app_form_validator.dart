import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Utilities}
/// Provides a comprehensive suite of static methods for validating form inputs
/// such as emails, passwords, dates, amounts, and custom regex patterns.
class AppValidators {
  static bool _isEmpty(String? text) => !text.hasValue;

  static AppConfigStrings get strings {
    return locator<AppConfig>().strings;
  }

  /// Validates a [password] ensuring it's not empty and meets the [minLength] requirement.
  static String? passwordValidator(
    String? password, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
    int minLength = 3,
  }) {
    final isEmpty = _isEmpty(password);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.passwordRequired.tr();
    }

    if ((password?.length ?? 0) < minLength) {
      return errorMessage ??
          strings.passwordMustHaveNChars.tr({"num": "$minLength"});
    }

    return null;
  }

  /// Validates that [base] matches [comparison].
  static String? matchValidator(
    String? base,
    String? comparison, {
    String? errorMessage,
    String? emptyMessage,

    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(base);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    if (base != comparison) return errorMessage ?? strings.fieldsDontMatch.tr();

    return null;
  }

  /// Validates the [email] format using regex.
  static String? emailValidator(
    String? email, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(email);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    if (!AppRegex.mailRegEx.hasMatch(email!)) {
      return errorMessage ?? strings.provideValidEmail.tr();
    }

    return null;
  }

  /// Validates the [url] format using regex.
  static String? urlValidator(
    String? url, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(url);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    if (!AppRegex.urlRegex.hasMatch(url!)) {
      return errorMessage ?? strings.invalidUrl.tr();
    }

    return null;
  }

  /// Validates the [tel] (phone number) format using regex.
  static String? phoneValidator(
    String? tel, {
    String? errorMessage,
    String? emptyMessage,
    String countryCode = "",
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(tel);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    if (!AppRegex.phoneRegex.hasMatch("$countryCode$tel")) {
      return errorMessage ?? strings.invalidPhone.tr();
    }
    return null;
  }

  /// Validates that a parsed [date] meets the [minAge] requirement.
  static String? dobValidator(
    String? date, {
    String? errorMessage,
    String? emptyMessage,
    int minAge = 18,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(date);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    final parsedDate = DateTime.tryParse(date ?? '');

    if (parsedDate == null) return errorMessage ?? strings.invalidDate.tr();

    final now = DateTime.now();

    final yearsSinceDate = (now.difference(parsedDate).inDays / 365);

    if (yearsSinceDate < minAge) {
      return errorMessage ?? strings.mustBeNYears.tr({"age": "$minAge"});
    }

    return null;
  }

  /// Validates a [date] string, optionally ensuring it is greater/less than [otherDate].
  static String? dateValidator(
    String? date, {
    String? errorMessage,
    String? emptyMessage,
    String? otherDate,
    bool? shouldBeGreaterThan,
    String? comparisonErrorMessage,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(date);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    final parsedDate = DateTime.tryParse(date ?? '');

    if (parsedDate == null) return errorMessage ?? strings.invalidDate.tr();

    if (!_isEmpty(otherDate) && shouldBeGreaterThan != null) {
      final parsedOtherDate = DateTime.tryParse(otherDate ?? '');

      if (parsedOtherDate == null) return null;

      final defaultErrorMessage =
          comparisonErrorMessage ?? errorMessage ?? strings.invalidDate.tr();

      String? message;

      if (shouldBeGreaterThan) {
        final isGreaterThan = parsedDate >= parsedOtherDate;

        message = isGreaterThan ? null : defaultErrorMessage;
      }

      if (!shouldBeGreaterThan) {
        final isLessThan = parsedDate <= parsedOtherDate;

        message = isLessThan ? null : defaultErrorMessage;
      }

      return message;
    }

    return null;
  }

  /// Validates that [data] is not empty.
  static String? required(
    String? data, {
    String? errorMessage,
    String? emptyMessage,
  }) {
    bool isEmpty = _isEmpty(data);

    if (isEmpty) return emptyMessage ?? strings.fieldRequired.tr();

    return null;
  }

  /// Validates that the [data] list is not empty.
  static String? requiredList(
    List? data, {
    String? errorMessage,
    String? emptyMessage,
  }) {
    final isEmpty = !data.hasValue;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    return null;
  }

  /// Validates that [name] is not empty.
  static String? nameValidator(
    String? name, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(name);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    return null;
  }

  /// Validates that [value] parses to a valid amount within [minAmount] and [maxAmount].
  static String? amountValidator(
    String? value, {
    String? errorMessage,
    String? emptyMessage,
    num? minAmount,
    num? maxAmount,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(value);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    final num? amount = AppHelpers.extractAmount(value);
    if (amount == null) {
      return errorMessage ?? strings.invalidAmount.tr();
    }
    if (minAmount != null && amount < minAmount) {
      final min = AppTextFormatter.formatCurrency(minAmount);
      return errorMessage ?? strings.amountMinimum.tr({"amount": min});
    }
    if (maxAmount != null && amount > maxAmount) {
      final max = AppTextFormatter.formatCurrency(maxAmount);
      return errorMessage ?? strings.amountMaximum.tr({"amount": max});
    }
    return null;
  }

  /// Validates that the numeric [value] does not exceed the provided [balance].
  static String? balanceValidator(
    String? value, {
    String? errorMessage,
    String? emptyMessage,
    required num balance,
  }) {
    final isEmpty = _isEmpty(value);

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    final num? amount = AppHelpers.extractAmount(value);
    if (amount == null) {
      return errorMessage ?? strings.invalidAmount.tr();
    }
    if (amount > balance) {
      return errorMessage ?? strings.insufficentFunds.tr();
    }
    return null;
  }

  /// Validates that [value] parses successfully to a numeric digit.
  static String? digitValidator(
    String? value, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(value);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }
    final num? amount = AppHelpers.extractAmount(value);
    if (amount == null) {
      return errorMessage ?? strings.invalidNumber.tr();
    }
    return null;
  }

  /// Validates that [text] meets the minimum [length] requirement.
  static String? minLength(
    String? text, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
    int length = 6,
  }) {
    final isEmpty = _isEmpty(text?.trim());

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    if ((text?.trim().length ?? 0) < length) {
      return errorMessage ?? strings.minLength.tr({"num": "$length"});
    }

    return null;
  }

  /// Validates that [text] does not exceed the maximum [length] requirement.
  static String? maxLength(
    String? text, {
    String? errorMessage,
    String? emptyMessage,
    bool isRequired = true,
    int length = 6,
  }) {
    final isEmpty = _isEmpty(text);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return emptyMessage ?? strings.fieldRequired.tr();
    }

    if ((text?.length ?? 0) > length) {
      return errorMessage ?? strings.maxLength.tr({"num": "$length"});
    }

    return null;
  }

  /// Validates the credit card expiry [text] is not in the past.
  static String? cardExpiryValidator(
    String? text, {
    String? errorMessage,
    String? emptyMessage,
  }) {
    if (!text.hasValue) return emptyMessage ?? strings.fieldRequired.tr();

    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month);
    final parsedDate = text?.fromCardExpiryTextToDate;

    if (parsedDate == null) return errorMessage ?? strings.invalidDate.tr();

    final isAfterNow = parsedDate >= now;

    if (!isAfterNow) return errorMessage ?? strings.invalidDate.tr();

    return null;
  }

  /// Validates the credit [text] (card number) format based on known card regex patterns.
  static String? cardNumberValidator(
    String? text, {
    required String errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final number = text.value.withoutWhiteSpaceAndSpecialChar;
    final isEmpty = _isEmpty(number);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) return emptyMessage ?? strings.fieldRequired.tr();

    if (AppRegex.masterRegex.hasMatch(number)) return null;
    if (AppRegex.visaRegex.hasMatch(number)) return null;
    if (AppRegex.maestroRegex.hasMatch(number)) return null;
    if (AppRegex.jcbRegex.hasMatch(number)) return null;
    if (AppRegex.unionpayRegex.hasMatch(number)) return null;
    if (AppRegex.amexRegex.hasMatch(number)) return null;

    return errorMessage;
  }

  /// Validates the credit card [text] (CVV) format.
  static String? cvvValidator(
    String? text, {
    required String errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final number = text.value.withoutWhiteSpaceAndSpecialChar;
    final isEmpty = _isEmpty(number);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) return emptyMessage ?? strings.fieldRequired.tr();

    if (AppRegex.cvvRegex.hasMatch(number)) return null;

    return errorMessage;
  }

  /// Validates the [text] matches the standard Nigerian BVN format.
  static String? bvnValidator(
    String? text, {
    required String errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final number = text.value.withoutWhiteSpaceAndSpecialChar;
    final isEmpty = _isEmpty(number);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) return emptyMessage ?? strings.fieldRequired.tr();

    if (AppRegex.bvnRegex.hasMatch(number)) return null;

    return errorMessage;
  }

  /// Validates the [text] matches the standard Nigerian NUBAN format.
  static String? nubanValidator(
    String? text, {
    required String errorMessage,
    String? emptyMessage,
    bool isRequired = true,
  }) {
    final number = text.value.withoutWhiteSpaceAndSpecialChar;
    final isEmpty = _isEmpty(number);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) return emptyMessage ?? strings.fieldRequired.tr();

    if (AppRegex.nubanRegex.hasMatch(number)) return null;

    return errorMessage;
  }
}
