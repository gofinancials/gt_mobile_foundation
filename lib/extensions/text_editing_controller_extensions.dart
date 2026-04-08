import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';
import 'package:flutter/material.dart';

extension TextCtrlExtension on TextEditingController {
  String? get textValue => !hasValue ? null : text;

  bool get hasValue => text.hasValue;
}

extension NotifierExtension on ValueNotifier {
  bool get hasValue => value != null;
}
