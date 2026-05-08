import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Extensions}
/// Extension on [TextEditingController] providing convenience getters for text state.
extension TextCtrlExtension on TextEditingController {
  /// Returns the current text, or `null` if the text is empty or blank.
  String? get textValue => !hasValue ? null : text;

  /// Returns `true` if the controller contains non-empty, non-blank text.
  bool get hasValue => text.hasValue;
}

/// {@category Extensions}
/// Extension on [ValueNotifier] to check for null values.
extension NotifierExtension on ValueNotifier {
  /// Returns `true` if the notifier's value is not `null`.
  bool get hasValue => value != null;
}
