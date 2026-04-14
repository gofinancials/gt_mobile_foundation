import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

// ignore_for_file: deprecated_member_use

extension ColorExtension on Color {
  Color setOpacity(double opacity) {
    return withValues(alpha: opacity);
  }

  ColorSet get colorSet => ColorSet(value);

  // A color is considered bright if its luminance is greater than 0.5. This is very expensive to comput so avoid uisng it in performance critical code.
  bool get isBright => computeLuminance() > 0.5 ? true : false;

  String get asCssHex {
    final red = r.round().toRadixString(16).padLeft(2, '0');
    final green = g.round().toRadixString(16).padLeft(2, '0');
    final blue = b.round().toRadixString(16).padLeft(2, '0');
    final alpha = a.round().toRadixString(16).padLeft(2, '0');
    String hex = '#$red$green$blue';
    if (alpha != 'ff') hex += alpha;

    return hex.toUpperCase();
  }
}
