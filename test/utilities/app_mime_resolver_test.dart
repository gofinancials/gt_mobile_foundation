import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;

void main() {
  group('AppMimeResolver.sniff', () {
    final cases = <String, (String, List<int>)>{
      'PNG': (AppMimeTypes.png, _png),
      'JPEG': (AppMimeTypes.jpeg, _jpeg),
      'GIF': (AppMimeTypes.gif, _bytes(['GIF89a', _zeros(10)])),
      'WebP': (AppMimeTypes.webp, _riff('WEBP')),
      'TIFF': (AppMimeTypes.tiff, _bytes([0x49, 0x49, 0x2A, 0x00, _zeros(8)])),
      'BMP': (AppMimeTypes.bmp, _bytes(['BM', _zeros(12), 40, 0, 0, 0])),
      'ICO': (
        'image/x-icon',
        _bytes([0, 0, 1, 0, 1, 0, 16, 16, 0, 0, 1, 0, 32, 0]),
      ),
      'HEIC': (AppMimeTypes.heic, _ftyp('heic', ['mif1', 'heic'])),
      'HEIF with an AVIF brand': (AppMimeTypes.avif, _ftyp('mif1', ['avif'])),
      'plain HEIF': (AppMimeTypes.heif, _ftyp('mif1', ['miaf'])),
      'AVIF': (AppMimeTypes.avif, _ftyp('avif', ['mif1'])),
      'M4A': (AppMimeTypes.m4a, _ftyp('M4A ', ['isom'])),
      'MOV': (AppMimeTypes.mov, _ftyp('qt  ', ['qt  '])),
      '3GP': ('video/3gpp', _ftyp('3gp4', ['isom'])),
      'MP4': (AppMimeTypes.mp4, _ftyp('isom', ['iso2', 'mp41'])),
      'MP3 with an ID3 tag': (
        AppMimeTypes.mp3,
        _bytes(['ID3', 4, 0, 0, 0, 0, 0, 4, _zeros(4), 0xFF, 0xFB, 0x90, 0x64]),
      ),
      'FLAC with an ID3 tag': (
        'audio/x-flac',
        _bytes(['ID3', 3, 0, 0, 0, 0, 0, 0, 'fLaC', 0x00, 0, 0, 34]),
      ),
      'MP3 frame': (AppMimeTypes.mp3, _bytes([0xFF, 0xF3, 0x84, 0x64])),
      'AAC (ADTS)': (AppMimeTypes.aac, _bytes([0xFF, 0xF1, 0x50, 0x80])),
      'WAV': (AppMimeTypes.wav, _riff('WAVE')),
      'FLAC': ('audio/x-flac', _bytes(['fLaC', 0x80, 0, 0, 34])),
      'AIFF': ('audio/x-aiff', _bytes(['FORM', _zeros(4), 'AIFF'])),
      'Ogg Opus': (AppMimeTypes.ogg, _ogg('OpusHead')),
      'Ogg Theora': ('video/ogg', _ogg('\x80theora')),
      'AMR': (AppMimeTypes.amr, _bytes(['#!AMR\n', 0x3C, 0x48])),
      'MIDI': ('audio/midi', _bytes(['MThd', 0, 0, 0, 6, 0, 1])),
      'WebM': (
        AppMimeTypes.webm,
        _bytes([0x1A, 0x45, 0xDF, 0xA3, 0x9F, 0x42, 0x82, 0x84, 'webm']),
      ),
      'Matroska': (
        'video/x-matroska',
        _bytes([0x1A, 0x45, 0xDF, 0xA3, 0xA3, 0x42, 0x82, 0x88, 'matroska']),
      ),
      'AVI': ('video/x-msvideo', _riff('AVI ')),
      'MPEG transport stream': (
        'video/mp2t',
        _bytes([
          for (var i = 0; i < 3; i++) ...[0x47, ..._zeros(187)],
        ]),
      ),
      'PDF': (AppMimeTypes.pdf, _bytes(['%PDF-1.7\n', _zeros(8)])),
      'RTF': (AppMimeTypes.rtf, utf8.encode(r'{\rtf1\ansi Hello}')),
      'DOCX': (
        AppMimeTypes.docx,
        _zip({'[Content_Types].xml': '<Types/>', 'word/document.xml': '<w/>'}),
      ),
      'XLSX': (AppMimeTypes.xlsx, _zip({'xl/workbook.xml': '<wb/>'})),
      'PPTX': (AppMimeTypes.pptx, _zip({'ppt/presentation.xml': '<p/>'})),
      'ODT': (
        'application/vnd.oasis.opendocument.text',
        _zip({
          'mimetype': 'application/vnd.oasis.opendocument.text',
          'content.xml': '<office/>',
        }),
      ),
      'EPUB': (
        'application/epub+zip',
        _zip({
          'mimetype': 'application/epub+zip',
          'META-INF/container.xml': '',
        }),
      ),
      'ZIP': (AppMimeTypes.zip, _zip({'notes.txt': 'hello'})),
      'DOC': (AppMimeTypes.doc, _compoundFile('WordDocument')),
      'XLS': (AppMimeTypes.xls, _compoundFile('Workbook')),
      'unclassified compound file': (
        'application/x-cfb',
        _compoundFile('Contents'),
      ),
      'gzip': ('application/gzip', _bytes([0x1F, 0x8B, 0x08, 0x00])),
      'WOFF2': ('font/woff2', _bytes(['wOF2', 0, 1, 0, 0, _zeros(10)])),
      'OpenType': ('font/otf', _bytes(['OTTO', 0, 10, _zeros(6)])),
      'SVG': (AppMimeTypes.svg, utf8.encode('<?xml version="1.0"?>\n<svg/>')),
      'HTML': (AppMimeTypes.html, utf8.encode('<!DOCTYPE html><html></html>')),
      'XML': (AppMimeTypes.xml, utf8.encode('<?xml version="1.0"?><a/>')),
      'text': (AppMimeTypes.txt, utf8.encode('name,amount\nAda,100\n')),
      'UTF-8 text with a BOM': (
        AppMimeTypes.txt,
        [0xEF, 0xBB, 0xBF, ...utf8.encode('Grüße')],
      ),
    };

    cases.forEach((label, fixture) {
      final (type, bytes) = fixture;
      test('identifies $label', () {
        expect(AppMimeResolver.sniff(bytes), type);
      });
    });

    test('returns null for empty or unrecognised bytes', () {
      expect(AppMimeResolver.sniff([]), isNull);
      expect(AppMimeResolver.sniff(List.filled(64, 0x01)), isNull);
      expect(AppMimeResolver.sniff([0x00, 0xFF, 0x13, 0x37, 0x00]), isNull);
    });

    test('does not mistake text for short binary signatures', () {
      for (final text in [
        'Get free money',
        'OTTO was here, and so was the rest of the team',
        'ID3 tags are metadata',
        'fLaC is not a word',
        'BM is a bowel movement',
      ]) {
        expect(AppMimeResolver.sniff(utf8.encode(text)), AppMimeTypes.txt);
      }
    });
  });

  group('AppMimeResolver.resolve', () {
    test('content wins over a conflicting extension', () {
      expect(
        AppMimeResolver.resolve(bytes: _png, name: 'photo.jpg'),
        AppMimeTypes.png,
      );
      expect(
        AppMimeResolver.resolve(bytes: _pdf, name: 'statement.docx'),
        AppMimeTypes.pdf,
      );
    });

    test('an extension from the same family narrows a container', () {
      final zip = _zip({'AndroidManifest.xml': ''});
      expect(
        AppMimeResolver.resolve(bytes: zip, name: 'app.apk'),
        'application/vnd.android.package-archive',
      );
      expect(
        AppMimeResolver.resolve(bytes: _ftyp('isom', []), name: 'memo.m4a'),
        AppMimeTypes.m4a,
      );
      expect(
        AppMimeResolver.resolve(bytes: _ftyp('mp42', []), name: 'clip.MOV'),
        AppMimeTypes.mov,
      );
      expect(
        AppMimeResolver.resolve(bytes: utf8.encode('a,b\n1,2'), name: 'x.csv'),
        AppMimeTypes.csv,
      );
      expect(
        AppMimeResolver.resolve(bytes: utf8.encode('{"a":1}'), name: 'x.json'),
        AppMimeTypes.json,
      );
      expect(
        AppMimeResolver.resolve(
          bytes: _compoundFile('Contents'),
          name: 'a.ppt',
        ),
        AppMimeTypes.ppt,
      );
    });

    test('an extension from another family does not narrow a container', () {
      expect(
        AppMimeResolver.resolve(bytes: _zip({'a.txt': ''}), name: 'photo.png'),
        AppMimeTypes.zip,
      );
      expect(
        AppMimeResolver.resolve(bytes: utf8.encode('hello'), name: 'x.pdf'),
        AppMimeTypes.txt,
      );
      final docx = _zip({'word/document.xml': ''});
      expect(
        AppMimeResolver.resolve(bytes: docx, name: 'sheet.xlsx'),
        AppMimeTypes.docx,
      );
    });

    test('a specific declared type wins; a generic one is refined', () {
      expect(
        AppMimeResolver.resolve(bytes: _png, declared: 'image/jpeg'),
        'image/jpeg',
      );
      expect(
        AppMimeResolver.resolve(
          bytes: _png,
          declared: 'application/octet-stream',
        ),
        AppMimeTypes.png,
      );
      expect(
        AppMimeResolver.resolve(name: 'a.pdf', declared: 'image/*'),
        AppMimeTypes.pdf,
      );
      expect(
        AppMimeResolver.resolve(name: 'README', declared: 'image/*'),
        'image/*',
      );
    });

    test('falls back to the name, then the path, then null', () {
      final unknown = List.filled(16, 0x01);
      expect(
        AppMimeResolver.resolve(bytes: unknown, name: 'a.pdf', path: 'b.png'),
        AppMimeTypes.pdf,
      );
      expect(
        AppMimeResolver.resolve(bytes: unknown, name: 'a', path: 'b.png'),
        AppMimeTypes.png,
      );
      expect(AppMimeResolver.resolve(bytes: unknown, name: 'a'), isNull);
    });
  });

  group('AppMimeResolver paths and extensions', () {
    test('fromPath reads the extension of names, paths and URLs', () {
      expect(AppMimeResolver.fromPath('IMG_0001.JPG'), AppMimeTypes.jpeg);
      expect(AppMimeResolver.fromPath('assets/audio/lesson.mp3'), 'audio/mpeg');
      expect(
        AppMimeResolver.fromPath('https://cdn.example.com/a.mp3?token=1#t=2'),
        AppMimeTypes.mp3,
      );
      expect(
        AppMimeResolver.fromPath(r'C:\Users\me\report.xlsx'),
        AppMimeTypes.xlsx,
      );
      expect(
        AppMimeResolver.fromPath('file:///tmp/clip.mov'),
        AppMimeTypes.mov,
      );
      expect(AppMimeResolver.fromPath('voice.amr'), AppMimeTypes.amr);
    });

    test('fromPath returns null without a usable extension', () {
      expect(AppMimeResolver.fromPath(null), isNull);
      expect(AppMimeResolver.fromPath(''), isNull);
      expect(AppMimeResolver.fromPath('https://example.com'), isNull);
      expect(
        AppMimeResolver.fromPath('https://api.example.com/files/1'),
        isNull,
      );
      expect(AppMimeResolver.fromPath('https://youtu.be/dQw4w9WgXcQ'), isNull);
      expect(AppMimeResolver.fromPath('.env'), isNull);
      expect(AppMimeResolver.fromPath('archive.'), isNull);
    });

    test('fromPath reads the declared type of a data URI', () {
      expect(
        AppMimeResolver.fromPath('data:image/PNG;base64,iVBORw0KGgo='),
        AppMimeTypes.png,
      );
      expect(AppMimeResolver.fromPath('data:,hello'), isNull);
    });

    test('extensionOf and extensionFor', () {
      expect(
        AppMimeResolver.extensionOf('https://host/Statement.PDF?download=1'),
        'pdf',
      );
      expect(AppMimeResolver.extensionOf('data:image/png;base64,AAAA'), isNull);
      expect(AppMimeResolver.extensionFor(AppMimeTypes.jpeg), 'jpg');
      expect(AppMimeResolver.extensionFor('text/csv; charset=utf-8'), 'csv');
      expect(AppMimeResolver.extensionFor(AppMimeTypes.docx), 'docx');
      expect(AppMimeResolver.extensionFor('image/jpg'), 'jpg');
      expect(AppMimeResolver.extensionFor(AppMimeTypes.octetStream), 'bin');
      expect(AppMimeResolver.extensionFor(null), isNull);
    });

    test('isGeneric', () {
      for (final type in [
        null,
        '',
        '*/*',
        'image/*',
        'Application/Octet-Stream',
      ]) {
        expect(AppMimeResolver.isGeneric(type), isTrue, reason: '$type');
      }
      expect(AppMimeResolver.isGeneric('image/png; q=1'), isFalse);
    });
  });

  group('AppMimeResolver sources', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('mime_resolver_test');
    });

    tearDown(() => directory.delete(recursive: true));

    Future<File> write(String name, List<int> bytes) {
      return File('${directory.path}/$name').writeAsBytes(bytes);
    }

    test('fromFile reads content rather than trusting the extension', () async {
      final file = await write('avatar.png', _jpeg);

      expect(await AppMimeResolver.fromFile(file), AppMimeTypes.jpeg);
    });

    test('fromFile reads the ZIP directory past the header', () async {
      // The large first entry pushes the central directory well past the
      // bytes read up front, and the name gives no hint.
      final file = await write(
        'upload.bin',
        _zip({
          '[Content_Types].xml': 'x' * 40000,
          'xl/workbook.xml': '<workbook/>',
        }),
      );

      expect(await AppMimeResolver.fromFile(file), AppMimeTypes.xlsx);
    });

    test('fromFile skips a large ID3 tag to find the audio', () async {
      final tagSize = 20000;
      final file = await write('song', [
        ..._bytes([
          'ID3',
          4,
          0,
          0,
          0,
          (tagSize >> 14) & 0x7F,
          (tagSize >> 7) & 0x7F,
          tagSize & 0x7F,
        ]),
        ..._zeros(tagSize),
        ..._bytes(['fLaC', 0, 0, 0, 34]),
      ]);

      expect(await AppMimeResolver.fromFile(file), 'audio/x-flac');
    });

    test(
      'fromFile uses the picked name, then the path, when unreadable',
      () async {
        final missing = File('${directory.path}/missing.png');

        expect(
          await AppMimeResolver.fromFile(missing, name: 'scan.pdf'),
          AppMimeTypes.pdf,
        );
        expect(await AppMimeResolver.fromFile(missing), AppMimeTypes.png);
      },
    );

    test('fromXFile reads content and treats its mimeType as a hint', () async {
      final file = XFile.fromData(
        Uint8List.fromList(_png),
        path: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      expect(await AppMimeResolver.fromXFile(file), AppMimeTypes.png);
    });

    test('fromAsset reads the bundled asset', () async {
      final bundle = _FakeBundle({'assets/images/avatar.jpg': _png});

      expect(
        await AppMimeResolver.fromAsset(
          'assets/images/avatar.jpg',
          bundle: bundle,
        ),
        AppMimeTypes.png,
      );
      expect(
        await AppMimeResolver.fromAsset('assets/missing.svg', bundle: bundle),
        AppMimeTypes.svg,
      );
    });

    test(
      'fromNetwork sniffs a byte range and follows the ZIP directory',
      () async {
        final body = _zip({
          '[Content_Types].xml': 'x' * 40000,
          'word/document.xml': '<w/>',
        });
        final adapter = _RangeAdapter(body, contentType: 'binary/octet-stream');
        final dio = Dio()..httpClientAdapter = adapter;

        expect(
          await AppMimeResolver.fromNetwork(
            'https://files.example.com/1',
            dio: dio,
          ),
          AppMimeTypes.docx,
        );
        expect(adapter.ranges.first, 'bytes=0-8191');
        expect(adapter.ranges.length, greaterThan(1));
      },
    );

    test(
      'fromNetwork narrows a container with the Content-Type header',
      () async {
        final adapter = _RangeAdapter(
          _zip({'content.xml': ''}),
          contentType: 'application/vnd.oasis.opendocument.spreadsheet',
          supportsRanges: false,
        );
        final dio = Dio()..httpClientAdapter = adapter;

        expect(
          await AppMimeResolver.fromNetwork(
            'https://example.com/export',
            dio: dio,
          ),
          'application/vnd.oasis.opendocument.spreadsheet',
        );
      },
    );

    test('fromNetwork trusts content over a wrong Content-Type', () async {
      final dio = Dio()
        ..httpClientAdapter = _RangeAdapter(_png, contentType: 'image/jpeg');

      expect(
        await AppMimeResolver.fromNetwork(
          'https://example.com/a.jpg',
          dio: dio,
        ),
        AppMimeTypes.png,
      );
    });

    test('fromNetwork falls back to the URL when the request fails', () async {
      final dio = Dio()..httpClientAdapter = _RangeAdapter(_png, status: 404);

      expect(
        await AppMimeResolver.fromNetwork(
          'https://example.com/a.webp',
          dio: dio,
        ),
        AppMimeTypes.webp,
      );
    });

    test('fromSource dispatches on the kind of source', () async {
      final bundle = _FakeBundle({'assets/a.bin': _pdf});

      expect(await AppMimeResolver.fromSource(_png), AppMimeTypes.png);
      expect(
        await AppMimeResolver.fromSource(
          ByteData.sublistView(Uint8List.fromList(_jpeg)),
        ),
        AppMimeTypes.jpeg,
      );
      expect(
        await AppMimeResolver.fromSource(await write('x', _pdf)),
        AppMimeTypes.pdf,
      );
      expect(
        await AppMimeResolver.fromSource('assets/a.bin', bundle: bundle),
        AppMimeTypes.pdf,
      );
      expect(
        await AppMimeResolver.fromSource('data:image/gif;base64,R0lGODlh'),
        AppMimeTypes.gif,
      );
      expect(
        await AppMimeResolver.fromSource(
          Uri.parse('https://example.com/a.mp4'),
        ),
        AppMimeTypes.mp4,
      );
      expect(
        await AppMimeResolver.fromSource(
          'https://example.com/a',
          dio: Dio()..httpClientAdapter = _RangeAdapter(_png),
          fetchRemote: true,
        ),
        AppMimeTypes.png,
      );
      expect(
        await AppMimeResolver.fromSource(null, name: 'a.csv'),
        AppMimeTypes.csv,
      );
    });

    test('fromSource needs a client to fetch remote sources', () {
      expect(
        AppMimeResolver.fromSource('https://example.com/a', fetchRemote: true),
        throwsArgumentError,
      );
    });
  });
}

final _png = _bytes([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  _zeros(8),
]);
final _jpeg = _bytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 'JFIF', 0x00]);
final _pdf = _bytes(['%PDF-1.4\n', _zeros(8)]);

List<int> _zeros(int count) => List.filled(count, 0);

/// Flattens bytes, byte lists and Latin-1 strings.
List<int> _bytes(List<Object> parts) => [
  for (final part in parts)
    ...switch (part) {
      int byte => [byte],
      String text => latin1.encode(text),
      List<int> bytes => bytes,
      _ => throw ArgumentError(part),
    },
];

List<int> _riff(String format) =>
    _bytes(['RIFF', 36, 0, 0, 0, format, _zeros(8)]);

List<int> _ftyp(String major, List<String> compatible) {
  final size = 16 + compatible.length * 4;
  return _bytes([
    0, 0, 0, size, 'ftyp', major, 0, 0, 0, 0, ...compatible, //
    _zeros(8),
  ]);
}

List<int> _ogg(String codec) {
  return _bytes(['OggS', 0, 2, _zeros(20), 1, 19, codec, _zeros(8)]);
}

List<int> _u16(int value) => [value & 0xFF, value >> 8 & 0xFF];

List<int> _u32(int value) => [..._u16(value & 0xFFFF), ..._u16(value >> 16)];

/// A stored (uncompressed) ZIP archive with a central directory.
List<int> _zip(Map<String, String> entries) {
  final local = <int>[];
  final central = <int>[];
  for (final MapEntry(key: name, value: text) in entries.entries) {
    final nameBytes = latin1.encode(name);
    final data = latin1.encode(text);
    final offset = local.length;
    final sizes = [..._u32(0), ..._u32(data.length), ..._u32(data.length)];
    local.addAll([
      ...[0x50, 0x4B, 0x03, 0x04, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ...sizes,
      ..._u16(nameBytes.length),
      0, 0, ...nameBytes, ...data, //
    ]);
    central.addAll([
      ...[0x50, 0x4B, 0x01, 0x02, 20, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ...sizes,
      ..._u16(nameBytes.length),
      ..._zeros(12),
      ..._u32(offset),
      ...nameBytes,
    ]);
  }
  return [
    ...local,
    ...central,
    ...[0x50, 0x4B, 0x05, 0x06, 0, 0, 0, 0],
    ..._u16(entries.length),
    ..._u16(entries.length),
    ..._u32(central.length),
    ..._u32(local.length),
    0, 0, //
  ];
}

/// A compound file whose first directory sector names a root and [stream].
List<int> _compoundFile(String stream) {
  final bytes = Uint8List(1024);
  bytes.setAll(0, [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]);
  bytes.setAll(30, _u16(9));
  bytes.setAll(48, _u32(0));
  void entry(int index, String name) {
    final start = 512 + index * 128;
    for (var i = 0; i < name.length; i++) {
      bytes.setAll(start + i * 2, _u16(name.codeUnitAt(i)));
    }
    bytes.setAll(start + 64, _u16((name.length + 1) * 2));
  }

  entry(0, 'Root Entry');
  entry(1, stream);
  return bytes;
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

/// Serves [body], honouring `Range` requests unless told otherwise.
class _RangeAdapter implements HttpClientAdapter {
  _RangeAdapter(
    this.body, {
    this.contentType,
    this.supportsRanges = true,
    this.status = 200,
  });

  final List<int> body;
  final String? contentType;
  final bool supportsRanges;
  final int status;
  final ranges = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final range = options.headers[HttpHeaders.rangeHeader] as String?;
    ranges.add(range);
    final headers = {
      if (contentType != null) Headers.contentTypeHeader: [contentType!],
    };
    final match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(range ?? '');
    if (status != 200 || !supportsRanges || match == null) {
      return ResponseBody.fromBytes(body, status, headers: headers);
    }

    final start = int.parse(match[1]!);
    final end = min(int.parse(match[2]!) + 1, body.length);
    return ResponseBody.fromBytes(
      body.sublist(start, end),
      HttpStatus.partialContent,
      headers: {
        ...headers,
        HttpHeaders.contentRangeHeader: [
          'bytes $start-${end - 1}/${body.length}',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
