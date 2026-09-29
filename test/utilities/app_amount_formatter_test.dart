import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// Runs [formatter] over an edit from [before] to [after], with the cursor
/// left at [cursor] or the end of [after].
String edit(
  String before,
  String after, {
  int? cursor,
  AppAmountFormatter formatter = const AppAmountFormatter(),
}) {
  return formatter
      .formatEditUpdate(
        TextEditingValue(
          text: before,
          selection: TextSelection.collapsed(offset: before.length),
        ),
        TextEditingValue(
          text: after,
          selection: TextSelection.collapsed(offset: cursor ?? after.length),
        ),
      )
      .text;
}

/// Types [keys] into an empty field one character at a time.
String type(
  String keys, {
  AppAmountFormatter formatter = const AppAmountFormatter(),
}) {
  var text = "";
  for (final key in keys.split("")) {
    text = edit(text, "$text$key", formatter: formatter);
  }
  return text;
}

void main() {
  group('AppAmountFormatter grouping', () {
    test('groups the whole part with commas', () {
      expect(type("1234567"), "1,234,567");
    });

    test('keeps every typed digit of a long whole part', () {
      expect(type("123456789012"), "123,456,789,012");
    });

    test('drops leading zeros but keeps a lone zero', () {
      expect(type("0"), "0");
      expect(type("005"), "5");
    });

    test('starts a leading decimal point with a zero', () {
      expect(type("."), "0.");
      expect(type(".5"), "0.5");
    });

    test('clears the field when every digit is deleted', () {
      expect(edit("5", ""), "");
    });
  });

  group('AppAmountFormatter limits', () {
    test('refuses a third decimal digit', () {
      expect(type("1000.555"), "1,000.55");
    });

    test('refuses a second decimal point', () {
      expect(type("1.2.3"), "1.23");
    });

    test('refuses a whole digit past the limit', () {
      expect(type("1234567890123"), "123,456,789,012");
    });

    test('honours custom limits', () {
      const formatter = AppAmountFormatter(decimalDigits: 0, maxWholeDigits: 4);

      expect(type("12345", formatter: formatter), "1,234");
      expect(type("12.", formatter: formatter), "12");
    });

    test('refuses a paste past the limits', () {
      expect(edit("", "1000.555"), "");
      expect(edit("", "12345678901234567"), "");
    });

    test('still lets an over-limit value be shortened', () {
      expect(edit("1,000.555", "1,000.55"), "1,000.55");
      expect(edit("1,000.5555", "1,000.555"), "1,000.555");
    });
  });

  group('AppAmountFormatter decimal comma', () {
    test('reads a typed comma as the decimal point', () {
      expect(type("12,50"), "12.50");
    });

    test('reads a comma typed mid-text as the decimal point', () {
      expect(edit("1,250", "1,2,50", cursor: 4), "12.50");
    });

    test('ignores a typed comma once there is a decimal point', () {
      expect(edit("12.5", "12.5,"), "12.5");
    });

    test('reads pasted commas as grouping', () {
      expect(edit("", "1,250"), "1,250");
    });
  });
}
