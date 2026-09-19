import 'dart:convert';

import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Utilities}
/// Tolerant readers for the loose value types a gateway sends.
///
/// The same field arrives as `1500`, `1500.0`, `'1,500'` and `'NGN 1,500'`
/// across one response family, and a flag arrives as a bool, a number or a
/// string. Every HTTP boundary that re-derives its own tolerance drifts from
/// its neighbours, so the tolerance is stated once here.
///
/// Nothing in this class throws: a value it cannot read becomes the caller's
/// fallback, or `null` where absence is itself an answer.
class AppJson {
  const AppJson._();

  /// The keys a gateway nests a record under.
  static const payloadKeys = ['data', 'responseData', 'result'];

  /// The keys a gateway spells its success flag with.
  static const successKeys = [
    'isSuccessful',
    'IsSuccessful',
    'isSuccess',
    'IsSuccess',
    'success',
  ];

  /// The keys a gateway spells its message with.
  static const messageKeys = [
    'responseMessage',
    'ResponseMessage',
    'message',
    'description',
  ];

  /// [value] as a string-keyed map, or [fallback] for anything that is not a
  /// map.
  ///
  /// A decoded envelope hands back `Map<Object?, Object?>` where `jsonDecode`
  /// hands back `Map<String, dynamic>`, and a reader that accepts only the
  /// latter silently drops the former. [fallback] is an argument because what
  /// a non-map payload means belongs to the call site.
  static Map<String, dynamic> asMap(
    Object? value, {
    Map<String, dynamic> fallback = const {},
  }) => switch (value) {
    Map<String, dynamic> map => map,
    Map<Object?, Object?> map => map.map(
      (key, value) => MapEntry('$key', value),
    ),
    _ => fallback,
  };

  /// [value] as a number, tolerating grouped and prefixed string amounts.
  ///
  /// Unlike [AppHelpers.extractAmount] this keeps a minus sign and takes the
  /// caller's [fallback] rather than always answering null.
  static num asNum(Object? value, {num fallback = 0}) => switch (value) {
    num number => number,
    String raw =>
      num.tryParse(raw.replaceAll(',', '')) ??
          num.tryParse(raw.replaceAll(RegExp(r'[^0-9.\-]'), '')) ??
          fallback,
    _ => fallback,
  };

  /// [value] as an `int`, tolerating numeric strings.
  static int asInt(Object? value, {int fallback = 0}) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String raw => raw.value.asInt ?? fallback,
    _ => fallback,
  };

  /// [value] as a flag, or `null` when it carried no answer.
  ///
  /// Absence and rejection are different answers: an account the gateway said
  /// nothing about must not be silently opted out of the feature the flag
  /// gates.
  static bool? asFlag(Object? value) => switch (value) {
    bool flag => flag,
    num number => number != 0,
    String raw => switch (raw.value.lower) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    },
    _ => null,
  };

  /// The value among [values] whose name the gateway sent as [wire], ignoring
  /// case and surrounding space, or `null` for one this app does not know.
  static T? asEnum<T extends Enum>(List<T> values, Object? wire) {
    final name = wire?.toString() ?? '';
    return values.tryFirstWhere((value) => value.name.equals(name));
  }

  /// The map entries of a JSON array, decoded, ignoring malformed entries.
  ///
  /// Matching and binding happen together so callers do not repeat unchecked
  /// `as List` and `as Map<String, dynamic>` casts at every boundary.
  static List<T> decodeList<T>(
    Object? value,
    MapCallback<T, Map<String, dynamic>> decode,
  ) => switch (value) {
    Iterable<Object?> values => [
      for (final value in values)
        if (value case Map<Object?, Object?> json) decode(asMap(json)),
    ],
    _ => const [],
  };

  /// One typed JSON object, decoded, without an unchecked map cast.
  static T? decodeObject<T>(
    Object? value,
    MapCallback<T, Map<String, dynamic>> decode,
  ) => switch (value) {
    Map<Object?, Object?> json => decode(asMap(json)),
    _ => null,
  };

  /// The map [raw] spells as JSON, or `null` when it spells anything else.
  ///
  /// A body read as plain text, or a record a gateway stringified, is still a
  /// map to whoever reads it; text that merely opens with a brace is not.
  static Map<String, dynamic>? decodedMap(String raw) {
    if (!raw.value.startsWith('{')) return null;
    if (_decodeOrNull(raw) case Map<Object?, Object?> map) return asMap(map);
    return null;
  }

  /// The record [json] nests under one of [payloadKeys], or [json] itself when
  /// it nests none.
  ///
  /// A record sent as a JSON string is decoded; a string that is not valid
  /// JSON counts as absent.
  static Map<String, dynamic> payload(Map<String, dynamic> json) {
    for (final key in payloadKeys) {
      final value = switch (json[key]) {
        String raw => decodedMap(raw),
        final other => other,
      };
      if (value case Map<Object?, Object?> map) return asMap(map);
    }
    return json;
  }

  /// The raw value of the first of [keys] present in [json], even when null.
  static Object? valueAt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return json[key];
    }
    return null;
  }

  /// The first non-empty value among [keys], trimmed, or empty when none has
  /// one.
  ///
  /// The gateway spells one field several ways across endpoints, so readers
  /// list every spelling they accept.
  static String stringAt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json[key] case final value? when '$value'.hasValue) {
        return '$value'.value;
      }
    }
    return '';
  }

  /// The first of [keys] carrying a number [asNum] can read, or 0.
  static num numAt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final number = asNum(json[key], fallback: double.nan);
      if (!number.isNaN) return number;
    }
    return 0;
  }

  /// The first of [keys] carrying a flag [asFlag] recognises, or `null`.
  static bool? flagAt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (asFlag(json[key]) case final flag?) return flag;
    }
    return null;
  }

  /// The gateway's business-success flag, or `null` when [json] carries none.
  ///
  /// A gateway that answers `200` while reporting a business failure is the
  /// most common way a broken call renders as an empty catalogue or a zero
  /// fee, so the flag has to be read rather than assumed from the status code.
  ///
  /// Every value is read by [asFlag], so a flag spelled `'1'` means here what
  /// it means everywhere else. Reading strings twice, once here and once
  /// there, is what made `'1'` a success to one reader and a refusal to the
  /// one that decides whether the request succeeded.
  ///
  /// Only a string [asFlag] cannot read falls to [strict]: left off it is a
  /// refusal, because a gateway that spelled the flag reached for it and said
  /// something; set, it is no answer at all.
  static bool? successFlag(Map<String, dynamic> json, {bool strict = false}) {
    final flag = valueAt(json, successKeys);
    if (asFlag(flag) case final value?) return value;
    if (flag is String && !strict) return false;
    return null;
  }

  /// The message the gateway attached to [json], empty when it attached none.
  static String message(Map<String, dynamic> json) =>
      stringAt(json, messageKeys);

  static Object? _decodeOrNull(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
