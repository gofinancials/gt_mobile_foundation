import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppAvData in-memory media', () {
    final bytes = Uint8List.fromList([0x49, 0x44, 0x33, 0x04, 0x00]);

    test('Uint8List documents are valid memory media, never a file path', () {
      final data = AppAvData<Uint8List>(
        document: bytes,
        mediaType: AppMediaType.audio,
      );

      expect(data.isValid, isTrue);
      expect(data.isBytes, isTrue);
      expect(data.isFile, isFalse);
      expect(data.file, isNull);
      expect(data.mediaOrigin, AppMediaOrigin.memory);
      expect(data.bytesData, bytes);
    });

    test('the memory constructor matches the default constructor', () {
      final data = AppAvData<Uint8List>.memory(
        bytes,
        contentType: 'audio/mpeg',
      );

      expect(
        data,
        AppAvData<Uint8List>(document: bytes, contentType: 'audio/mpeg'),
      );
      expect(data.mediaOrigin, AppMediaOrigin.memory);
      expect(data.isAudio, isTrue);
    });

    test('memory media infers its type from contentType, then name', () {
      expect(AppAvData.memory(bytes, contentType: 'video/mp4').isVideo, isTrue);
      expect(
        AppAvData.memory(bytes, contentType: 'video/mp4').isAudio,
        isFalse,
      );
      expect(AppAvData.memory(bytes, name: 'lesson.mp3').isAudio, isTrue);
      expect(AppAvData.memory(bytes).isAudio, isFalse);
    });

    test('strings are never treated as memory', () {
      const url = AppAvData<String>(document: 'https://example.com/lesson.mp3');
      const asset = AppAvData<String>(document: 'assets/audio/lesson.mp3');
      const dataUri = AppAvData<String>(
        document: 'data:audio/mpeg;base64,SUQz',
      );

      expect(url.mediaOrigin, AppMediaOrigin.network);
      expect(asset.mediaOrigin, AppMediaOrigin.asset);
      for (final data in [url, asset, dataUri]) {
        expect(data.isBytes, isFalse);
        expect(data.bytesData, isNull);
      }
    });

    test('data URI strings no longer fabricate a file', () {
      const data = AppAvData<String>(document: 'data:audio/mpeg;base64,SUQz');

      expect(data.isFile, isFalse);
      expect(data.file, isNull);
      expect(data.isValid, isFalse);
    });
  });

  group('AppAvData.mimeType', () {
    test('resolves real MIME types from URLs, assets and files', () {
      expect(
        const AppAvData(
          document: 'https://cdn.example.com/lesson.mp3',
        ).mimeType,
        'audio/mpeg',
      );
      expect(
        const AppAvData(
          document: 'https://cdn.example.com/lesson.mp3?token=abc',
        ).mimeType,
        'audio/mpeg',
      );
      expect(
        const AppAvData(document: 'assets/video/intro.MOV').mimeType,
        'video/quicktime',
      );
      expect(AppAvData(document: File('clip.mp4')).mimeType, 'video/mp4');
    });

    test('audio media keeps an audio type for shared containers', () {
      const data = AppAvData(
        document: 'https://cdn.example.com/lesson.mp4',
        mediaType: AppMediaType.audio,
      );

      expect(data.mimeType, 'audio/mp4');
    });

    test('falls back to a wildcard for the media kind', () {
      expect(
        const AppAvData(document: 'https://youtu.be/dQw4w9WgXcQ').mimeType,
        'video/*',
      );
      expect(
        const AppAvData(
          document: 'https://api.example.com/media/1',
          mediaType: AppMediaType.audio,
        ).mimeType,
        'audio/*',
      );
      expect(const AppAvData(document: 'assets/media').mimeType, '*/*');
    });

    test('in-memory media is typed and classified from its content', () {
      final mp3 = Uint8List.fromList([
        0xFF,
        0xFB,
        0x90,
        0x64,
        ...List.filled(8, 0),
      ]);
      final data = AppAvData.memory(mp3);

      expect(data.mimeType, 'audio/mpeg');
      expect(data.isAudio, isTrue);
      expect(data.isVideo, isFalse);
    });

    test('bytes with a complete ID3 tag are audio without a name', () {
      final id3 = Uint8List.fromList([
        ...'ID3'.codeUnits, 4, 0, 0, 0, 0, 0, 0, //
        0xFF, 0xFB, 0x90, 0x64,
      ]);

      expect(AppAvData.memory(id3).isAudio, isTrue);
    });

    test('a specific contentType is returned unchanged', () {
      expect(
        const AppAvData(
          document: 'https://cdn.example.com/lesson.mp3',
          contentType: 'audio/x-custom',
        ).mimeType,
        'audio/x-custom',
      );
    });

    test(
      'resolveMimeType reads a file rather than trusting its name',
      () async {
        final directory = await Directory.systemTemp.createTemp('av_data_test');
        addTearDown(() => directory.delete(recursive: true));
        final file = await File('${directory.path}/voice.mp3').writeAsBytes([
          0,
          0,
          0,
          20,
          ...'ftypM4A '.codeUnits,
          0,
          0,
          0,
          0,
          ...'isom'.codeUnits,
        ]);

        expect(AppAvData(document: file).mimeType, 'audio/mpeg');
        expect(await AppAvData(document: file).resolveMimeType(), 'audio/mp4');
      },
    );
  });
}
