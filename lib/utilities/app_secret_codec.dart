// Plain Dart on purpose: bin/mask_secret.dart imports this file alone, so
// `dart run gt_mobile_foundation:mask_secret` runs without Flutter.

/// {@category Utilities}
/// Provides reversible masking and redaction utilities for sensitive configuration values.
///
/// This codec helps prevent plaintext secrets (such as API keys, tokens, or environment
/// variables) from appearing directly in source files, logs, crash reports, or CI artifacts.
///
/// ### Encoding Scheme
/// The encoding algorithm masks data by converting each character into a fixed-width,
/// zero-padded 3-digit group. The value of each group equals the character's code unit
/// plus its 1-based positional index:
/// ```text
/// shiftedValue = codeUnit + index + 1
/// ```
/// Because the shift increases with each character position, repeated characters produce
/// distinct digit groups, preventing pattern analysis.
///
/// This format is compatible with the `SensitiveDataUtils` masking scheme used across
/// client applications to share environment values.
///
/// > **Note:** This utility provides obfuscation to guard against accidental exposure in
/// > logs and diffs; it is not cryptographic encryption. Anyone with access to the client
/// > binary can reverse the masking. Always ensure sensitive credentials and environment
/// > files remain gitignored and properly secured.
class AppSecretCodec {
  const AppSecretCodec._();

  /// The fixed number of digits representing each masked character (3 digits per character).
  static const _groupSize = 3;

  /// The upper bound for a single digit group value (`1000`).
  ///
  /// Since the positional shift increases with string length, shifted values must remain
  /// strictly less than this ceiling to fit within a 3-digit group.
  static const _groupCeiling = 1000;

  /// Encodes [value] into a masked, position-shifted digit-group string.
  ///
  /// Each character in [value] is shifted by its 1-based index and formatted as a
  /// zero-padded 3-digit group.
  ///
  /// Throws an [ArgumentError] if any shifted character code unit reaches or exceeds
  /// `1000` (e.g. non-ASCII characters or strings that exceed maximum supported length).
  ///
  /// Returns the masked digit-sequence string.
  static String encode(String value) {
    final masked = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final shifted = value.codeUnitAt(index) + index + 1;
      if (shifted >= _groupCeiling) {
        throw ArgumentError.value(
          value,
          'value',
          'Character at index $index does not fit a $_groupSize-digit group. '
              'Masking supports ASCII values short enough to stay under '
              '$_groupCeiling once shifted by position.',
        );
      }
      masked.write(shifted.toString().padLeft(_groupSize, '0'));
    }
    return masked.toString();
  }

  /// Decodes a masked [encoded] string back to its original plain text value.
  ///
  /// Reverses the positional shift applied by [encode]. If [encoded] is empty,
  /// returns an empty string.
  ///
  /// Throws a [FormatException] if:
  /// - The length of [encoded] is not a multiple of 3.
  /// - Any 3-digit group cannot be parsed as an integer.
  /// - The calculated character code unit is negative or invalid.
  ///
  /// Returns the decoded plain text string.
  static String decode(String encoded) {
    if (encoded.isEmpty) return '';
    if (encoded.length % _groupSize != 0) {
      throw const FormatException(
        'Masked configuration must be grouped in 3-digit chunks.',
      );
    }

    final characters = <String>[];
    for (var index = 0; index < encoded.length; index += _groupSize) {
      final group = encoded.substring(index, index + _groupSize);
      final shifted = int.tryParse(group);
      if (shifted == null) {
        throw FormatException(
          'Masked configuration group "$group" is not numeric.',
        );
      }
      final codeUnit = shifted - (characters.length + 1);
      if (codeUnit < 0) {
        throw FormatException(
          'Masked configuration group "$group" is out of range.',
        );
      }
      characters.add(String.fromCharCode(codeUnit));
    }

    return characters.join();
  }

  /// Resolves a configuration secret from [masked] and [plain] candidates.
  ///
  /// If [masked] is non-empty, it is decoded via [decode] and returned.
  /// Otherwise, [plain] is returned as a fallback. This enables seamless migration
  /// of configuration secrets from plain text to masked representations.
  static String resolve({required String masked, required String plain}) {
    return masked.isEmpty ? plain : decode(masked);
  }

  /// Returns a log-safe, redacted version of [value], exposing only the trailing [visible] characters.
  ///
  /// Replaces leading characters with asterisks (`*`). If [value] is empty, an empty string
  /// is returned. If the length of [value] is less than or equal to [visible], the entire
  /// string is masked with asterisks.
  ///
  /// Example:
  /// ```dart
  /// AppSecretCodec.redact('sk_live_123456789', visible: 4); // '***************6789'
  /// ```
  static String redact(String value, {int visible = 4}) {
    if (value.isEmpty) return '';
    if (value.length <= visible) return '*' * value.length;
    return '${'*' * (value.length - visible)}${value.substring(value.length - visible)}';
  }
}
