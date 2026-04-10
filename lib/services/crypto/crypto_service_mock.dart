import 'dart:convert';
import 'package:gt_mobile_foundation/foundation.dart';

class AppCryptoServiceMock implements AppCryptoService {
  @override
  String encrypt(String data, {AppCryptoMode mode = .base16}) {
    try {
      return base64Encode(data.encoded);
    } catch (e, t) {
      AppLogger.severe("Encryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String decrypt(String data, {AppCryptoMode mode = .base16}) {
    try {
      return base64Decode(data).toString();
    } catch (e, t) {
      AppLogger.severe("Decryption failed: $e", stackTrace: t, error: e);
      return data;
    }
  }

  @override
  String? encryptRsa(String data, {AppCryptoMode mode = .base16}) {
    return encrypt(data, mode: mode);
  }
}
