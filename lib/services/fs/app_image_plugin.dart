import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A plugin specifically designed for picking image files from the file system.
class AppImagePlugin {
  /// Opens the device's native file picker configured specifically to select an image file.
  static Future<FsResponse> pickImage() async {
    return await AppFilePlugin.pickFile(documentType: .image);
  }
}
