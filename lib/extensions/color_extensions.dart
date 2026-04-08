import 'package:flutter/material.dart';

extension ColorExtension on Color {
  String get asCssHexString {
    final boundaryPattern = RegExp("[Color,(,),0x]");
    String colorString = toString();
    colorString = colorString.replaceAll(boundaryPattern, "").trim();
    final opacity = colorString.substring(0, 2);
    String color = colorString.substring(2);

    if (color.length == 3) {
      color = "${color[0] * 2}${color[1] * 2}${color[2] * 2}";
    }

    return "#$color$opacity";
  }

  Color setOpacity(double opacity) {
    return withValues(alpha: opacity);
  }
}
