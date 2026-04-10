import 'dart:math';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

extension NumExtension on num {
  String get formattedCurrency {
    return AppTextFormatter.formatCurrency(this);
  }

  String asCurrency([String symbol = "\$"]) {
    return AppTextFormatter.formatCurrency(this, symbol: symbol);
  }

  String asCurrencyShort([String symbol = "\$"]) {
    return AppTextFormatter.formatCurrencyShort(this, symbol: symbol);
  }

  String get maskedCurrency {
    return AppTextFormatter.maskedCurrency(this);
  }

  String get formattedNumber {
    return AppTextFormatter.formatNumber(toString());
  }

  String get formattedNumberLong {
    return AppTextFormatter.formatNumberLong(toString());
  }

  double get asDeg {
    return this * (180 / pi);
  }

  Duration get microseconds {
    return Duration(microseconds: toInt());
  }

  Duration get milliseconds {
    return Duration(milliseconds: toInt());
  }

  Duration get seconds {
    return Duration(seconds: toInt());
  }

  Duration get minutes {
    return Duration(minutes: toInt());
  }

  Duration get hours {
    return Duration(hours: toInt());
  }

  Duration get days {
    return Duration(days: toInt());
  }

  double get asCents => this * 100;
  double get asDollars => this / 100;
  String get asPercentage => (asCents).toStringAsFixed(0);

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

extension IntExtension on int {
  String get asHourName {
    final date = TimeOfDay(hour: this, minute: 0).asDate;
    return date.format("hh");
  }

  String get asMinuteName {
    final date = TimeOfDay(hour: 0, minute: this).asDate;
    return date.format("mm");
  }

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

int randomInt() {
  return Random().nextInt(10000);
}
