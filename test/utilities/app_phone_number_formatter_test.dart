import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// Runs the formatter over an edit from [before] to [after].
String edit(String before, String after) {
  return AppPhoneNumberFormatter()
      .formatEditUpdate(
        TextEditingValue(
          text: before,
          selection: TextSelection.collapsed(offset: before.length),
        ),
        TextEditingValue(
          text: after,
          selection: TextSelection.collapsed(offset: after.length),
        ),
      )
      .text;
}

/// Types [keys] into an empty field one character at a time.
String type(String keys) {
  var text = "";
  for (final key in keys.split("")) {
    text = edit(text, "$text$key");
  }
  return text;
}

/// Backspaces [text] one character at a time until it is empty, or until
/// the formatter refuses a deletion.
String backspace(String text) {
  while (text.isNotEmpty) {
    final next = edit(text, text.substring(0, text.length - 1));
    if (next == text) return text;
    text = next;
  }
  return text;
}

void main() {
  group('AppPhoneNumberFormatter', () {
    test('formats digits as they are typed', () {
      expect(type("08031234567"), "0803 123 4567");
    });

    test('rejects letters in the first four characters', () {
      expect(type("ab"), "");
      expect(type("08a"), "08");
      expect(edit("080", "080x"), "080");
    });

    test('rejects letters a number parser would accept', () {
      expect(type("NaN"), "");
      expect(edit("0803", "0803e"), "0803");
      expect(edit("", "0x1f"), "");
      expect(edit("", "Infinity"), "");
    });

    test('rejects a pasted value with letters', () {
      expect(edit("", "0803abc4567"), "");
    });

    test('keeps a leading plus', () {
      expect(type("+234"), "+234");
      expect(type("+2348031234567"), "+234 803 123 4567");
    });

    test('keeps a leading plus on a pasted number', () {
      expect(edit("", "+234 803 123 4567"), "+234 803 123 4567");
    });

    test('lets a number be backspaced to empty', () {
      expect(backspace(type("08031234567")), "");
    });

    test('lets letters already in the field be deleted', () {
      expect(backspace("ab"), "");
    });

    test('stops at fifteen digits', () {
      expect(type("1234567890123456").replaceAll(" ", "").length, 15);
    });
  });
}
