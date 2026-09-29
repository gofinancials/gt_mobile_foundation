import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeFilePicker extends FilePicker with MockPlatformInterfaceMixin {
  FilePickerResult? result;
  Object? failure;
  bool? allowMultiple;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    this.allowMultiple = allowMultiple;
    final failure = this.failure;
    if (failure != null) throw failure;
    return result;
  }
}

void main() {
  late Directory directory;
  late _FakeFilePicker picker;

  // AppFilePlugin captures FilePicker.platform on first access, so the fake
  // must be installed before any pick call.
  setUpAll(() {
    picker = _FakeFilePicker();
    FilePicker.platform = picker;
  });

  setUp(() async {
    picker
      ..result = null
      ..failure = null
      ..allowMultiple = null;
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
  Future<PlatformFile> pickedFile(String name, List<int> bytes) async {
    final file = await File('${directory.path}/$name').writeAsBytes(bytes);
    return PlatformFile(path: file.path, name: name, size: bytes.length);
  }

  // Unrecognised bytes picked as an image fall back to image/*, whose limit
  // is 5 MB, so one byte over it is oversized.
  Future<PlatformFile> oversizedImage() =>
      pickedFile('huge', List.filled(5 * 1048576 + 1, 0));

  group('AppFilePlugin.pickFile', () {
    test('picks a single file', () async {
      picker.result = FilePickerResult([
        await pickedFile('report.csv', 'name,amount\n'.codeUnits),
      ]);

      final response = await AppFilePlugin.pickFile();

      expect(picker.allowMultiple, isFalse);
      expect(response.hasFile, isTrue);
      expect(response.name, 'report.csv');
      expect(response.mimeType, AppMimeTypes.csv);
    });

    test('reports a dismissal as cancelled', () async {
      final response = await AppFilePlugin.pickFile();

      expect(response.wasCancelled, isTrue);
    });
  });

  group('AppFilePlugin.pickFiles', () {
    test('returns one response per picked file, in order', () async {
      picker.result = FilePickerResult([
        await pickedFile('certificate.pdf', '%PDF-1.4\n'.codeUnits),
        await pickedFile('status.csv', 'name,amount\n'.codeUnits),
      ]);

      final responses = await AppFilePlugin.pickFiles();

      expect(picker.allowMultiple, isTrue);
      expect(responses.map((it) => it.name), ['certificate.pdf', 'status.csv']);
      expect(responses.map((it) => it.mimeType), [
        AppMimeTypes.pdf,
        AppMimeTypes.csv,
      ]);
      expect(responses.every((it) => it.hasFile && !it.hasError), isTrue);
    });

    test('applies the size limit to each file on its own', () async {
      picker.result = FilePickerResult([
        await pickedFile('small', [1, 2, 3]),
        await oversizedImage(),
      ]);

      final responses = await AppFilePlugin.pickFiles(
        documentType: FsDocumentType.image,
      );

      expect(responses, hasLength(2));
      expect(responses.first.hasFile, isTrue);
      expect(responses.last.error?.isTooLarge, isTrue);
      expect(responses.last.hasFile, isFalse);
    });

    test('reports a file without a path as empty', () async {
      picker.result = FilePickerResult([
        PlatformFile(name: 'cloud.pdf', size: 0),
        await pickedFile('local.csv', 'name,amount\n'.codeUnits),
      ]);

      final responses = await AppFilePlugin.pickFiles();

      expect(responses.first.error?.type, FsErrorType.empty);
      expect(responses.last.hasFile, isTrue);
    });

    test('returns no responses when dismissed', () async {
      expect(await AppFilePlugin.pickFiles(), isEmpty);
    });

    test('returns a single unknown error when the picker fails', () async {
      picker.failure = StateError('picker unavailable');

      final responses = await AppFilePlugin.pickFiles();

      expect(responses, hasLength(1));
      expect(responses.single.error?.isUnknown, isTrue);
      expect(responses.single.error?.error, picker.failure);
    });
  });
}
