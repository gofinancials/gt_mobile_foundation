import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:easy_localization/easy_localization.dart' as l10n;

/// {@category Extensions}
/// Extension on [String] providing localization, parsing, and formatting utilities.
extension StringExtension on String {
  /// Encodes this string into a UTF-8 [Uint8List].
  Uint8List get encoded => utf8.encode(this);

  /// Returns this string formatted as a standard phone number.
  String get asFormattedPhone {
    return AppTextFormatter.formatPhone(this);
  }

  /// Strips all whitespace and non-alphanumeric special characters from the string.
  String get withoutWhiteSpaceAndSpecialChar {
    String str = trim();
    str = str.replaceAll(" ", "");
    str = str.replaceAll(AppRegex.specialCharRegEx, "");
    return str.trim();
  }

  /// Formats this string (assumed to be a duration) into a human-readable duration string.
  String get asDuration {
    return AppTextFormatter.timeSince(this);
  }

  /// Formats this string (assumed to be a number) into a comma-separated number string.
  String asFormattedNumber() {
    return AppTextFormatter.formatNumber(this);
  }

  /// Translates this string using `easy_localization`. Accepts optional named arguments.
  String tr([Map<String, String>? namedArgs]) {
    return l10n.tr(this, namedArgs: namedArgs);
  }

  /// Translates this string and converts it entirely to uppercase.
  String utr([Map<String, String>? namedArgs]) {
    return tr(namedArgs).upper;
  }

  /// Translates this string and capitalizes the first letter of each word.
  String ctr([Map<String, String>? namedArgs]) {
    return tr(namedArgs).capitalise();
  }

  /// Translates this string and converts it entirely to lowercase.
  String ltr([Map<String, String>? namedArgs]) {
    return tr(namedArgs).lower;
  }

  /// Formats this string into a masked or spaced credit card number layout.
  String get asCardNumber => AppTextFormatter.formatCardNumber(this);

  /// Attempts to parse this string into a [DateTime] object.
  DateTime? get asDate => DateTime.tryParse(this);

  /// Attempts to parse this string into an integer.
  int? get asInt => int.tryParse(this);

  /// Attempts to extract a numeric currency/amount value from this string.
  num? get asAmount => AppHelpers.extractAmount(this);

  /// Parses and formats this string as a date using the provided format and fallback.
  String? asFormattedDate([String? format, String? fallback]) {
    return AppTextFormatter.formatDate(
      this,
      format: format,
      fallback: fallback,
    );
  }

  /// Returns only the date portion (YYYY-MM-DD) assuming an ISO 8601 formatted string.
  String get isoDateOnly => split("T").first;

  /// Returns only the time portion assuming an ISO 8601 formatted string.
  String get isoTimeOnly => split("T").last;

  /// Shorthand for [toLowerCase].
  String get lower => toLowerCase();

  /// Shorthand for [toUpperCase].
  String get upper => toUpperCase();

  /// Case-insensitive inclusion check. Returns `true` if this string contains [other].
  bool includes(String other) {
    return lower.contains(other.lower);
  }

  /// Case-insensitive equality check. Returns `true` if this string equals [other].
  bool equals(String other) {
    return lower.trim() == other.lower.trim();
  }

  /// Appends [other] to this string, optionally separated by a [concatenant].
  String concatenate(String other, {String concatenant = ""}) {
    return "$this$concatenant$other";
  }

  /// Attempts to parse this string into an integer ID, returning the string itself if it fails.
  dynamic toId() {
    return int.tryParse(this) ?? this;
  }

  /// Returns the last 4 characters of the string (or the entire string if shorter than 4).
  String get lastChars {
    if (isEmpty) return "";
    if (length <= 4) return this[length - 1];
    return substring(length - 4);
  }

  /// Partially obscures an email address (e.g., test@example.com -> te**@example.com).
  String get obscuredEmail {
    if (!AppRegex.mailRegEx.hasMatch(this)) return this;
    final parts = split("@");
    final mail = parts.first;
    final host = parts.last;

    if (mail.length <= 1) return "***@$host";

    final mailMidIndex = mail.length ~/ 2;
    final obscureChar = "*" * (mail.length - mailMidIndex);
    final presentedChar = mail.substring(0, mailMidIndex);

    return "$presentedChar$obscureChar@$host";
  }

  /// Capitalizes the first letter of the string (or each word if [onlyFirst] is false).
  String capitalise([bool onlyFirst = false]) {
    final text = this;
    try {
      if (text.isEmpty) {
        return text;
      } else if (text.length == 1) {
        return text.toUpperCase();
      } else if (text.length > 1 && onlyFirst) {
        final firstChar = text[0];
        return "${firstChar.toUpperCase()}${text.substring(1).toLowerCase()}";
      } else {
        final textSpan = text.split(" ").map((it) {
          if (it.isEmpty) {
            return it;
          }
          if (it.length == 1) {
            return it.toUpperCase();
          }
          final firstChar = it[0];
          return "${firstChar.toUpperCase()}${it.substring(1).toLowerCase()}";
        });
        return textSpan.join(" ");
      }
    } catch (_) {
      return this;
    }
  }

  /// Exact case-insensitive match check. Alias for [equals] but without trimming.
  bool matches(String other) {
    return lower == other.lower;
  }

  /// Splits the string by a [Pattern] and attempts to transform each item into type [T].
  List<T> toList<T>({TransformCall<T>? transformer, Pattern splitBy = ","}) {
    try {
      final value = this;

      final values = value.split(splitBy).mapList((it) => it.trim());

      if (transformer == null) {
        final transormValues = switch (T) {
          const (int) => values.map((it) => (int.tryParse(it) ?? 0)),
          const (double) => values.map((it) => double.tryParse(it) ?? 0),
          const (bool) => values.map((it) => it == "true"),
          _ => values,
        };
        return [...transormValues].cast();
      }
      return values.mapList((it) => transformer(it));
    } catch (_) {
      return [].cast();
    }
  }

  /// Parses a card expiry string like "12/25" into a [DateTime] object.
  DateTime? get fromCardExpiryTextToDate {
    if (!hasValue) return null;

    final parts = split("/");

    final isPair = parts.length == 2;
    final containsPairParts = parts.every((it) => it.length == 2);
    final containsDigits = parts.every((it) => it.asInt != null);

    if (!(isPair && containsDigits && containsPairParts)) return null;

    final month = parts.first.asInt ?? 0;
    final year = 2000 + (parts.last.asInt ?? 0);

    if (month > 12 || month < 1) return null;

    return DateTime(year, month);
  }
}

/// {@category Extensions}
/// Extension on nullable [String] for safer validation and manipulation.
extension NullableStringExtension on String? {
  /// Returns `true` if the string is non-null and not purely whitespace.
  bool get hasValue {
    return this != null && (this ?? "").trim().isNotEmpty;
  }

  /// Returns the trimmed string, or an empty string if null.
  String get value => (this ?? "").trim();

  /// Case-insensitive equality check handling nullability gracefully.
  bool equals(String other) {
    if (!hasValue) return false;
    return value.lower.trim() == other.lower.trim();
  }

  /// Checks if the text matches a Right-to-Left (RTL) script format.
  bool get isRTL {
    if (!hasValue) return false;
    final matchesRtl = AppRegex.rtlScriptRegex.hasMatch(value);

    return matchesRtl;
  }

  /// Returns the appropriate [TextDirection] based on the string content.
  TextDirection get directionality {
    if (!isRTL) return TextDirection.ltr;
    return TextDirection.rtl;
  }

  /// Returns the initials parsed from the string (e.g., "John Doe" -> "JD").
  String? get initials => AppHelpers.getInitials(this);

  /// Returns the acronym parsed from the string.
  String? get accronym => AppHelpers.getAccronym(this);

  /// Attempts to extract a numeric currency/amount value from this string.
  num? get asAmount => AppHelpers.extractAmount(this);
}

/// Generates a random numeric string.
String randomNumString() {
  return "${Random().nextInt(100000000)}";
}

/// {@category Extensions}
/// Comprehensive masking and secret codec extension methods on nullable [String?].
extension NullableStringMaskExtension on String? {
  /// Masks this nullable string as a phone number for OTP verification screens (e.g. `0810*****14`).
  String get asMaskedOtpPhone => AppStringMaskUtils.maskOtpPhone(this);

  /// Masks this nullable string as a phone number with default visible lengths (`0810*****14`).
  String get asMaskedPhone => AppStringMaskUtils.maskPhoneNumber(this);

  /// Masks this nullable string as an email address (e.g. `u***r@example.com`).
  String get asMaskedEmail => AppStringMaskUtils.maskEmail(this);

  /// Masks this nullable string as a bank account number (e.g. `012****789`).
  String get asMaskedAccountNumber =>
      AppStringMaskUtils.maskAccountNumber(this);

  /// Masks this nullable string as an 11-digit BVN (e.g. `222******55`).
  String get asMaskedBvn => AppStringMaskUtils.maskBvn(this);

  /// Masks this nullable string as a National Identification Number (NIN).
  String get asMaskedNin => AppStringMaskUtils.maskBvn(this);

  /// Masks this nullable string as a Card PAN, keeping first 6 and last 4 digits (e.g. `123456******5678`).
  String get asMaskedCard => AppStringMaskUtils.maskCardPan(this);

  /// Returns a log-safe redacted rendering of this secret string, preserving the last 4 characters.
  String get asRedactedSecret => !hasValue ? '' : AppSecretCodec.redact(value);

  /// Encodes this string using [AppSecretCodec.encode].
  String get asSecretEncoded => !hasValue ? '' : AppSecretCodec.encode(value);

  /// Decodes this masked secret string using [AppSecretCodec.decode].
  String get asSecretDecoded => !hasValue ? '' : AppSecretCodec.decode(value);

  /// Generic customizable masking on this nullable string.
  String mask({
    int startVisible = 4,
    int endVisible = 2,
    String maskChar = '*',
    int? fixedMaskLength,
  }) => AppStringMaskUtils.mask(
    this,
    startVisible: startVisible,
    endVisible: endVisible,
    maskChar: maskChar,
    fixedMaskLength: fixedMaskLength,
  );

  /// Shorthand masking method with tighter visible boundaries (2 leading, 2 trailing).
  String maskWith({
    int startVisible = 2,
    int endVisible = 2,
    String maskChar = '*',
    int? fixedMaskLength,
  }) => AppStringMaskUtils.mask(
    this,
    startVisible: startVisible,
    endVisible: endVisible,
    maskChar: maskChar,
    fixedMaskLength: fixedMaskLength,
  );

  /// Alias for [mask].
  String maskCustom({
    int startVisible = 4,
    int endVisible = 2,
    String maskChar = '*',
    int? fixedMaskLength,
  }) => AppStringMaskUtils.mask(
    this,
    startVisible: startVisible,
    endVisible: endVisible,
    maskChar: maskChar,
    fixedMaskLength: fixedMaskLength,
  );

  /// Masks this nullable string as a phone number with configurable options.
  String maskPhoneNumber({
    int prefixLength = 4,
    int suffixLength = 2,
    String maskChar = '*',
    bool normalizeNigerian = true,
  }) => AppStringMaskUtils.maskPhoneNumber(
    this,
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
    normalizeNigerian: normalizeNigerian,
  );

  /// Masks this nullable string specifically for OTP verification screens.
  String maskOtpPhone() => AppStringMaskUtils.maskOtpPhone(this);

  /// Masks this nullable string as an email address with configurable visible character counts.
  String maskEmail({
    int visiblePrefix = 1,
    int visibleSuffix = 1,
    String maskChar = '*',
  }) => AppStringMaskUtils.maskEmail(
    this,
    visiblePrefix: visiblePrefix,
    visibleSuffix: visibleSuffix,
    maskChar: maskChar,
  );

  /// Masks this nullable string as an account number with configurable visible lengths.
  String maskAccountNumber({
    int prefixLength = 3,
    int suffixLength = 3,
    String maskChar = '*',
  }) => AppStringMaskUtils.maskAccountNumber(
    this,
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
  );

  /// Masks this nullable string as a BVN with configurable visible lengths.
  String maskBvn({
    int prefixLength = 3,
    int suffixLength = 2,
    String maskChar = '*',
  }) => AppStringMaskUtils.maskBvn(
    this,
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
  );

  /// Masks this nullable string as a NIN with configurable visible lengths.
  String maskNin({
    int prefixLength = 3,
    int suffixLength = 2,
    String maskChar = '*',
  }) => AppStringMaskUtils.maskBvn(
    this,
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
  );

  /// Masks this nullable string as a Card PAN with configurable visible lengths.
  String maskCardPan({
    int prefixLength = 6,
    int suffixLength = 4,
    String maskChar = '*',
  }) => AppStringMaskUtils.maskCardPan(
    this,
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
  );

  /// Alias for [maskCardPan].
  String maskCard({
    int prefixLength = 6,
    int suffixLength = 4,
    String maskChar = '*',
  }) => AppStringMaskUtils.maskCardPan(
    this,
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    maskChar: maskChar,
  );

  /// Redacts this nullable secret string exposing only the last [visible] characters.
  String redactSecret({int visible = 4}) {
    if (!hasValue) return '';
    return AppSecretCodec.redact(value, visible: visible);
  }
}
