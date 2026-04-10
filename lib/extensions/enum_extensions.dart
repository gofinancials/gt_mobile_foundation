extension EnumExtensions on Enum {
  String get label {
    return "$this".split(".").last;
  }
}
