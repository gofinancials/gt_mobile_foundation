import 'package:flutter/widgets.dart';

import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:intl/intl.dart';

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

  static String formatPhone(String tel) {
    if (tel.length < 10) return tel.trim();

    if (tel.length == 10) {
      return "${tel.substring(0, 3)} ${tel.substring(3, 6)} ${tel.substring(6)}";
    }
    if (tel.length == 11) {
      return "${tel.substring(0, 4)} ${tel.substring(4, 7)} ${tel.substring(7)}";
    }
    return "+${tel.substring(0, 3)} ${tel.substring(3, 6)} ${tel.substring(6, 9)} ${tel.substring(9)}";
  }

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

  static String formatDate(String? date, {String? format, String? fallback}) {
    final formatter = DateFormat(format ?? "MM-dd-yyyy", _locale);
    final datetime = DateTime.tryParse(date ?? "");

    if (datetime == null) return fallback ?? "";

    return formatter.format(datetime);
  }

  static String maskedCurrency(num? value, {String symbol = "\$"}) {
    return "$symbol*****";
  }

  static String formatCurrencyShort(
    num? value, {
    bool spaceIcon = false,
    bool ignoreSymbol = false,
    String symbol = "\$",
  }) {
    if (value == null) return "";

    String amount = "$value";
    if (amount.isEmpty) return "";

    String currencySymbol = symbol;
    final formatter = NumberFormat.compactCurrency(
      locale: _locale,
      name: ignoreSymbol ? '' : currencySymbol,
      decimalDigits: 1,
      symbol: ignoreSymbol ? "" : "$currencySymbol${spaceIcon ? " " : ""}",
    );

    amount = amount.replaceAll(RegExp(r'[^0-9\.]'), "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null) return "";
    return formatter.format(amountDouble);
  }

  static String formatCurrency(
    num? value, {
    bool spaceIcon = false,
    bool ignoreSymbol = false,
    String symbol = "\$",
  }) {
    if (value == null) return "";

    String amount = "$value";
    if (amount.isEmpty) return "";

    String currencySymbol = symbol;
    final formatter = NumberFormat.currency(
      locale: _locale,
      name: ignoreSymbol ? '' : currencySymbol,
      symbol: ignoreSymbol ? "" : "$currencySymbol${spaceIcon ? " " : ""}",
    );

    amount = amount.replaceAll(RegExp(r'[^0-9\.]'), "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null) return "";
    return formatter.format(amountDouble);
  }

  static String formatNumberCutsom(
    String amount,
    String pattern, [
    bool ignoreLocale = false,
  ]) {
    if (!amount.hasValue) return "";

    final formatter = NumberFormat(pattern, ignoreLocale ? null : _locale);
    amount = amount.withoutWhiteSpaceAndSpecialChar.replaceAll(
      RegExp(r'[^0-9\.]'),
      "",
    );
    return formatter.format(num.tryParse(amount));
  }

  static String formatNumber(String amount, [bool ignoreLocale = false]) {
    if (!amount.hasValue) return "";

    final formatter = NumberFormat.compact(
      locale: ignoreLocale ? null : _locale,
    );
    amount = amount.replaceAll(RegExp(r'[^0-9\.]'), "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null || amountDouble == 0) return "0";
    return formatter.format(amountDouble);
  }

  static String formatNumberLong(String amount) {
    if (!amount.hasValue) return "";

    final formatter = NumberFormat();
    amount = amount.replaceAll(RegExp(r'[^0-9\.]'), "");
    final amountDouble = double.tryParse(amount);
    if (amountDouble == null || amountDouble == 0) return "0";
    return formatter.format(amountDouble);
  }

  static String formatSalaryRange({
    num? from,
    num? to,
    String currencySymbol = "\$",
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

  static String formatSalaryRangeShort({
    num? from,
    num? to,
    String currencySymbol = "\$",
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

  static String formatCardExpiry(String value) {
    String text = value.withoutWhiteSpaceAndSpecialChar;

    if (text.length > 2) text = "${text.substring(0, 2)}/${text.substring(2)}";

    return text;
  }

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

class AppAmountFormatter extends TextInputFormatter {
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
      final amount = newValue.text.isNotEmpty
          ? newValue.text.replaceAll(RegExp(r'[^0-9\.]'), "")
          : "";
      final isValidNum = amount.isNotEmpty && int.tryParse(amount) != null;
      if (isValidNum) {
        final formattedText = AppTextFormatter.formatNumberLong(amount);
        return TextEditingValue(
          text: formattedText,
          selection: TextSelection.collapsed(offset: formattedText.length),
          composing: TextRange.empty,
        );
      } else {
        return newValue;
      }
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return oldValue;
    }
  }
}
