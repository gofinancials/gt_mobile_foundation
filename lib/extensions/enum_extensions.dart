extension EnumExtensions on Enum {
  String get value {
    return "$this".split(".").last;
  }
}
