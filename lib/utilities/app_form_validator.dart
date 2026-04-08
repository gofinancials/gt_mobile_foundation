import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class AppValidators {
  static bool _isEmpty(String? text) => !text.hasValue;

  static AppConfigStrings get strings {
    return locator<AppConfig>().strings;
  }

  static String? passwordValidator(
    String? password, {
    bool isRequired = true,
    int minLength = 3,
  }) {
    final isEmpty = _isEmpty(password);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.passwordRequired.tr();
    }

    if ((password?.length ?? 0) < minLength) {
      return strings.passwordMustHaveNChars.tr({"num": "$minLength"});
    }

    return null;
  }

  static String? matchValidator(
    String? base,
    String? comparison, {
    String? message,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(base);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    if (base != comparison) return message ?? strings.fieldsDontMatch.tr();

    return null;
  }

  static String? emailValidator(String? email, {bool isRequired = true}) {
    final isEmpty = _isEmpty(email);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    if (!AppRegex.mailRegEx.hasMatch(email!)) {
      return strings.provideValidEmail.tr();
    }

    return null;
  }

  static String? urlValidator(String? url, {bool isRequired = true}) {
    final isEmpty = _isEmpty(url);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    if (!AppRegex.urlRegex.hasMatch(url!)) {
      return strings.invalidUrl.tr();
    }

    return null;
  }

  static String? phoneValidator(
    String? tel, {
    String countryCode = "",
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(tel);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    if (!AppRegex.phoneRegex.hasMatch("$countryCode$tel")) {
      return strings.invalidPhone.tr();
    }
    return null;
  }

  static String? dobValidator(
    String? date, {
    int minAge = 18,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(date);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    final parsedDate = DateTime.tryParse(date ?? '');

    if (parsedDate == null) return strings.invalidDate.tr();

    final now = DateTime.now();

    final yearsSinceDate = (now.difference(parsedDate).inDays / 365);

    if (yearsSinceDate < minAge) {
      return strings.mustBeNYears.tr({"age": "$minAge"});
    }

    return null;
  }

  static String? dateValidator(
    String? date, {
    String? otherDate,
    bool? shouldBeGreaterThan,
    String? comparisonErrorMessage,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(date);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    final parsedDate = DateTime.tryParse(date ?? '');

    if (parsedDate == null) return strings.invalidDate.tr();

    if (!_isEmpty(otherDate) && shouldBeGreaterThan != null) {
      final parsedOtherDate = DateTime.tryParse(otherDate ?? '');

      if (parsedOtherDate == null) return null;

      final defaultErrorMessage =
          comparisonErrorMessage ?? strings.invalidDate.tr();

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

  static String? required(String? data) {
    bool isEmpty = _isEmpty(data);

    if (isEmpty) return strings.fieldRequired.tr();

    return null;
  }

  static String? requiredList(List? data) {
    final isEmpty = !data.hasValue;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    return null;
  }

  static String? nameValidator(String? name, {bool isRequired = true}) {
    final isEmpty = _isEmpty(name);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    return null;
  }

  static String? amountValidator(
    String? value, {
    num? minAmount,
    num? maxAmount,
    bool isRequired = true,
  }) {
    final isEmpty = _isEmpty(value);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }

    final num? amount = AppHelpers.extractAmount(value);
    if (amount == null) {
      return strings.invalidAmount.tr();
    }
    if (minAmount != null && amount < minAmount) {
      final min = AppTextFormatter.formatCurrency(minAmount);
      return strings.amountMinimum.tr({"amount": min});
    }
    if (maxAmount != null && amount > maxAmount) {
      final max = AppTextFormatter.formatCurrency(maxAmount);
      return strings.amountMaximum.tr({"amount": max});
    }
    return null;
  }

  static String? digitValidator(String? value, {bool isRequired = true}) {
    final isEmpty = _isEmpty(value);

    if (!isRequired && isEmpty) return null;

    if (isEmpty) {
      return strings.fieldRequired.tr();
    }
    final num? amount = AppHelpers.extractAmount(value);
    if (amount == null) {
      return strings.invalidNumber.tr();
    }
    return null;
  }
}
