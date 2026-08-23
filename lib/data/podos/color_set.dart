// ignore_for_file: deprecated_member_use

import 'dart:ui';

/// {@category Data}
/// A custom [Color] subclass that manages a light and dark theme pair.
///
/// It automatically calculates an inverted color for dark mode if none is provided.
class ColorSet extends Color {
  final int? _dark;

  const ColorSet(super.value, [this._dark]);

  int get _inverted => value ^ 0x00ffffff;

  ColorSet get dark => ColorSet(_dark ?? _inverted);

  @override
  ColorSpace get colorSpace => ColorSpace.sRGB;

  ColorSet forTheme(bool inDarkMode) {
    return inDarkMode ? dark : this;
  }
}
