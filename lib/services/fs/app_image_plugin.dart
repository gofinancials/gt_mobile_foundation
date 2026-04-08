import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

class AppImagePlugin {
  static Future<FSResponse> pickImage() async {
    return await AppFilePlugin.pickFile(documentType: FSDocumentType.image);
  }
}
