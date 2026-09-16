import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  final png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ...List.filled(8, 0),
  ]);
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10]);

  group('AppImageData.mimeType', () {
    test('files with a .jpg or .jpeg extension resolve to image/jpeg', () {
      expect(AppImageData.file(File('photo.jpg')).mimeType, AppMimeTypes.jpeg);
      expect(
        AppImageData.file(File('IMG_0001.JPEG')).mimeType,
        AppMimeTypes.jpeg,
      );
    });

    test('network images, assets and data URIs are resolved', () {
      const network = AppImageData<String>.network(
        'https://cdn.example.com/avatar.png?size=64',
      );
      const asset = AppImageData<String>.asset('assets/images/logo.svg');
      const dataUri = AppImageData<String>('data:image/webp;base64,UklGRg==');

      expect(network.mimeType, AppMimeTypes.png);
      expect(network.isImage, isTrue);
      expect(asset.mimeType, AppMimeTypes.svg);
      expect(dataUri.mimeType, AppMimeTypes.webp);
    });

    test('in-memory images are typed from their content, then name', () {
      expect(AppImageData.bytes(png, name: 'avatar.jpg').mimeType, 'image/png');
      expect(
        AppImageData.bytes(Uint8List(4), name: 'avatar.webp').mimeType,
        AppMimeTypes.webp,
      );
      expect(AppImageData.bytes(png).isImage, isTrue);
    });

    test('icons and unknown images fall back to "*/*"', () {
      const icon = AppImageData<IconData>.icon(Icons.add);

      expect(icon.mimeType, AppMimeTypes.any);
      expect(icon.isImage, isFalse);
      expect(
        const AppImageData<String>.network('https://example.com/i/1').mimeType,
        AppMimeTypes.any,
      );
    });

    test('a specific contentType wins', () {
      expect(
        AppImageData.bytes(png, contentType: 'image/x-custom').mimeType,
        'image/x-custom',
      );
    });
  });

  group('AppImageData.resolveMimeType', () {
    test('reads a file rather than trusting its extension', () async {
      final directory = await Directory.systemTemp.createTemp('image_test');
      addTearDown(() => directory.delete(recursive: true));
      final file = await File('${directory.path}/a.png').writeAsBytes(jpeg);

      expect(AppImageData.file(file).mimeType, AppMimeTypes.png);
      expect(
        await AppImageData.file(file).resolveMimeType(),
        AppMimeTypes.jpeg,
      );
    });

    test('reads bundled assets', () async {
      final bundle = _FakeBundle({'assets/images/logo.png': jpeg});

      expect(
        await const AppImageData<String>.asset(
          'assets/images/logo.png',
        ).resolveMimeType(bundle: bundle),
        AppMimeTypes.jpeg,
      );
    });

    test('does not fetch URLs unless asked', () async {
      const network = AppImageData<String>.network(
        'https://cdn.example.com/avatar.gif',
      );

      expect(await network.resolveMimeType(), AppMimeTypes.gif);
    });
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, List<int>> assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = assets[key];
    if (bytes == null) throw StateError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
