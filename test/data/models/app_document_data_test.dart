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

  group('AppDocumentData.mimeType', () {
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]);

    test('resolves real MIME types instead of "*/<extension>"', () {
      expect(
        AppDocumentData(File('statement.pdf')).mimeType,
        'application/pdf',
      );
      expect(
        const AppDocumentData(
          'https://api.example.com/documents/42',
          name: 'Statement.PDF',
        ).mimeType,
        'application/pdf',
      );
      expect(
        const AppDocumentData('https://example.com/r.xlsx?dl=1').mimeType,
        AppMimeTypes.xlsx,
      );
    });

    test('in-memory documents are typed from their content', () {
      final pdf = AppDocumentData.memory(bytes, name: 'statement.docx');

      expect(pdf.mimeType, 'application/pdf');
    });

    test('generic contentTypes are refined; unknown documents are "*/*"', () {
      expect(
        AppDocumentData.memory(
          bytes,
          contentType: 'application/octet-stream',
        ).mimeType,
        'application/pdf',
      );
      expect(
        AppDocumentData.memory(
          Uint8List.fromList([1, 2, 3]),
          contentType: 'application/octet-stream',
        ).mimeType,
        'application/octet-stream',
      );
      expect(const AppDocumentData('assets/docs/terms').mimeType, '*/*');
    });

    test(
      'resolveMimeType reads a file rather than trusting its name',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'document_test',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = await File(
          '${directory.path}/scan.docx',
        ).writeAsBytes(bytes);

        expect(AppDocumentData(file).mimeType, AppMimeTypes.docx);
        expect(
          await AppDocumentData(file).resolveMimeType(),
          'application/pdf',
        );
      },
    );
  });
}
