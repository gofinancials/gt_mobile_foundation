// ignore_for_file: deprecated_member_use

import 'dart:ui';

class ColorSet extends Color {
  final int? _dark;

  const ColorSet(super.value, [this._dark]);

  int get _inverted {
    return ((value >> 24) & 0xff) |
        ((value << 8) & 0xff0000) |
        ((value >> 8) & 0xff00) |
        ((value << 24) & 0xff000000);
  }

  ColorSet get dark => ColorSet(_dark ?? _inverted);

  @override
  ColorSpace get colorSpace => ColorSpace.sRGB;

  ColorSet forTheme(bool inDarkMode) {
    return inDarkMode ? dark : this;
  }
}
