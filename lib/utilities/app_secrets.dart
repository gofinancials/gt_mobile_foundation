import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Utilities}
/// Central string masking utility for masking phone numbers, OTP verification targets,
/// emails, bank account numbers, BVN, NIN, card PANs, and general strings.
///
/// Designed to be resilient, intelligent, and safe: it never throws runtime exceptions
/// on malformed, unexpected, or short inputs, dynamically scaling visible character counts
/// to always provide safe obfuscation.
///
/// Corresponding extension methods are available via [StringMaskExtension] on [String]
/// and [NullableStringMaskExtension] on [String?].
class AppStringMaskUtils {
  const AppStringMaskUtils._();

  /// Masks a phone number for privacy-compliant UI display.
  ///
  /// If [normalizeNigerian] is `true` (default) and the input represents a valid Nigerian
  /// phone number (e.g. `+2348100115314`, `2348100115314`, or `08100115314`), it is first
  /// normalized to standard 11-digit local format (`08100115314`) before applying masking.
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.maskPhoneNumber('08100115314');     // '0810*****14'
  /// AppStringMaskUtils.maskPhoneNumber('+2348100115314'); // '0810*****14'
  /// AppStringMaskUtils.maskPhoneNumber('2348100115314');  // '0810*****14'
  /// ```
  ///
  /// - [phone]: The input phone number string. Returns an empty string if null or empty.
  /// - [prefixLength]: Number of unmasked visible characters at the start (default: `4`).
  /// - [suffixLength]: Number of unmasked visible characters at the end (default: `2`).
  /// - [maskChar]: The character used to obscure digits (default: `'*'`).
  /// - [normalizeNigerian]: Whether to auto-detect and normalize Nigerian numbers (default: `true`).
  static String maskPhoneNumber(
    String? phone, {
    int prefixLength = 4,
    int suffixLength = 2,
    String maskChar = '*',
    bool normalizeNigerian = true,
  }) {
    if (phone == null || phone.trim().isEmpty) return '';

    final trimmed = phone.trim();

    String formatted = trimmed;
    if (normalizeNigerian) {
      final normalized = _tryNormalizeNigerianPhone(trimmed);
      if (normalized != null) {
        formatted = normalized;
      }
    }

    return mask(
      formatted,
      startVisible: prefixLength,
      endVisible: suffixLength,
      maskChar: maskChar,
    );
  }

  /// Convenience shorthand specifically designed for OTP verification screens.
  ///
  /// Normalizes and formats any valid Nigerian phone number into standard masked form `0810*****14`.
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.maskOtpPhone('+2348100115314'); // '0810*****14'
  /// ```
  static String maskOtpPhone(String? phone) {
    return maskPhoneNumber(
      phone,
      prefixLength: 4,
      suffixLength: 2,
      maskChar: '*',
      normalizeNigerian: true,
    );
  }

  /// Generic, intelligent string masker that masks arbitrary strings safely without throwing exceptions.
  ///
  /// Preserves [startVisible] characters at the beginning and [endVisible] characters at the end,
  /// replacing middle characters with [maskChar].
  ///
  /// If `startVisible + endVisible >= value.length`, visible counts are scaled down dynamically
  /// to ensure middle characters remain obscured without out-of-bounds errors.
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.mask('SecretString123', startVisible: 3, endVisible: 3); // 'Sec*******123'
  /// ```
  ///
  /// - [value]: The string to mask. Returns an empty string if null or empty.
  /// - [startVisible]: Number of characters to retain at the start (default: `4`).
  /// - [endVisible]: Number of characters to retain at the end (default: `2`).
  /// - [maskChar]: Character used for masking (default: `'*'`).
  /// - [fixedMaskLength]: Optional explicit count of mask characters. If null, replaces characters 1:1.
  static String mask(
    String? value, {
    int startVisible = 4,
    int endVisible = 2,
    String maskChar = '*',
    int? fixedMaskLength,
  }) {
    if (value == null || value.isEmpty) return '';

    final length = value.length;

    // Handle very short strings safely
    if (length == 1) {
      return maskChar;
    }
    if (length == 2) {
      return '$maskChar$maskChar';
    }

    int start = startVisible < 0 ? 0 : startVisible;
    int end = endVisible < 0 ? 0 : endVisible;

    // If requested visible counts exceed or equal length, scale them down dynamically
    // so that at least some characters in the middle get masked.
    if (start + end >= length) {
      start = (length / 3).floor();
      if (start < 1) start = 1;
      end = (length / 4).floor();
      if (end < 1) end = 1;

      if (start + end >= length) {
        start = 1;
        end = 0;
      }
    }

    final prefix = value.substring(0, start);
    final suffix = end > 0 ? value.substring(length - end) : '';
    final maskLength = fixedMaskLength ?? (length - start - end);
    final maskedSection = maskLength > 0 ? maskChar * maskLength : '';

    return '$prefix$maskedSection$suffix';
  }

  /// Masks the local-part (username) of an email address while keeping the domain intact.
  ///
  /// If the input does not contain an `@` symbol, it falls back to generic [mask].
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.maskEmail('user@example.com');     // 'u**r@example.com'
  /// AppStringMaskUtils.maskEmail('john.doe@example.com'); // 'j******e@example.com'
  /// ```
  ///
  /// - [email]: The email address to mask. Returns an empty string if null or empty.
  /// - [visiblePrefix]: Number of visible characters at the start of the local-part (default: `1`).
  /// - [visibleSuffix]: Number of visible characters at the end of the local-part (default: `1`).
  /// - [maskChar]: Mask character (default: `'*'`).
  static String maskEmail(
    String? email, {
    int visiblePrefix = 1,
    int visibleSuffix = 1,
    String maskChar = '*',
  }) {
    if (email == null || email.trim().isEmpty) return '';
    final trimmed = email.trim();
    if (!trimmed.contains('@')) {
      return mask(
        trimmed,
        startVisible: visiblePrefix,
        endVisible: visibleSuffix,
        maskChar: maskChar,
      );
    }

    final atIndex = trimmed.lastIndexOf('@');
    final localPart = trimmed.substring(0, atIndex);
    final domainPart = trimmed.substring(atIndex);

    if (localPart.isEmpty) return trimmed;
    if (localPart.length <= 2) {
      return '${maskChar * localPart.length}$domainPart';
    }

    final maskedLocal = mask(
      localPart,
      startVisible: visiblePrefix,
      endVisible: visibleSuffix,
      maskChar: maskChar,
    );

    return '$maskedLocal$domainPart';
  }

  /// Masks a bank account number, keeping prefix and suffix digits visible.
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.maskAccountNumber('0123456789'); // '012****789'
  /// ```
  ///
  /// - [accountNumber]: The account number to mask.
  /// - [prefixLength]: Number of leading visible digits (default: `3`).
  /// - [suffixLength]: Number of trailing visible digits (default: `3`).
  /// - [maskChar]: Mask character (default: `'*'`).
  static String maskAccountNumber(
    String? accountNumber, {
    int prefixLength = 3,
    int suffixLength = 3,
    String maskChar = '*',
  }) {
    return mask(
      accountNumber,
      startVisible: prefixLength,
      endVisible: suffixLength,
      maskChar: maskChar,
    );
  }

  /// Masks a Bank Verification Number (BVN) or National Identification Number (NIN).
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.maskBvn('22233344455'); // '222******55'
  /// ```
  ///
  /// - [bvn]: The BVN/NIN string to mask.
  /// - [prefixLength]: Number of leading visible digits (default: `3`).
  /// - [suffixLength]: Number of trailing visible digits (default: `2`).
  /// - [maskChar]: Mask character (default: `'*'`).
  static String maskBvn(
    String? bvn, {
    int prefixLength = 3,
    int suffixLength = 2,
    String maskChar = '*',
  }) {
    return mask(
      bvn,
      startVisible: prefixLength,
      endVisible: suffixLength,
      maskChar: maskChar,
    );
  }

  /// Masks a Payment Card Primary Account Number (PAN).
  ///
  /// Strips all whitespace before masking, keeping the Bank Identification Number (BIN, first 6 digits)
  /// and the last 4 digits visible.
  ///
  /// Example:
  /// ```dart
  /// AppStringMaskUtils.maskCardPan('1234 5678 1234 5678'); // '123456******5678'
  /// ```
  ///
  /// - [pan]: The card PAN string to mask.
  /// - [prefixLength]: Number of leading visible digits (default: `6`).
  /// - [suffixLength]: Number of trailing visible digits (default: `4`).
  /// - [maskChar]: Mask character (default: `'*'`).
  static String maskCardPan(
    String? pan, {
    int prefixLength = 6,
    int suffixLength = 4,
    String maskChar = '*',
  }) {
    if (pan == null || pan.isEmpty) return '';
    final cleanPan = pan.replaceAll(AppRegex.space, '');
    return mask(
      cleanPan,
      startVisible: prefixLength,
      endVisible: suffixLength,
      maskChar: maskChar,
    );
  }

  /// Internal helper to normalize Nigerian phone numbers to standard 11-digit local format (`08100115314`).
  static String? _tryNormalizeNigerianPhone(String raw) {
    String digits = raw.replaceAll(AppRegex.nonDigits, '');
    if (digits.startsWith('234')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }

    if (digits.length == 10) {
      return '0$digits';
    }

    return null;
  }
}
