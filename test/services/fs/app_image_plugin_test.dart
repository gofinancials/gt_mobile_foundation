import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
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

void main() {
  late Directory directory;
  late _FakeImagePicker picker;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('image_plugin_test');
    picker = _FakeImagePicker();
    ImagePickerPlatform.instance = picker;
  });

  tearDown(() => directory.delete(recursive: true));

  Future<XFile> jpeg(String name) async {
    final file = await File(
      '${directory.path}/$name',
    ).writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    return XFile(file.path, name: name);
  }

  group('AppImagePlugin.pickImage', () {
    test('passes quality and size limits to the gallery picker', () async {
      picker.images = [await jpeg('photo.jpg')];

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
