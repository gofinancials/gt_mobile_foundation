/// {@category Extensions}
/// Extension on [Enum] providing a convenient getter for the string label.
extension EnumExtensions on Enum {
  /// Returns the string representation of the enum value, stripping the class name.
  String get label {
    return "$this".split(".").last;
  }
}
