import 'package:gt_mobile_foundation/foundation.dart';

abstract class AppCryptoService {
  String encrypt(String data, {AppCryptoMode mode = .base16});
  String decrypt(String data, {AppCryptoMode mode = .base16});
  String? encryptRsa(String data, {AppCryptoMode mode = .base16});
}
