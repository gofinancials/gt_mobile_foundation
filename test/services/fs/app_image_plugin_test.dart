import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeImagePicker extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  List<XFile> images = [];
  ImageSource? source;
  ImagePickerOptions? singleOptions;
  MultiImagePickerOptions? multiOptions;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    this.source = source;
    singleOptions = options;
    return images.firstOrNull;
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    multiOptions = options;
    return images;
  }
}

class _FakeImageCropper extends ImageCropperPlatform
    with MockPlatformInterfaceMixin {
  /// The path the crop comes back at; null dismisses the cropper.
  String? croppedPath;
  int calls = 0;
  String? sourcePath;
  int? maxWidth;
  int? maxHeight;
  CropAspectRatio? aspectRatio;
  ImageCompressFormat? compressFormat;
  int? compressQuality;
  List<PlatformUiSettings>? uiSettings;

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    calls++;
    this.sourcePath = sourcePath;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.aspectRatio = aspectRatio;
    this.compressFormat = compressFormat;
    this.compressQuality = compressQuality;
    this.uiSettings = uiSettings;
    final path = croppedPath;
    return path == null ? null : CroppedFile(path);
  }
}

class _ThrowingImageCropper extends ImageCropperPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) => throw StateError('cropper failed');
}

void main() {
  late Directory directory;
  late _FakeImagePicker picker;
  late _FakeImageCropper cropper;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('image_plugin_test');
    picker = _FakeImagePicker();
    ImagePickerPlatform.instance = picker;
    cropper = _FakeImageCropper();
    ImageCropperPlatform.instance = cropper;
  });

  tearDown(() => directory.delete(recursive: true));

  Future<XFile> jpeg(String name) async {
    final file = await File(
      '${directory.path}/$name',
    ).writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    return XFile(file.path, name: name);
  }

  Future<File> png(String name) => File(
    '${directory.path}/$name',
  ).writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  Map<String, dynamic> androidSettings() =>
      cropper.uiSettings!.whereType<AndroidUiSettings>().single.toMap();

  Map<String, dynamic> iosSettings() =>
      cropper.uiSettings!.whereType<IOSUiSettings>().single.toMap();

  group('AppImagePlugin.pickImage', () {
    test('passes quality and size limits to the gallery picker', () async {
      picker.images = [await jpeg('photo.jpg')];
      cropper.croppedPath = picker.images.single.path;

      final response = await AppImagePlugin.pickImage(
        imageQuality: 80,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      expect(picker.source, ImageSource.gallery);
      expect(picker.singleOptions?.imageQuality, 80);
      expect(picker.singleOptions?.maxWidth, 2048);
      expect(picker.singleOptions?.maxHeight, 2048);
      expect(response.hasFile, isTrue);
      expect(response.mimeType, AppMimeTypes.jpeg);
    });

    test('leaves the image as picked when no limit is given', () async {
      picker.images = [await jpeg('photo.jpg')];

      await AppImagePlugin.pickImage();

      expect(picker.singleOptions?.imageQuality, isNull);
      expect(picker.singleOptions?.maxWidth, isNull);
      expect(picker.singleOptions?.maxHeight, isNull);
    });

    test('reports a dismissal as cancelled', () async {
      final response = await AppImagePlugin.pickImage(maxWidth: 2048);

      expect(response.wasCancelled, isTrue);
      expect(cropper.calls, 0);
    });

    test('opens the picked image in the cropper', () async {
      picker.images = [await jpeg('photo.png')];
      cropper.croppedPath = (await png('cropped.png')).path;

      final response = await AppImagePlugin.pickImage(
        cropOptions: const ImageCropOptions(compressFormat: .png),
      );

      expect(cropper.sourcePath, picker.images.single.path);
      expect(response.file?.path, cropper.croppedPath);
      expect(response.name, 'photo.png');
      expect(response.mimeType, AppMimeTypes.png);
      expect(response.type, FsDocumentType.image);
    });

    test('names the crop after the format it was saved in', () async {
      picker.images = [await jpeg('scan.png')];
      cropper.croppedPath = picker.images.single.path;

      final response = await AppImagePlugin.pickImage();

      expect(cropper.compressFormat, ImageCompressFormat.jpg);
      expect(response.name, 'scan.jpg');
      expect(response.mimeType, AppMimeTypes.jpeg);
    });

    test('reports a dismissed crop as cancelled', () async {
      picker.images = [await jpeg('photo.jpg')];

      final response = await AppImagePlugin.pickImage();

      expect(cropper.calls, 1);
      expect(response.wasCancelled, isTrue);
      expect(response.hasFile, isFalse);
    });

    test('returns the image as picked when crop is off', () async {
      picker.images = [await jpeg('photo.jpg')];

      final response = await AppImagePlugin.pickImage(crop: false);

      expect(cropper.calls, 0);
      expect(response.file?.path, picker.images.single.path);
      expect(response.name, 'photo.jpg');
    });
  });

  group('AppImagePlugin.captureImage', () {
    test('opens the photo in the cropper', () async {
      picker.images = [await jpeg('photo.jpg')];
      cropper.croppedPath = picker.images.single.path;

      final response = await AppImagePlugin.captureImage(
        cropOptions: const ImageCropOptions(maxWidth: 1024),
      );

      expect(picker.source, ImageSource.camera);
      expect(cropper.maxWidth, 1024);
      expect(response.hasFile, isTrue);
    });

    test('returns the photo as taken when crop is off', () async {
      picker.images = [await jpeg('photo.jpg')];

      final response = await AppImagePlugin.captureImage(crop: false);

      expect(cropper.calls, 0);
      expect(response.hasFile, isTrue);
    });
  });

  group('AppImagePlugin.cropImage', () {
    Future<FsResponse> picked(String name, String mimeType) async {
      final file = await File('${directory.path}/$name').writeAsBytes([0]);
      return FsResponse(
        file: file,
        name: name,
        type: FsDocumentType.image,
        mimeType: mimeType,
      );
    }

    test('passes a PDF through untouched', () async {
      final source = await picked('bill.pdf', AppMimeTypes.pdf);

      final response = await AppImagePlugin.cropImage(source);

      expect(cropper.calls, 0);
      expect(response, source);
    });

    test('passes an SVG through untouched', () async {
      final source = await picked('logo.svg', AppMimeTypes.svg);

      expect(await AppImagePlugin.cropImage(source), source);
      expect(cropper.calls, 0);
    });

    test('passes a response with no file through untouched', () async {
      const source = FsResponse(
        type: FsDocumentType.image,
        error: FsError(type: FsErrorType.oversized),
      );

      expect(await AppImagePlugin.cropImage(source), source);
      expect(cropper.calls, 0);
    });

    test('is free-form by default', () async {
      await AppImagePlugin.cropImage(
        await picked('photo.jpg', AppMimeTypes.jpeg),
      );

      expect(cropper.aspectRatio, isNull);
      expect(cropper.compressQuality, 90);
      expect(androidSettings()['android.lock_aspect_ratio'], isFalse);
      expect(iosSettings()['ios.aspect_ratio_lock_enabled'], isFalse);
      expect(
        (androidSettings()['android.aspect_ratio_presets'] as List).map(
          (it) => it['name'],
        ),
        ['original', 'square', '3x2', '4x3', '16x9'],
      );
    });

    test('locks to the given ratio and passes output limits', () async {
      await AppImagePlugin.cropImage(
        await picked('photo.jpg', AppMimeTypes.jpeg),
        options: const ImageCropOptions(
          aspectRatio: .square,
          maxWidth: 1024,
          maxHeight: 768,
          compressQuality: 80,
          compressFormat: .png,
          title: 'Crop photo',
        ),
      );

      expect(cropper.aspectRatio, const CropAspectRatio(ratioX: 1, ratioY: 1));
      expect(cropper.maxWidth, 1024);
      expect(cropper.maxHeight, 768);
      expect(cropper.compressQuality, 80);
      expect(cropper.compressFormat, ImageCompressFormat.png);
      expect(androidSettings()['android.lock_aspect_ratio'], isTrue);
      expect(androidSettings()['android.toolbar_title'], 'Crop photo');
      expect(androidSettings()['android.aspect_ratio_presets'], [
        {
          'name': '1x1',
          'data': {'ratio_x': 1, 'ratio_y': 1},
        },
      ]);
      expect(iosSettings()['ios.aspect_ratio_lock_enabled'], isTrue);
      expect(iosSettings()['ios.aspect_ratio_picker_button_hidden'], isTrue);
      expect(iosSettings()['ios.title'], 'Crop photo');
    });

    test('reports a cropper failure as unknown', () async {
      ImageCropperPlatform.instance = _ThrowingImageCropper();

      final response = await AppImagePlugin.cropImage(
        await picked('photo.jpg', AppMimeTypes.jpeg),
      );

      expect(response.error?.isUnknown, isTrue);
      expect(response.hasFile, isFalse);
    });
  });

  group('AppImagePlugin.pickImages', () {
    test('passes quality and size limits for every image', () async {
      picker.images = [await jpeg('front.jpg'), await jpeg('back.jpg')];

      final responses = await AppImagePlugin.pickImages(
        limit: 3,
        imageQuality: 80,
        maxWidth: 2048,
        maxHeight: 1024,
      );

      final options = picker.multiOptions;
      expect(options?.limit, 3);
      expect(options?.imageOptions.imageQuality, 80);
      expect(options?.imageOptions.maxWidth, 2048);
      expect(options?.imageOptions.maxHeight, 1024);
      expect(responses.map((it) => it.name), ['front.jpg', 'back.jpg']);
    });

    test('leaves the images as picked when no limit is given', () async {
      await AppImagePlugin.pickImages();

      final options = picker.multiOptions?.imageOptions;
      expect(picker.multiOptions?.limit, 5);
      expect(options?.imageQuality, isNull);
      expect(options?.maxWidth, isNull);
      expect(options?.maxHeight, isNull);
    });
  });
}
