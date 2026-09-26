import 'package:flutter/widgets.dart';

import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:intl/intl.dart';

/// {@category Utilities}
/// A centralized utility class for formatting text, numbers, currencies, dates,
/// and phone numbers according to the app's locale and configuration settings.
class AppTextFormatter {
  static Locale? locale;

  static AppConfigStrings get strings {
    return locator<AppConfig>().strings;
  }

  static String? get _locale {
    if (locale == null) return null;
    return "$locale";
  }

  static String? get languageCode => locale?.languageCode.upper;

  /// Formats the given [tel] string as a standardized phone number layout.
  static String formatPhone(String tel) {
    String digits = tel.withoutWhiteSpaceAndSpecialChar;
    digits = digits.replaceAll(AppRegex.nonDigits, '');
    if (digits.isEmpty) return tel.trim();

    bool hasPlus = tel.trim().startsWith('+');
    String prefix = hasPlus ? '+' : '';

    if (digits.length <= 4) {
      return '$prefix$digits';
    }

    switch (digits.length) {
      case 5:
        return '$prefix${digits.substring(0, 3)} ${digits.substring(3)}';
      case 6:
        return '$prefix${digits.substring(0, 3)} ${digits.substring(3)}';
      case 7:
        return '$prefix${digits.substring(0, 3)} ${digits.substring(3)}';
      case 8:
        return '$prefix${digits.substring(0, 4)} ${digits.substring(4)}';
      case 9:
        return '$prefix${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      case 10:
        return '$prefix${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      case 11:
        return '$prefix${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
      default:
        List<String> chunks = [];
        chunks.add(digits.substring(0, 3));
        int remaining = digits.length - 3;
        int offset = 3;

        while (remaining > 0) {
          if (remaining == 4) {
            chunks.add(digits.substring(offset, offset + 4));
            break;
          } else if (remaining == 7) {
            chunks.add(digits.substring(offset, offset + 3));
            chunks.add(digits.substring(offset + 3, offset + 7));
            break;
          } else if (remaining == 8) {
            chunks.add(digits.substring(offset, offset + 4));
            chunks.add(digits.substring(offset + 4, offset + 8));
            break;
          } else if (remaining >= 3) {
            chunks.add(digits.substring(offset, offset + 3));
            offset += 3;
            remaining -= 3;
          } else {
            chunks.add(digits.substring(offset));
            break;
          }
        }
        return "$prefix${chunks.join(' ')}";
    }
  }

  /// The dial code to canonicalise against, as the app configured it.
  ///
  /// Taken from [AppConfig.countryCode], which apps already configure, so the
  /// library carries no country of its own.
  static String get _dialCode => locator<AppConfig>().countryCode;

  /// The ITU calling code in [dial], as digits only: `234` for `+234`, and
  /// `1` for the North American `+1-876` or `1-809,1-829,1-849`, which carry
  /// area codes after the calling code.
  static String _callingCode(String dial) {
    final entry = dial.split(',').first;
    return entry.split('-').first.replaceAll(AppRegex.nonDigits, '');
  }

  /// The single area code [dial] carries after its calling code, `876` for
  /// `+1-876`, or empty when it carries none or several.
  static String _areaCode(String dial) {
    if (dial.contains(',')) return '';

    final parts = dial.split('-');
    if (parts.length < 2) return '';

    return parts[1].replaceAll(AppRegex.nonDigits, '');
  }

  /// The national lengths to accept: [nationalLength] when the caller gives
  /// one, otherwise the mobile lengths published for [callingCode], otherwise
  /// ten.
  static List<int> _nationalLengths(String callingCode, int? nationalLength) {
    if (nationalLength != null) return [nationalLength];
    return AppPhoneLengths.mobileByCallingCode[callingCode] ?? const [10];
  }

  static bool _isNational(String digits, List<int> lengths) {
    return lengths.contains(digits.length);
  }

  static bool _isTrunked(String digits, List<int> lengths) {
    return digits.startsWith('0') && lengths.contains(digits.length - 1);
  }

  /// [digits] without a leading [callingCode], stripped only when what
  /// remains is itself a plausible national number.
  static String _withoutCallingCode(
    String digits,
    String callingCode,
    List<int> lengths,
  ) {
    if (callingCode.isEmpty || !digits.startsWith(callingCode)) return digits;

    final rest = digits.substring(callingCode.length);
    if (!_isNational(rest, lengths) && !_isTrunked(rest, lengths)) {
      return digits;
    }

    return rest;
  }

  static String _withoutTrunkZero(String digits, List<int> lengths) {
    if (!_isTrunked(digits, lengths)) return digits;
    return digits.substring(1);
  }

  /// [digits] with [areaCode] in front when they were typed without it, so
  /// `555 1234` under `+1-876` becomes `876 555 1234`.
  static String _withAreaCode(
    String digits,
    String areaCode,
    List<int> lengths,
  ) {
    if (areaCode.isEmpty || _isNational(digits, lengths)) return digits;

    final withAreaCode = '$areaCode$digits';
    if (!_isNational(withAreaCode, lengths)) return digits;

    return withAreaCode;
  }

  /// The national digits of [tel] — the number with its calling code and any
  /// trunk `0` stripped — or `null` when [tel] is not a well-formed number,
  /// including one written with anything but [AppRegex.phoneCharacters].
  ///
  /// The same number reaches the app as `0803 123 4567`, `+234 803 123 4567`,
  /// `2348031234567` and `8031234567`, and every one of those must reduce to
  /// the same national digits before it is compared or sent.
  ///
  /// [dialCode] defaults to [AppConfig.countryCode] and may be written as a
  /// [Country.dial] or [Country.countryCode] is, including the North American
  /// `+1-876` form; digits typed without that area code get it back.
  ///
  /// The number must have [nationalLength] digits when given; otherwise one of
  /// the lengths [AppPhoneLengths] publishes for the calling code, falling
  /// back to ten for a calling code it does not know.
  ///
  /// The calling code is only stripped when what remains is itself a
  /// plausible national number, so a national number that happens to begin
  /// with the calling code's digits survives intact.
  static String? nationalPhoneDigits(
    String? tel, {
    String? dialCode,
    int? nationalLength,
  }) {
    if (tel == null || !AppRegex.phoneCharacters.hasMatch(tel.trim())) {
      return null;
    }

    final dial = dialCode ?? _dialCode;
    final callingCode = _callingCode(dial);
    final lengths = _nationalLengths(callingCode, nationalLength);

    var digits = tel.replaceAll(AppRegex.nonDigits, '');
    digits = _withoutCallingCode(digits, callingCode, lengths);
    digits = _withoutTrunkZero(digits, lengths);
    digits = _withAreaCode(digits, _areaCode(dial), lengths);

    if (!_isNational(digits, lengths) || digits.startsWith('0')) return null;

    return digits;
  }

  /// [tel] in the form a gateway expects: the calling code followed by the
  /// national digits, with no spaces or punctuation.
  ///
  /// Returns `null` when [tel] cannot be reduced to national digits, as
  /// [nationalPhoneDigits] describes, so a caller decides for itself whether
  /// to send the raw value or refuse it. Set [withPlus] for the `+234…` form
  /// some services require.
  static String? canonicalPhone(
    String? tel, {
    String? dialCode,
    int? nationalLength,
    bool withPlus = false,
  }) {
    final national = nationalPhoneDigits(
      tel,
      dialCode: dialCode,
      nationalLength: nationalLength,
    );
    if (national == null) return null;

    final callingCode = _callingCode(dialCode ?? _dialCode);
    return "${withPlus ? '+' : ''}$callingCode$national";
  }

  /// Whether [tel] reduces to a well-formed national number.
  static bool isCanonicalisablePhone(
    String? tel, {
    String? dialCode,
    int? nationalLength,
  }) {
    return nationalPhoneDigits(
          tel,
          dialCode: dialCode,
          nationalLength: nationalLength,
        ) !=
        null;
  }

  /// Returns a localized, human-readable age string representing the time elapsed since [datetime].
  static String age(DateTime? datetime) {
    if (datetime == null) {
      return strings.momentsAgo.tr();
    }

    final now = DateTime.now();
    final yearsSince = now.difference(datetime).inPreciseYears;
    final daysSince = now.difference(datetime).inDays;
    final weeksSince = now.difference(datetime).inWeeks;
    final monthsSince = now.difference(datetime).inMonths;

    if (daysSince <= 6) {
      return strings.daysOld.tr({"age": "$daysSince"});
    }

    if (weeksSince <= 4) {
      return strings.weeksOld.tr({"age": "$weeksSince"});
    }

    if (monthsSince <= 11) {
      return strings.monthsOld.tr({"age": "$monthsSince"});
    }

    return strings.yearsOld.tr({"age": "$yearsSince"});
  }

  /// Returns a localized string representing the time elapsed since [date] compared to [comparisonDate].
  static String timeSince(
    String? date, {
    DateTime? comparisonDate,
    bool useTime = false,
  }) {
    final datetime = DateTime.tryParse(date ?? "");

    if (datetime == null) {
      return strings.momentsAgo.tr();
    }

    final now = comparisonDate ?? DateTime.now();

    if (AppDateUtil.isSameDay(firstDate: now, secondDate: datetime)) {
      final minutesPast = now.difference(datetime).inMinutes;
      final hoursPast = minutesPast ~/ 60;
      if (minutesPast <= 1) {
        return strings.momentsAgo.tr();
      }
      if (useTime) {
        return formatDate(datetime.toIso8601String(), format: "HH:mm");
      }
      if (minutesPast > 1 && hoursPast < 1) {
        return strings.minutesAgo.tr({"minute": "$minutesPast"});
      }
      if (hoursPast == 1) {
        return strings.anHourAgo.tr();
      }
      return strings.hoursAgo.tr({"hour": "$hoursPast"});
    }
    final daysPast = now.difference(datetime).inDays;

    if (daysPast <= 1) {
      return strings.yesterday.tr();
    }

    if (daysPast <= 2) {
      return strings.daysAgo.tr({"day": "$daysPast"});
    }

    return formatDate(
      datetime.toIso8601String(),
      format: "MMM dd${useTime ? ' HH:mm' : ''}",
    );
  }

  /// Parses and formats the given [date] string using the specified [format] or [fallback].
  static String formatDate(String? date, {String? format, String? fallback}) {
    final formatter = DateFormat(format ?? "MM-dd-yyyy", _locale);
    final datetime = DateTime.tryParse(date ?? "");

    if (datetime == null) return fallback ?? "";

    return formatter.format(datetime);
  }

  /// Returns a masked string representation of a currency value (e.g., "$*****").
  static String maskedCurrency(num? value, {String symbol = AppStrings.naira}) {
    return "$symbol*****";
  }

  /// Returns a short, compact formatted currency string (e.g., "1.5K").
  static String formatCurrencyShort(
    num? value, {
    bool spaceIcon = false,
    bool ignoreSymbol = false,
    String symbol = AppStrings.naira,
    int decimals = 1,
  }) {
    if (value == null) return "";

    String amount = "$value";
    if (amount.isEmpty) return "";

    String currencySymbol = symbol;
    final formatter = NumberFormat.compactCurrency(
      locale: _locale,
      name: ignoreSymbol ? '' : currencySymbol,
      decimalDigits: decimals,
      symbol: ignoreSymbol ? "" : "$currencySymbol${spaceIcon ? " " : ""}",
    );

    amount = amount.replaceAll(AppRegex.nonAmount, "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null) return "";
    return formatter.format(amountDouble);
  }

  /// Returns a fully formatted currency string with comma separators.
  static String formatCurrency(
    num? value, {
    bool spaceIcon = false,
    bool ignoreSymbol = false,
    String symbol = AppStrings.naira,
    int decimals = 2,
  }) {
    if (value == null) return "";

    String amount = "$value";
    if (amount.isEmpty) return "";

    String currencySymbol = symbol;
    final formatter = NumberFormat.currency(
      locale: _locale,
      name: ignoreSymbol ? '' : currencySymbol,
      decimalDigits: decimals,
      symbol: ignoreSymbol ? "" : "$currencySymbol${spaceIcon ? " " : ""}",
    );

    amount = amount.replaceAll(AppRegex.nonAmount, "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null) return "";
    return formatter.format(amountDouble);
  }

  /// Formats the numeric [amount] using a custom formatting [pattern].
  static String formatNumberCutsom(
    String amount,
    String pattern, [
    bool ignoreLocale = false,
  ]) {
    if (!amount.hasValue) return "";

    final formatter = NumberFormat(pattern, ignoreLocale ? null : _locale);
    amount = amount.withoutWhiteSpaceAndSpecialChar.replaceAll(
      AppRegex.nonAmount,
      "",
    );
    return formatter.format(num.tryParse(amount));
  }

  /// Returns a short, compact formatted number string without currency symbol.
  static String formatNumber(String amount, [bool ignoreLocale = false]) {
    if (!amount.hasValue) return "";

    final formatter = NumberFormat.compact(
      locale: ignoreLocale ? null : _locale,
    );
    amount = amount.replaceAll(AppRegex.nonAmount, "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null || amountDouble == 0) return "0";
    return formatter.format(amountDouble);
  }

  /// Returns a fully formatted number string with comma separators.
  static String formatNumberLong(String amount) {
    if (!amount.hasValue) return "";

    final formatter = NumberFormat();
    amount = amount.replaceAll(AppRegex.nonAmount, "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null || amountDouble == 0) return "0";
    return formatter.format(amountDouble);
  }

  /// Returns a formatted string representing a salary range.
  static String formatSalaryRange({
    num? from,
    num? to,
    String currencySymbol = AppStrings.naira,
    required String fromText,
    required String toText,
  }) {
    final salaryFrom = AppTextFormatter.formatCurrency(
      from,
      symbol: currencySymbol,
    );
    final salaryTo = AppTextFormatter.formatCurrency(
      to,
      symbol: currencySymbol,
    );

    if (salaryFrom.isEmpty && salaryTo.isEmpty) return "";

    if (salaryFrom.isEmpty || salaryTo.isEmpty) {
      return salaryFrom.isEmpty ? salaryTo : salaryFrom;
    }
    return "$fromText $salaryFrom $toText $salaryTo";
  }

  /// Returns a compact formatted string representing a salary range.
  static String formatSalaryRangeShort({
    num? from,
    num? to,
    String currencySymbol = AppStrings.naira,
    String? prefix,
  }) {
    final salaryFrom = AppTextFormatter.formatCurrency(
      from,
      symbol: currencySymbol,
    );
    final salaryTo = AppTextFormatter.formatCurrency(
      to,
      symbol: currencySymbol,
    );

    if (salaryFrom.isEmpty && salaryTo.isEmpty) return "";

    if (salaryFrom.isEmpty || salaryTo.isEmpty) {
      return salaryFrom.isEmpty ? salaryTo : salaryFrom;
    }
    final prefixText = prefix != null ? "$prefix: " : "";
    return "$prefixText$salaryFrom - $salaryTo";
  }

  /// Formats the given [value] into a standard card expiry format (MM/YY).
  static String formatCardExpiry(String value) {
    String text = value.withoutWhiteSpaceAndSpecialChar;

    if (text.length > 2) text = "${text.substring(0, 2)}/${text.substring(2)}";

    return text;
  }

  /// Formats the given [value] into grouped blocks representing a credit card number.
  static String formatCardNumber(String value) {
    final text = value.withoutWhiteSpaceAndSpecialChar;
    if (text.length <= 4) return text;
    final groups = text.length / 4;
    final groupCeil = groups.ceil();

    final chunks = List.generate(groupCeil, (index) {
      final start = 4 * index;
      final endOffset = (start + 4);
      final end = endOffset >= text.length ? null : endOffset;

      return text.substring(start, end);
    });

    return chunks.join(" ");
  }
}

/// {@category Utilities}
/// A [TextInputFormatter] that automatically formats the input as a number with commas.
///
/// A keystroke that would take the amount past [decimalDigits] places, or its
/// whole part past [maxWholeDigits] digits, is refused. Deleting is always
/// allowed, so a longer value set in code can still be shortened.
///
/// A single `,` typed where there is no decimal point yet is read as the
/// decimal point, for keyboards in regions that use a comma. Commas already
/// in the text, or pasted with it, are read as grouping.
class AppAmountFormatter extends TextInputFormatter {
  /// The most digits allowed after the decimal point. Zero refuses a decimal
  /// point altogether.
  final int decimalDigits;

  /// The most digits allowed before the decimal point.
  ///
  /// With [decimalDigits] at 2, keep this at 13 or below so the amount stays
  /// within the 15 significant digits a double holds exactly.
  final int maxWholeDigits;

  const AppAmountFormatter({this.decimalDigits = 2, this.maxWholeDigits = 12})
    : assert(decimalDigits >= 0),
      assert(maxWholeDigits > 0);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    try {
      if (oldValue == newValue) {
        return TextEditingValue(
          text: newValue.text,
          selection: TextSelection.collapsed(offset: newValue.text.length),
          composing: TextRange.empty,
        );
      }

      final amount = _withDecimalComma(
        oldValue,
        newValue,
      ).replaceAll(AppRegex.nonAmount, "");

      if (amount.isEmpty) {
        return newValue.copyWith(text: "");
      }

      // Prevent multiple decimal points
      final parts = amount.split('.');
      if (parts.length > 2) return oldValue;

      final wholePart = _wholeDigits(parts[0]);
      final decimalPart = parts.length > 1 ? parts[1] : null;

      final isDeletion = newValue.text.length < oldValue.text.length;
      if (!isDeletion && _exceedsLimits(wholePart, decimalPart)) {
        return oldValue;
      }

      String formattedText = wholePart.replaceAll(
        AppRegex.thousandsBoundary,
        ",",
      );
      if (decimalPart != null) formattedText += ".$decimalPart";

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
        composing: TextRange.empty,
      );
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return oldValue;
    }
  }

  /// The text of [newValue], with a single `,` just typed read as the decimal
  /// point when the amount has none yet.
  String _withDecimalComma(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final typedAt = newValue.selection.baseOffset - 1;

    if (decimalDigits == 0) return text;
    if (text.length != oldValue.text.length + 1) return text;
    if (typedAt < 0 || typedAt >= text.length) return text;
    if (text[typedAt] != ",") return text;
    if (oldValue.text.contains(".")) return text;
    if (text.replaceRange(typedAt, typedAt + 1, "") != oldValue.text) {
      return text;
    }

    return text.replaceRange(typedAt, typedAt + 1, ".");
  }

  /// The whole part of the amount without leading zeros, or `0` when it is
  /// empty or all zeros.
  static String _wholeDigits(String digits) {
    final trimmed = digits.replaceFirst(AppRegex.leadingZeros, "");
    return trimmed.isEmpty ? "0" : trimmed;
  }

  bool _exceedsLimits(String wholePart, String? decimalPart) {
    if (wholePart.length > maxWholeDigits) return true;
    if (decimalPart == null) return false;
    return decimalDigits == 0 || decimalPart.length > decimalDigits;
  }
}

/// {@category Utilities}
/// A [TextInputFormatter] that automatically formats the input as a grouped credit card number.
class AppCardInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    try {
      final newText = newValue.text.withoutWhiteSpaceAndSpecialChar;
      final oldText = oldValue.text.withoutWhiteSpaceAndSpecialChar;

      if (newValue.text.length < oldText.length) {
        return newValue;
      }

      if (newText.length > 19) return oldValue;

      if (num.tryParse(newText) == null) return oldValue;

      final formattedText = AppTextFormatter.formatCardNumber(newText);

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
        composing: TextRange.empty,
      );
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return oldValue;
    }
  }
}

/// {@category Utilities}
/// A [TextInputFormatter] that automatically formats the input as a card expiry date (MM/YY).
class AppCardDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    try {
      final newText = newValue.text.withoutWhiteSpaceAndSpecialChar;
      final oldText = oldValue.text.withoutWhiteSpaceAndSpecialChar;

      if (newValue.text.length < oldText.length) return newValue;

      if (newText.length > 4) return oldValue;

      if (num.tryParse(newText) == null) return oldValue;

      if (newText.length <= 2) return newValue;

      String formattedText = AppTextFormatter.formatCardExpiry(newText);

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
        composing: TextRange.empty,
      );
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return oldValue;
    }
  }
}

/// {@category Utilities}
/// A [TextInputFormatter] that automatically formats the input as a phone number.
class AppPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    try {
      final newText = newValue.text.withoutWhiteSpaceAndSpecialChar;
      final oldText = oldValue.text.withoutWhiteSpaceAndSpecialChar;

      if (newText.length <= 4) return newValue;

      if (newValue.text.length < oldText.length) return newValue;

      if (newText.length > 15) return oldValue;

      if (num.tryParse(newText) == null) return oldValue;

      final formattedText = AppTextFormatter.formatPhone(newText);

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
        composing: TextRange.empty,
      );
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return oldValue;
    }
  }
}
