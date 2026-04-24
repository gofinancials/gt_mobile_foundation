import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

// ignore_for_file: deprecated_member_use

extension ColorExtension on Color {
  /// Sets the opacity of the color.
  ///
  /// Returns a new [Color] with the given [opacity] (alpha value).
  Color setOpacity(double opacity) {
    return withValues(alpha: opacity);
  }

  /// Returns a [ColorSet] derived from the current color's value.
  ColorSet get colorSet => ColorSet(value);

  /// A color is considered bright if its luminance is greater than 0.5. 
  /// 
  /// Note: This is very expensive to compute so avoid using it in performance critical code.
  bool get isBright => computeLuminance() > 0.5 ? true : false;

  /// Converts a Flutter Color to a CSS hex string.
  ///
  /// Returns a 6-character hex (e.g., #FF0000) by default.
  /// If [includeAlpha] is true, returns an 8-character hex (e.g., #FF000080).
  String toCssHex({bool includeAlpha = false}) {
    // Mask out the alpha channel to get just RGB, convert to hex, and pad to 6 chars
    final rgb = (value & 0x00FFFFFF).toRadixString(16).padLeft(6, '0');

    if (includeAlpha) {
      // Unsigned right shift by 24 to get the alpha value, convert, and pad
      final a = (value >>> 24).toRadixString(16).padLeft(2, '0');
      // CSS appends alpha to the end: #RRGGBBAA
      return '#$rgb$a'.toUpperCase();
    }

    return '#$rgb'.toUpperCase();
  }
}
