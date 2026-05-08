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
  static final jpegRegex = RegExp(r"\.jp(e)?g$", caseSensitive: false);
  static final videoRegex = RegExp(
    r"\.(flv|webm|mkv|vob|ogv|ogg|drc|mp4|drc|avi|mov|qt|mts|ts|m2ts|wmv|amv|m4p|m4v|mpg|mpeg|mp2|mpe|mpv|flv|m4v|svi|3gp|3g2|f4v|f4p|f4a|f4b)$",
    caseSensitive: false,
  );
  static final cvvRegex = RegExp(r"^\d{3}(\d)?$");
  static final visaRegex = RegExp(r"^4[0-9]{12}(?:[0-9]{3})?$");
  static final masterRegex = RegExp(
    r"(^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$)|(^(?:5[13]99|55[35][19]|514[36])(?:11|4[10]|23|83|88)(?:[0-9]{10})$)",
  );
  static final amexRegex = RegExp(r"^3[47][0-9]{13}$");
  static final jcbRegex = RegExp(r"^(?:2131|1800|35\d{3})\d{11}$");
  static final maestroRegex = RegExp(
    r"^(5899|5018|5020|5038|6304|6703|6708|6759|676[1-3])[06][19](?:[0-9]{10})$",
  );
  static final verveRegex = RegExp(r"^(?:50[067][180]|6500)(?:[0-9]{15})$");
  static final unionpayRegex = RegExp(r"^(62[0-9]{14,17})$");
  static final visaPrefixRegex = RegExp(r"^4");
  static final masterPrefixRegex = RegExp(
    r"(^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720))|(^(?:5[13]99|55[35][19]|514[36])(?:11|4[10]|23|83|88))",
  );
  static final startsWithDigit = RegExp(r"^\d");
  static final amexPrefixRegex = RegExp(r"^3[47]");
  static final jcbPrefixRegex = RegExp(r"^(?:2131|1800|35\d{3})");
  static final maestroPrefixRegex = RegExp(
    r"^5899|5018|5020|5038|6304|6703|6708|6759|676[1-3]",
    multiLine: true,
  );
  static final vervePrefixRegex = RegExp(r"^(50[067][180])|(6500)");
  static final unionpayPrefixRegex = RegExp(r"^62");
  static final visaNumRegex = RegExp(r"^(\d{8}|([A-Z]{1,2}\d{5,7}))$");
  static final usPassportRegex = RegExp(r"^[A-Z]\d{8,9}");
  static final ngPassportRegex = RegExp(r"^[A-Z]\d{8}");
  static final bvnRegex = RegExp(r"^\d{11}$");
  static final nubanRegex = RegExp(r"^\d{10}$");

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
