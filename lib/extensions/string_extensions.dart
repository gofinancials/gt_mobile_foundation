import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:easy_localization/easy_localization.dart' as l10n;

extension StringExtension on String {
  Uint8List get encoded => utf8.encode(this);

  String get asFormattedPhone {
    return AppTextFormatter.formatPhone(this);
  }

  String get withoutWhiteSpaceAndSpecialChar {
    String str = trim();
    str = str.replaceAll(" ", "");
    str = str.replaceAll(AppRegex.specialCharRegEx, "");
    return str.trim();
  }

  String get asDuration {
    return AppTextFormatter.timeSince(this);
  }

  String asFormattedNumber() {
    return AppTextFormatter.formatNumber(this);
  }

  String tr([Map<String, String>? namedArgs]) {
    return l10n.tr(this, namedArgs: namedArgs);
  }

  String utr([Map<String, String>? namedArgs]) {
    return tr(namedArgs).upper;
  }

  String ctr([Map<String, String>? namedArgs]) {
    return tr(namedArgs).capitalise();
  }

  String ltr([Map<String, String>? namedArgs]) {
    return tr(namedArgs).lower;
  }

  String get asCardNumber => AppTextFormatter.formatCardNumber(this);

  DateTime? get asDate => DateTime.tryParse(this);

  int? get asInt => int.tryParse(this);

  num? get asAmount => AppHelpers.extractAmount(this);

  String? asFormattedDate([String? format, String? fallback]) {
    return AppTextFormatter.formatDate(
      this,
      format: format,
      fallback: fallback,
    );
  }

  String get isoDateOnly => split("T").first;
  String get isoTimeOnly => split("T").last;

  String get lower => toLowerCase();
  String get upper => toUpperCase();

  bool includes(String other) {
    return lower.contains(other.lower);
  }

  bool equals(String other) {
    return lower.trim() == other.lower.trim();
  }

  String concatenate(String other, {String concatenant = ""}) {
    return "$this$concatenant$other";
  }

  dynamic toId() {
    return int.tryParse(this) ?? this;
  }

  String get lastChars {
    if (isEmpty) return "";
    if (length <= 4) return this[length - 1];
    return substring(length - 4);
  }

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

  bool matches(String other) {
    return lower == other.lower;
  }

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
}

extension NullableStringExtension on String? {
  bool get hasValue {
    return this != null && (this ?? "").trim().isNotEmpty;
  }

  String get value => (this ?? "").trim();

  bool equals(String other) {
    if (this == null) return false;
    return this!.lower.trim() == other.lower.trim();
  }

  bool get isRTL {
    if (!hasValue) return false;
    final matchesRtl = AppRegex.rtlScriptRegex.hasMatch(this!);

    return matchesRtl;
  }

  TextDirection get directionality {
    if (!isRTL) return TextDirection.ltr;
    return TextDirection.rtl;
  }

  String? get initials => AppHelpers.getInitials(this);
  String? get accronym => AppHelpers.getAccronym(this);
}

String randomNumString() {
  return "${Random().nextInt(100000000)}";
}
