class AppRegex {
  static final mailRegEx = RegExp(
    r"\b[\w\d\W\D]+(?:@(?:[\w\d\W\D]+(?:\.(?:[\w\d\W\D]+))))\b",
  );
  static final starRegex = RegExp(r'\*$');
  static final syriacScriptRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF\u0591-\u05C7\u05D0-\u05EA\u05F0-\u05F4]',
    unicode: true,
  );
  static final rtlScriptRegex = RegExp(
    r'[\u0590-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    unicode: true,
    multiLine: true,
  );
  static final passwordRegEx = RegExp(
    r"(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^a-zA-Z0-9]).{8,}",
  );
  static final specialCharRegEx = RegExp(r"[^A-Za-z0-9]+");
  static final eightCharRegEx = RegExp(r".{8,}");
  static final phoneRegex = RegExp(r"^(\+[0-9]{1,4}\s)?[0-9]{5,15}$");
  static final imageRegex = RegExp(
    r"\.(gif|jp(e)?g|tif(f)?|png|webp|bmp|heic)$",
  );
  static final urlRegex = RegExp(
    r"^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$",
  );
  static final globalUrlRegEx = RegExp(
    r"https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)",
    caseSensitive: false,
    multiLine: true,
  );
  static final xmlRegex = RegExp(r"<.+?>");
  static final hashTagRegex = RegExp(
    r"(?<text>\#[\w\d(_)]+\b)",
    multiLine: true,
    caseSensitive: false,
  );
  static final hashTagInputRegex = RegExp(
    r"^(\#)?[\w\d(_)]+\b",
    multiLine: true,
    caseSensitive: false,
  );
  static final lowercaseRegEx = RegExp(r"[a-z]+");
  static final uppercaseRegEx = RegExp(r"[A-Z]+");
  static final xmlRegEx = RegExp(
    r"((<\w+>(.*)?<\/\w+>)|<\w+>|(<\s*\/?[^>]*>))",
    caseSensitive: false,
    multiLine: true,
  );
  static final digitRegEx = RegExp(r"\d+");
  static final customSchemeRegex = RegExp(
    r"(?<scheme>\w{1,3})(:\/)(?<path>\/[\w\W\d\D]{1,})",
    caseSensitive: false,
    multiLine: true,
  );

  static String getMatchGroupValue({
    required RegExp pattern,
    required String input,
    required String group,
  }) {
    if (!pattern.hasMatch(input)) return "";
    final match = pattern.firstMatch(input);
    return match?.namedGroup(group) ?? "";
  }
}
