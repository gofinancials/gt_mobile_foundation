import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('file_plugin_test');
  });

  tearDown(() => directory.delete(recursive: true));

  group('AppFilePlugin.getFileMimeType', () {
    test('reads the file content rather than trusting its extension', () async {
      final file = await File(
        '${directory.path}/avatar.png',
      ).writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

      expect(await AppFilePlugin.getFileMimeType(file), AppMimeTypes.jpeg);
    });

    test('uses the picked name when content is unrecognised', () async {
      final file = await File(
        '${directory.path}/cache_1234',
      ).writeAsString('name,amount\nAda,100\n');

      expect(
        await AppFilePlugin.getFileMimeType(file, name: 'statement.csv'),
        AppMimeTypes.csv,
      );
    });

    test('falls back to image/* for images, else null', () async {
      final file = await File('${directory.path}/blob').writeAsBytes([1, 2, 3]);

      expect(
        await AppFilePlugin.getFileMimeType(file, type: FsDocumentType.image),
        AppMimeTypes.image,
      );
      expect(
        await AppFilePlugin.getFileMimeType(
          file,
          type: FsDocumentType.document,
        ),
        isNull,
      );
    });
  });
}
