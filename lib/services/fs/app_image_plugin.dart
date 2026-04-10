import 'package:gt_mobile_foundation/foundation.dart';

class AppImagePlugin {
  static Future<FsResponse> pickImage() async {
    return await AppFilePlugin.pickFile(documentType: .image);
  }
}
