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
}
