import 'dart:math';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Extensions}
/// Extension on [num] providing utilities for currency, formatting, and duration conversions.
extension NumExtension on num {
  /// Formats this number as a standard currency string (e.g., "$1,000.00").
  String get formattedCurrency {
    return AppTextFormatter.formatCurrency(this);
  }

  /// Formats this number as a currency string with a custom [symbol].
  String asCurrency([String symbol = "\$"]) {
    return AppTextFormatter.formatCurrency(this, symbol: symbol);
  }

  /// Formats this number as a short currency string, abbreviating large values (e.g., "$1k").
  String asCurrencyShort([String symbol = "\$"]) {
    return AppTextFormatter.formatCurrencyShort(this, symbol: symbol);
  }

  /// Formats this number as a masked currency string (e.g., "****").
  String get maskedCurrency {
    return AppTextFormatter.maskedCurrency(this);
  }

  /// Formats this number with comma separators (e.g., "1,000").
  String get formattedNumber {
    return AppTextFormatter.formatNumber(toString());
  }

  /// Formats this number into a long number string without abbreviation.
  String get formattedNumberLong {
    return AppTextFormatter.formatNumberLong(toString());
  }

  /// Converts this number from radians to degrees.
  double get asDeg {
    return this * (180 / pi);
  }

  /// Returns a [Duration] treating this number as microseconds.
  Duration get microseconds {
    return Duration(microseconds: toInt());
  }

  /// Returns a [Duration] treating this number as milliseconds.
  Duration get milliseconds {
    return Duration(milliseconds: toInt());
  }

  /// Returns a [Duration] treating this number as seconds.
  Duration get seconds {
    return Duration(seconds: toInt());
  }

  /// Returns a [Duration] treating this number as minutes.
  Duration get minutes {
    return Duration(minutes: toInt());
  }

  /// Returns a [Duration] treating this number as hours.
  Duration get hours {
    return Duration(hours: toInt());
  }

  /// Returns a [Duration] treating this number as days.
  Duration get days {
    return Duration(days: toInt());
  }

  /// Converts a dollar value to cents (multiplies by 100).
  double get asCents => this * 100;

  /// Converts a cent value to dollars (divides by 100).
  double get asDollars => this / 100;

  /// Returns a string representation of this number as a percentage (treats number as decimal).
  String get asPercentage => (asCents).toStringAsFixed(0);

  /// Returns a localized, human-readable duration string for this number (treated as seconds).
  String get formattedDuration {
    final duration = "$seconds".split(".").tryFirst;
    final sections = duration?.split(":") ?? List.generate(3, (_) => "0");
    final [hour, min, sec] = [
      num.tryParse(sections[0]) ?? 0,
      num.tryParse(sections[1]) ?? 0,
      num.tryParse(sections[2]) ?? 0,
    ];
    final fomattedMin = min < 10 ? "0$min" : "$min";
    final fomattedHour = hour < 10 ? "0$hour" : "$hour";
    final fomattedSec = sec < 10 ? "0$sec" : "$sec";

    if (hour < 1 && min < 1) {
      final sec = seconds.inSeconds;
      return stringKeys.seconds.tr({"time": "$sec"});
    }

    if (hour < 1 && min >= 1) {
      return stringKeys.minutes.tr({"time": "$fomattedMin:$fomattedSec"});
    }

    return "$fomattedHour:$fomattedMin:$fomattedSec";
  }

  /// Returns a raw duration string in "HH:MM:SS" or "MM:SS" format (treated as seconds).
  String get asDurationString {
    final duration = "$seconds".split(".").first;

    final [hours, minutes, seconds_] = duration
        .split(":")
        .mapList((it) => int.tryParse(it) ?? 0);

    final hoursText = hours < 1 ? "" : "${hours < 10 ? '0' : ''}$hours:";
    final minutesText = "${minutes < 10 ? '0' : ''}$minutes:";
    final secondsText = "${seconds_ < 10 ? '0' : ''}$seconds_";

    return "$hoursText$minutesText$secondsText";
  }

  /// Returns a time code string "HH:MM:SS" or "MM:SS" based on this number (treated as seconds).
  String get timeCode {
    final duration = "$seconds".split(".").tryFirst;
    final sections = duration?.split(":") ?? List.generate(3, (_) => "0");
    final [hour, min, sec] = [
      num.tryParse(sections[0]) ?? 0,
      num.tryParse(sections[1]) ?? 0,
      num.tryParse(sections[2]) ?? 0,
    ];
    final fomattedMin = min < 10 ? "0$min" : "$min";
    final fomattedHour = hour < 10 ? "0$hour" : "$hour";
    final fomattedSec = sec < 10 ? "0$sec" : "$sec";

    String timeCode = "$fomattedMin:$fomattedSec";

    if (hour > 0) timeCode = "$fomattedHour:$timeCode";

    return timeCode;
  }
}

/// {@category Extensions}
/// Extension on [int] providing specific time and date helpers.
extension IntExtension on int {
  /// Returns the formatted hour name treating this int as an hour (0-23).
  String get asHourName {
    final date = TimeOfDay(hour: this, minute: 0).asDate;
    return date.format("hh");
  }

  /// Returns the formatted minute name treating this int as a minute (0-59).
  String get asMinuteName {
    final date = TimeOfDay(hour: 0, minute: this).asDate;
    return date.format("mm");
  }

  /// Returns a list of day numbers (1 to N) based on this int representing a month index (1-12).
  List<int> get monthDays {
    int daysInMonth = switch (this) {
      DateTime.february => 29,
      DateTime.september | DateTime.april | DateTime.june | DateTime.november =>
        30,
      _ => 31,
    };
    return List.generate(daysInMonth, (index) => index + 1, growable: false);
  }
}

/// Generates a random integer between 0 and 9999.
int randomInt() {
  return Random().nextInt(10000);
}
