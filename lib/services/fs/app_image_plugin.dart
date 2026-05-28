import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// Represents the camera source option for capturing an image.
/// {@category Services}
enum ImageCameraOption {
  /// Represents the front-facing camera.
  front,

  /// Represents the back-facing camera.
  back;

  /// Converts the current [ImageCameraOption] to its corresponding [CameraDevice] value.
  ///
  /// Returns [CameraDevice.front] if the current option is [ImageCameraOption.front],
  /// and [CameraDevice.rear] if the current option is [ImageCameraOption.back].
  CameraDevice get source => switch (this) {
    front => .front,
    back => .rear,
  };
}

/// {@category Services}
/// A plugin specifically designed for picking and capturing image files from the device.
class AppImagePlugin {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the device's native file picker configured specifically to select a single image file.
  static Future<FsResponse> pickImage({int? imageQuality}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
      if (image != null) {
        return FsResponse(
          file: File(image.path),
          name: image.name,
          type: FsDocumentType.image,
        );
      }
      return const FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.empty),
      );
    } catch (e, t) {
      return FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.unknown, error: e, stackTrace: t),
      );
    }
  }

  /// Opens the device's camera to capture a new image.
  static Future<FsResponse> captureImage({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    ImageCameraOption cameraOption = .back,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: cameraOption.source,
      );
      if (image != null) {
        return FsResponse(
          file: File(image.path),
          name: image.name,
          type: FsDocumentType.image,
        );
      }
      return const FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.empty),
      );
    } catch (e, t) {
      return FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.unknown, error: e, stackTrace: t),
      );
    }
  }

  /// Opens the device's native file picker to select multiple image files.
  ///
  /// The optional [limit] parameter restricts the maximum number of images
  /// a user can select. It defaults to 5.
  static Future<List<FsResponse>> pickImages({int limit = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(limit: limit);
      if (images.isNotEmpty) {
        return images.mapList(
          (image) => FsResponse(
            file: File(image.path),
            name: image.name,
            type: FsDocumentType.image,
          ),
        );
      }
      return [];
    } catch (e, t) {
      return [
        FsResponse(
          type: FsDocumentType.image,
          error: FsError(type: FsErrorType.unknown, error: e, stackTrace: t),
        ),
      ];
    }
  }
}
