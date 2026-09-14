import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppDocumentData in-memory documents', () {
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]);

    test('Uint8List documents are valid memory documents', () {
      final data = AppDocumentData<Uint8List>(
        bytes,
        contentType: 'application/pdf',
      );

      expect(data.isValid, isTrue);
      expect(data.isBytes, isTrue);
      expect(data.file, isNull);
      expect(data.mediaOrigin, AppMediaOrigin.memory);
      expect(data.bytesData, bytes);
      expect(data.mimeType, 'application/pdf');
    });

    test('the memory constructor matches the default constructor', () {
      final data = AppDocumentData<Uint8List>.memory(
        bytes,
        contentType: 'application/pdf',
      );

      expect(
        data,
        AppDocumentData<Uint8List>(bytes, contentType: 'application/pdf'),
      );
      expect(data.mediaOrigin, AppMediaOrigin.memory);
    });

    test('data URI strings no longer fabricate a file', () {
      const data = AppDocumentData<String>('data:application/pdf;base64,JVBE');

      expect(data.isBytes, isFalse);
      expect(data.isFile, isFalse);
      expect(data.file, isNull);
      expect(data.isValid, isFalse);
    });

    test('files and URLs keep their existing origins', () {
      final file = File('statement.pdf');

      expect(AppDocumentData<File>(file).file, file);
      expect(AppDocumentData<File>(file).mediaOrigin, AppMediaOrigin.file);
      expect(
        const AppDocumentData<String>(
          'https://example.com/statement.pdf',
        ).mediaOrigin,
        AppMediaOrigin.network,
      );
    });
  });
}
