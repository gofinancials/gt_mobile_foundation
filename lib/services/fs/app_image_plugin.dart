import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:path/path.dart' as p;

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

/// The format a cropped image is saved in.
/// {@category Services}
enum ImageCropFormat {
  jpg,
  png;

  /// The cropper's [ImageCompressFormat] for this format.
  ImageCompressFormat get format => switch (this) {
    jpg => .jpg,
    png => .png,
  };
}

/// A width-to-height ratio to lock the cropper to.
/// {@category Services}
class ImageCropRatio {
  final int x;
  final int y;

  const ImageCropRatio(this.x, this.y) : assert(x > 0 && y > 0);

  static const square = ImageCropRatio(1, 1);
}

/// Shows an [ImageCropRatio] as the cropper's only preset.
class _RatioPreset implements CropAspectRatioPresetData {
  final ImageCropRatio ratio;

  const _RatioPreset(this.ratio);

  @override
  String get name => '${ratio.x}x${ratio.y}';

  @override
  (int, int) get data => (ratio.x, ratio.y);
}

/// How the cropper opens on an image and saves the result.
/// {@category Services}
class ImageCropOptions {
  /// The ratio the crop is locked to, such as [ImageCropRatio.square] for a
  /// profile photo. Left out, the crop is free-form, with original, square,
  /// 3:2, 4:3 and 16:9 offered as presets.
  final ImageCropRatio? aspectRatio;

  /// Scales the cropped image down to fit within these bounds.
  final int? maxWidth;
  final int? maxHeight;

  /// The quality, from 0 to 100, the cropped image is compressed at.
  final int compressQuality;
  final ImageCropFormat compressFormat;

  /// The title shown above the cropper.
  final String? title;

  const ImageCropOptions({
    this.aspectRatio,
    this.maxWidth,
    this.maxHeight,
    this.compressQuality = 90,
    this.compressFormat = .jpg,
    this.title,
  });

  static const List<CropAspectRatioPresetData> _freeFormPresets = [
    CropAspectRatioPreset.original,
    CropAspectRatioPreset.square,
    CropAspectRatioPreset.ratio3x2,
    CropAspectRatioPreset.ratio4x3,
    CropAspectRatioPreset.ratio16x9,
  ];

  CropAspectRatio? get _cropRatio {
    final ratio = aspectRatio;
    if (ratio == null) return null;
    return CropAspectRatio(
      ratioX: ratio.x.toDouble(),
      ratioY: ratio.y.toDouble(),
    );
  }

  List<PlatformUiSettings> get _uiSettings {
    final ratio = aspectRatio;
    final locked = ratio != null;
    final presets = locked ? [_RatioPreset(ratio)] : _freeFormPresets;
    return [
      AndroidUiSettings(
        toolbarTitle: title,
        lockAspectRatio: locked,
        initAspectRatio: presets.first,
        aspectRatioPresets: presets,
      ),
      IOSUiSettings(
        title: title,
        aspectRatioLockEnabled: locked,
        resetAspectRatioEnabled: !locked,
        aspectRatioPickerButtonHidden: locked,
        aspectRatioPresets: presets,
      ),
    ];
  }
}

/// {@category Services}
/// A plugin specifically designed for picking and capturing image files from the device.
///
/// [pickImage] and [captureImage] crop by default. On Android the cropper
/// opens in its own activity, which the app must declare, or the crop fails
/// with [FsErrorType.unknown]. iOS needs no setup.
///
/// 1. Add the cropper's theme to `android/app/src/main/res/values/styles.xml`:
///    ```xml
///    <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar"/>
///    ```
/// 2. Opt it out of edge-to-edge, which the cropper does not support yet on
///    Android 15, in `android/app/src/main/res/values-v35/styles.xml`:
///    ```xml
///    <?xml version="1.0" encoding="utf-8"?>
///    <resources>
///      <style name="Ucrop.CropTheme" parent="Theme.AppCompat.Light.NoActionBar">
///        <item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>
///      </style>
///    </resources>
///    ```
/// 3. Declare the activity inside `<application>` in
///    `android/app/src/main/AndroidManifest.xml`:
///    ```xml
///    <activity
///      android:name="com.yalantis.ucrop.UCropActivity"
///      android:screenOrientation="portrait"
///      android:theme="@style/Ucrop.CropTheme"/>
///    ```
///
/// An app that passes `crop: false` everywhere needs none of this.
class AppImagePlugin {
  static final ImagePicker _picker = ImagePicker();
  static final ImageCropper _cropper = ImageCropper();

  /// Builds the response for a picked [image], typed from its content.
  static Future<FsResponse> _response(XFile image) async {
    final file = File(image.path);
    return FsResponse(
      file: file,
      name: image.name,
      type: FsDocumentType.image,
      mimeType: await AppFilePlugin.getFileMimeType(
        file,
        type: FsDocumentType.image,
        name: image.name,
      ),
    );
  }

  /// Opens the device's native file picker configured specifically to select a single image file.
  ///
  /// [imageQuality] re-encodes the image, and [maxWidth] and [maxHeight] scale
  /// it down to fit, so a large photograph can be brought under an upload
  /// limit. Left out, the image is returned as picked.
  ///
  /// The picked image then opens in the cropper, set up by [cropOptions].
  /// Pass [crop] as false to skip it. See [cropImage]. [maxWidth] and
  /// [maxHeight] scale the image before the crop;
  /// [ImageCropOptions.maxWidth] and [ImageCropOptions.maxHeight] bound the
  /// crop itself.
  static Future<FsResponse> pickImage({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    bool crop = true,
    ImageCropOptions cropOptions = const ImageCropOptions(),
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      if (image == null) {
        return const FsResponse(
          type: FsDocumentType.image,
          error: FsError(type: FsErrorType.cancelled),
        );
      }
      final response = await _response(image);
      if (!crop) return response;
      return await cropImage(response, options: cropOptions);
    } catch (e, t) {
      return FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.unknown, error: e, stackTrace: t),
      );
    }
  }

  /// Opens the device's camera to capture a new image.
  ///
  /// The photo then opens in the cropper, as it does for [pickImage].
  static Future<FsResponse> captureImage({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    ImageCameraOption cameraOption = .back,
    bool crop = true,
    ImageCropOptions cropOptions = const ImageCropOptions(),
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: cameraOption.source,
      );
      if (image == null) {
        return const FsResponse(
          type: FsDocumentType.image,
          error: FsError(type: FsErrorType.cancelled),
        );
      }
      final response = await _response(image);
      if (!crop) return response;
      return await cropImage(response, options: cropOptions);
    } catch (e, t) {
      return FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.unknown, error: e, stackTrace: t),
      );
    }
  }

  /// Opens [source]'s image in the cropper and returns the cropped image in
  /// its place, saved as [ImageCropOptions.compressFormat].
  ///
  /// A response with no file, or whose file is not an image (such as a PDF
  /// from [AppFilePlugin.pickFile]), is returned untouched. A dismissed crop
  /// comes back cancelled, as a dismissed pick does.
  static Future<FsResponse> cropImage(
    FsResponse source, {
    ImageCropOptions options = const ImageCropOptions(),
  }) async {
    final file = source.file;
    if (file == null || !_isCroppable(source.mimeType)) return source;
    try {
      final cropped = await _cropper.cropImage(
        sourcePath: file.path,
        maxWidth: options.maxWidth,
        maxHeight: options.maxHeight,
        aspectRatio: options._cropRatio,
        compressFormat: options.compressFormat.format,
        compressQuality: options.compressQuality,
        uiSettings: options._uiSettings,
      );
      if (cropped == null) {
        return FsResponse(
          type: source.type,
          error: const FsError(type: FsErrorType.cancelled),
        );
      }
      final croppedFile = File(cropped.path);
      final name = p.setExtension(
        source.name ?? p.basename(file.path),
        '.${options.compressFormat.name}',
      );
      return FsResponse(
        file: croppedFile,
        name: name,
        type: source.type,
        mimeType: await AppFilePlugin.getFileMimeType(
          croppedFile,
          type: source.type,
          name: name,
        ),
      );
    } catch (e, t) {
      return FsResponse(
        type: source.type,
        error: FsError(type: FsErrorType.unknown, error: e, stackTrace: t),
      );
    }
  }

  /// Whether the cropper can open a file of [mimeType]. Vector images are
  /// left alone, as the cropper only reads raster ones.
  static bool _isCroppable(String? mimeType) {
    final mime = mimeType?.lower ?? "";
    return mime.startsWith("image/") && mime != AppMimeTypes.svg;
  }

  /// Opens the device's native file picker to select multiple image files.
  ///
  /// The optional [limit] parameter restricts the maximum number of images
  /// a user can select. It defaults to 5.
  ///
  /// [imageQuality], [maxWidth] and [maxHeight] apply to every image, as they
  /// do for [pickImage].
  static Future<List<FsResponse>> pickImages({
    int limit = 5,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        limit: limit,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return await Future.wait(images.map(_response));
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
