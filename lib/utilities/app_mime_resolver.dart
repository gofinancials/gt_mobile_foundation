import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:mime/mime.dart' as mime;

/// A signature match: the detected [type], and whether it is a [container]
/// that a name or header from the same family may narrow further.
typedef _Sniffed = ({String type, bool container});

typedef _RangeReader = Future<List<int>> Function(int offset, int count);

/// {@category Utilities}
/// Resolves MIME types from what a source actually contains.
///
/// Extensions, `Content-Type` headers and caller-supplied types can all
/// disagree with the data, so every entry point follows one order:
///
/// 1. A specific declared type, such as a stored `contentType`, is trusted.
/// 2. The content's signature, when content is available.
/// 3. Hints, in order: a server's `Content-Type`, then the extension of a
///    name, path or URL.
///
/// Some signatures only identify a container: every DOCX is a ZIP archive and
/// every M4A an ISO media file. When content can't be told apart any further,
/// a hint from the same family narrows the result, so a plain ZIP named
/// `report.xlsx` resolves to XLSX. A hint from another family is ignored, so
/// PNG bytes named `photo.jpg` stay `image/png`.
///
/// Generic types such as `application/octet-stream` or `image/*` never
/// override anything; they are returned only when nothing better is found.
abstract final class AppMimeResolver {
  /// Bytes read from the start of a file, stream or URL before sniffing.
  static const _headLength = 8192;

  /// Bytes inspected when deciding whether content is text.
  static const _textWindow = 4096;

  /// The end-of-central-directory record plus the longest archive comment.
  static const _zipTailLength = 65557;
  static const _zipDirectoryLimit = 1 << 20;

  /// Extra reads allowed for structures beyond the header.
  static const _extraReads = 4;

  static const _cfb = "application/x-cfb";
  static const _matroska = "video/x-matroska";
  static const _asf = "video/x-ms-asf";

  static const _genericTypes = {
    AppMimeTypes.octetStream,
    "binary/octet-stream",
    "application/binary",
    "application/unknown",
    "application/x-unknown",
    "application/force-download",
    "application/x-download",
  };

  /// Extensions the `mime` package does not map.
  static const _extensionTypes = {
    "3ga": "audio/3gpp",
    "amr": AppMimeTypes.amr,
    "awb": "audio/amr-wb",
    "cr3": "image/x-canon-cr3",
    "gz": "application/gzip",
    "heics": "image/heic-sequence",
    "heifs": "image/heif-sequence",
    "m4b": AppMimeTypes.m4a,
    "msg": "application/vnd.ms-outlook",
    "tgz": "application/gzip",
    "vtt": "text/vtt",
    "yaml": "application/yaml",
    "yml": "application/yaml",
  };

  /// Preferred extensions for types the `mime` package does not map,
  /// including common non-standard spellings.
  static const _typeExtensions = {
    "application/gzip": "gz",
    "application/vnd.ms-outlook": "msg",
    "application/x-cfb": "cfb",
    "application/yaml": "yaml",
    "audio/3gpp": "3ga",
    "audio/amr": "amr",
    "audio/amr-wb": "awb",
    "audio/m4a": "m4a",
    "audio/mp3": "mp3",
    "audio/wav": "wav",
    "audio/x-m4a": "m4a",
    "image/heic-sequence": "heics",
    "image/heif-sequence": "heifs",
    "image/jpg": "jpg",
    "image/x-canon-cr3": "cr3",
    "text/vtt": "vtt",
  };

  static const _textualTypes = {
    AppMimeTypes.json,
    AppMimeTypes.xml,
    "application/javascript",
    "application/x-sh",
    "application/x-sql",
    "application/x-subrip",
    "application/x-tex",
    "application/yaml",
  };

  /// Types each container signature may be narrowed to by a hint.
  static final Map<String, Set<String>> _families = {
    AppMimeTypes.zip: _typesOf(const [
      "docx", "docm", "dotx", "dotm", "xlsx", "xlsm", "xltx", "xltm", //
      "pptx", "pptm", "potx", "potm", "ppsx", "ppsm", "odt", "ott", "ods",
      "odp", "odg", "epub", "apk", "jar", "kmz", "xpi",
    ]),
    AppMimeTypes.docx: _typesOf(const ["docm", "dotx", "dotm"]),
    AppMimeTypes.xlsx: _typesOf(const ["xlsm", "xltx", "xltm"]),
    AppMimeTypes.pptx: _typesOf(const ["pptm", "potx", "potm", "ppsx", "ppsm"]),
    _cfb: _typesOf(const ["doc", "xls", "ppt", "msg", "msi", "vsd", "pub"]),
    AppMimeTypes.mp4: _typesOf(const [
      "m4a",
      "m4v",
      "mov",
      "3gp",
      "3g2",
      "f4v",
    ]),
    AppMimeTypes.webm: _typesOf(const ["weba"]),
    _matroska: _typesOf(const ["mka", "webm", "weba"]),
    AppMimeTypes.ogg: _typesOf(const ["ogv", "ogx"]),
    _asf: _typesOf(const ["wmv", "wma"]),
  };

  static final _dataUriRegex = RegExp(
    r"^data:([\w.+-]+/[\w.+-]+)[;,]",
    caseSensitive: false,
  );
  static final _schemeRegex = RegExp(
    r"^[a-z][a-z0-9+.-]+:",
    caseSensitive: false,
  );
  static final _pathSeparatorRegex = RegExp(r"[\\/]");
  static final _typeRegex = RegExp(r"^application/[\w.+-]+$");

  /// Returns `true` when [mimeType] says nothing specific: it is absent, a
  /// wildcard such as `image/*`, or an unknown-binary type such as
  /// `application/octet-stream`.
  static bool isGeneric(String? mimeType) {
    final type = _normalise(mimeType);
    return type == null || type.contains("*") || _genericTypes.contains(type);
  }

  /// Resolves a MIME type without any I/O.
  ///
  /// A specific [declared] type wins. Otherwise [bytes], when given, are
  /// identified by their content, with the extensions of [name] then [path]
  /// as hints. Returns `null` when nothing is known.
  static String? resolve({
    List<int>? bytes,
    String? name,
    String? path,
    String? declared,
  }) {
    if (!isGeneric(declared)) return declared;
    return _decide(
      declared: declared,
      sniffed: bytes == null ? null : _sniff(_Sample.of(bytes)),
      hints: [fromPath(name), fromPath(path)],
    );
  }

  /// Identifies [bytes] from their content alone, or returns `null` when no
  /// signature matches.
  ///
  /// Pass the whole payload where possible: some formats, such as DOCX inside
  /// a ZIP archive, are told apart by structures past the first few bytes.
  static String? sniff(List<int> bytes) => _sniff(_Sample.of(bytes))?.type;

  /// Resolves [path] from its extension, without reading any content.
  ///
  /// Accepts file names, file paths, asset keys and URLs, ignoring a URL's
  /// query and fragment. A `data:` URI resolves to its declared type.
  static String? fromPath(String? path) {
    if (!path.hasValue) return null;
    final dataType = _dataUriType(path!);
    if (dataType != null) return dataType;

    final extension = extensionOf(path);
    if (extension == null) return null;
    return _extensionTypes[extension] ?? mime.lookupMimeType("file.$extension");
  }

  /// Resolves [file] from its content, reading its header and, for container
  /// formats, the few structures that identify them.
  ///
  /// [name] is the original file name when it differs from the path, as with
  /// picked files. When the file can't be read, the extensions of [name] and
  /// the path are used instead.
  static Future<String?> fromFile(
    File file, {
    String? name,
    String? declared,
  }) async {
    if (!isGeneric(declared)) return declared;

    _Sniffed? sniffed;
    RandomAccessFile? handle;
    try {
      final opened = handle = await file.open();
      final sample = _Sample(await opened.length());
      sniffed = await _sniffRanges(sample, (offset, count) async {
        await opened.setPosition(offset);
        return opened.read(count);
      });
    } catch (e) {
      AppLogger.info("Could not read ${file.path} for its MIME type: $e");
    } finally {
      await handle?.close();
    }

    return _decide(
      declared: declared,
      sniffed: sniffed,
      hints: [fromPath(name), fromPath(file.path)],
    );
  }

  /// Resolves a picked or shared [file] from its content.
  ///
  /// The file's own `mimeType` is only a hint, because platforms usually
  /// derive it from the extension.
  static Future<String?> fromXFile(XFile file, {String? declared}) async {
    if (!isGeneric(declared)) return declared;

    _Sniffed? sniffed;
    try {
      final length = await file.length();
      sniffed = await _sniffRanges(_Sample(length), (offset, count) {
        final end = min(offset + count, length);
        return _collect(file.openRead(offset, end), end - offset);
      });
    } catch (e) {
      AppLogger.info("Could not read ${file.name} for its MIME type: $e");
    }

    return _decide(
      declared: declared,
      sniffed: sniffed,
      hints: [file.mimeType, fromPath(file.name), fromPath(file.path)],
    );
  }

  /// Resolves the bundled asset [key] from its content.
  ///
  /// The asset is loaded whole, since bundles don't support partial reads.
  /// When it can't be loaded, the extensions of [name] and [key] are used.
  static Future<String?> fromAsset(
    String key, {
    AssetBundle? bundle,
    String? name,
    String? declared,
  }) async {
    if (!isGeneric(declared)) return declared;

    _Sniffed? sniffed;
    try {
      final data = await (bundle ?? rootBundle).load(key);
      sniffed = _sniff(_Sample.of(Uint8List.sublistView(data)));
    } catch (e) {
      AppLogger.info("Could not load $key for its MIME type: $e");
    }

    return _decide(
      declared: declared,
      sniffed: sniffed,
      hints: [fromPath(name), fromPath(key)],
    );
  }

  /// Resolves [url] from the first bytes its server returns.
  ///
  /// Only a byte range is requested. Servers that honour ranges also let
  /// container formats such as DOCX be identified. The response's
  /// `Content-Type` is a hint ahead of the URL's extension, since servers
  /// often report generic types. [dio] must be the app's configured client,
  /// so requests keep its interceptors and certificate checks. When the
  /// request fails, the extensions of [name] and [url] are used.
  static Future<String?> fromNetwork(
    String url, {
    required Dio dio,
    String? name,
    String? declared,
  }) async {
    if (!isGeneric(declared)) return declared;

    String? reported;
    _Sniffed? sniffed;
    try {
      final head = await _fetchRange(dio, url, 0, _headLength);
      reported = head.headers.value(Headers.contentTypeHeader);
      final ranged = head.statusCode == HttpStatus.partialContent;
      final sample = _Sample(ranged ? _rangeTotal(head.headers) : null)
        ..add(0, head.bytes);

      sniffed = await _sniffRanges(
        sample,
        ranged ? (offset, count) => _refetch(dio, url, offset, count) : null,
        readHead: false,
      );
    } catch (e) {
      AppLogger.info("Could not fetch $url for its MIME type: $e");
    }

    return _decide(
      declared: declared,
      sniffed: sniffed,
      hints: [reported, fromPath(name), fromPath(url)],
    );
  }

  /// Resolves any media source the library works with.
  ///
  /// Bytes (`List<int>` or [ByteData]), [File]s and [XFile]s are read. A
  /// `data:` URI resolves to its declared type. Strings are treated as URLs
  /// or asset keys, like the media models do: assets are loaded from
  /// [bundle], and URLs are resolved from their extension unless
  /// [fetchRemote] is `true`, which fetches them with [dio] (then required).
  ///
  /// Throws an [ArgumentError] when [fetchRemote] is `true` without [dio].
  static Future<String?> fromSource(
    Object? source, {
    String? name,
    String? declared,
    AssetBundle? bundle,
    Dio? dio,
    bool fetchRemote = false,
  }) async {
    if (fetchRemote && dio == null) {
      throw ArgumentError.notNull("dio");
    }
    if (!isGeneric(declared)) return declared;

    switch (source) {
      case List<int> bytes:
        return resolve(bytes: bytes, name: name, declared: declared);
      case ByteData data:
        return resolve(
          bytes: Uint8List.sublistView(data),
          name: name,
          declared: declared,
        );
      case File file:
        return fromFile(file, name: name, declared: declared);
      case XFile file:
        return fromXFile(file, declared: declared);
      case Uri uri:
        return fromSource(
          "$uri",
          name: name,
          declared: declared,
          bundle: bundle,
          dio: dio,
          fetchRemote: fetchRemote,
        );
      case String value when _dataUriType(value) != null:
        return _decide(
          declared: declared,
          hints: [_dataUriType(value), fromPath(name)],
        );
      case String value when _isHttpUrl(value) && fetchRemote:
        return fromNetwork(value, dio: dio!, name: name, declared: declared);
      case String value when _isHttpUrl(value):
        return resolve(name: name, path: value, declared: declared);
      case String value:
        return fromAsset(value, bundle: bundle, name: name, declared: declared);
      default:
        return resolve(name: name, declared: declared);
    }
  }

  /// Returns the lower-case extension of a file name, path or URL without
  /// the dot, such as `pdf` for `https://host/Statement.PDF?download=1`.
  ///
  /// Returns `null` for `data:` URIs, dot-files and names without one.
  static String? extensionOf(String? path) {
    if (!path.hasValue) return null;
    var target = path!.trim();
    if (target.lower.startsWith("data:")) return null;
    if (_schemeRegex.hasMatch(target)) {
      target =
          Uri.tryParse(target)?.path ?? target.split(RegExp(r"[?#]")).first;
    }

    final name = target.split(_pathSeparatorRegex).last;
    final dot = name.lastIndexOf(".");
    if (dot <= 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).lower;
  }

  /// Returns the preferred extension for [mimeType] without the dot, such as
  /// `jpg` for `image/jpeg`. Parameters like `; charset=utf-8` are ignored.
  static String? extensionFor(String? mimeType) {
    final type = _normalise(mimeType);
    if (type == null) return null;
    return _typeExtensions[type] ?? mime.extensionFromMime(type);
  }

  static String? _normalise(String? mimeType) {
    final type = mimeType?.split(";").first.trim().lower;
    return type.hasValue ? type : null;
  }

  static String? _dataUriType(String value) {
    return _normalise(_dataUriRegex.firstMatch(value.trimLeft())?.group(1));
  }

  static bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.isScheme("http") || uri.isScheme("https"));
  }

  static Set<String> _typesOf(List<String> extensions) {
    return extensions.map((ext) => fromPath("file.$ext")).nonNulls.toSet();
  }

  // Deciding between declared types, content and hints.

  static String? _decide({
    String? declared,
    _Sniffed? sniffed,
    required List<String?> hints,
  }) {
    if (!isGeneric(declared)) return declared;
    final types = hints.map(_normalise).nonNulls.toList();
    if (sniffed != null) return _narrow(sniffed, types);

    return types.where((type) => !isGeneric(type)).firstOrNull ??
        (declared.hasValue ? declared : types.firstOrNull);
  }

  static String _narrow(_Sniffed sniffed, List<String> hints) {
    if (!sniffed.container) return sniffed.type;
    for (final hint in hints) {
      if (isGeneric(hint) || hint == sniffed.type) continue;
      if (_belongsTo(sniffed.type, hint)) return hint;
    }
    return sniffed.type;
  }

  static bool _belongsTo(String container, String type) {
    return switch (container) {
      AppMimeTypes.txt =>
        type.startsWith("text/") ||
            type.endsWith("+xml") ||
            type.endsWith("+json") ||
            _textualTypes.contains(type),
      AppMimeTypes.xml => type == "text/xml" || type.endsWith("+xml"),
      _ => _families[container]?.contains(type) ?? false,
    };
  }

  // Reading sources.

  /// Sniffs [sample], using [read] to fetch any range a signature needs
  /// beyond what has been read so far.
  static Future<_Sniffed?> _sniffRanges(
    _Sample sample,
    _RangeReader? read, {
    bool readHead = true,
  }) async {
    if (readHead && read != null) sample.add(0, await read(0, _headLength));

    for (var attempt = 0; ; attempt++) {
      final sniffed = _sniff(sample);
      final missing = sample.takeMissing();
      if (missing == null || read == null || attempt == _extraReads) {
        return sniffed;
      }
      final (offset, count) = missing;
      sample.add(offset, await read(offset, count));
    }
  }

  static Future<Uint8List> _collect(Stream<List<int>> stream, int count) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
      if (builder.length >= count) break;
    }
    final bytes = builder.takeBytes();
    if (bytes.length <= count) return bytes;
    return Uint8List.sublistView(bytes, 0, count);
  }

  static Future<({Uint8List bytes, Headers headers, int? statusCode})>
  _fetchRange(Dio client, String url, int offset, int count) async {
    final response = await client.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          HttpHeaders.rangeHeader: "bytes=$offset-${offset + count - 1}",
          HttpHeaders.acceptEncodingHeader: "identity",
        },
      ),
    );
    // Leaving the stream early closes the connection for the unread body.
    final bytes = await _collect(response.data!.stream, count);
    return (
      bytes: bytes,
      headers: response.headers,
      statusCode: response.statusCode,
    );
  }

  /// Fetches a later range, or nothing when the server ignores the range.
  static Future<List<int>> _refetch(
    Dio client,
    String url,
    int offset,
    int count,
  ) async {
    try {
      final range = await _fetchRange(client, url, offset, count);
      if (range.statusCode != HttpStatus.partialContent) return const [];
      return range.bytes;
    } catch (_) {
      return const [];
    }
  }

  static int? _rangeTotal(Headers headers) {
    final range = headers.value(HttpHeaders.contentRangeHeader);
    return int.tryParse(range?.split("/").last ?? "");
  }

  // Signatures. Checks that are short or printable also require bytes that
  // text never contains, so plain text isn't mistaken for binary formats.

  static _Sniffed? _sniff(_Sample sample) {
    final bytes = sample.head;
    if (bytes.isEmpty) return null;

    return _sniffImage(bytes) ??
        _sniffIsoMedia(bytes) ??
        _sniffAudio(sample) ??
        _sniffVideo(bytes) ??
        _sniffDocument(sample) ??
        _sniffArchive(bytes) ??
        _sniffFont(bytes) ??
        _sniffText(bytes) ??
        _sniffTransportStream(bytes);
  }

  static _Sniffed _exact(String type) => (type: type, container: false);

  static _Sniffed _container(String type) => (type: type, container: true);

  static _Sniffed? _sniffImage(Uint8List b) {
    if (_has(b, 0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return _exact(AppMimeTypes.png);
    }
    if (_has(b, 0, const [0xFF, 0xD8, 0xFF])) return _exact(AppMimeTypes.jpeg);
    if (_hasText(b, 0, "GIF87a") || _hasText(b, 0, "GIF89a")) {
      return _exact(AppMimeTypes.gif);
    }
    if (_isRiff(b, "WEBP")) return _exact(AppMimeTypes.webp);
    // Classic TIFF and BigTIFF, in both byte orders.
    if (_has(b, 0, const [0x49, 0x49, 0x2A, 0x00]) ||
        _has(b, 0, const [0x4D, 0x4D, 0x00, 0x2A]) ||
        _has(b, 0, const [0x49, 0x49, 0x2B, 0x00]) ||
        _has(b, 0, const [0x4D, 0x4D, 0x00, 0x2B])) {
      return _exact(AppMimeTypes.tiff);
    }
    // "BM" alone is too short; the DIB header that follows has a known size.
    if (_hasText(b, 0, "BM") &&
        const {12, 40, 52, 56, 64, 108, 124}.contains(_uint32le(b, 14))) {
      return _exact(AppMimeTypes.bmp);
    }
    if (_hasText(b, 0, "8BPS") && _has(b, 4, const [0x00])) {
      return _exact("image/vnd.adobe.photoshop");
    }
    if (_has(b, 0, const [0xFF, 0x0A]) ||
        _has(b, 0, const [0, 0, 0, 0x0C, 0x4A, 0x58, 0x4C, 0x20, 0x0D, 0x0A])) {
      return _exact("image/jxl");
    }
    // An icon directory with at least one image, whose first entry has its
    // reserved byte clear and at most one colour plane.
    if (_has(b, 0, const [0x00, 0x00, 0x01, 0x00]) &&
        _uint16le(b, 4) > 0 &&
        b.length >= 12 &&
        b[9] == 0 &&
        _uint16le(b, 10) <= 1) {
      return _exact("image/x-icon");
    }
    return null;
  }

  /// ISO base media files (MP4, MOV, 3GP, HEIC, AVIF) name their flavour in
  /// the brands of the leading `ftyp` box.
  static _Sniffed? _sniffIsoMedia(Uint8List b) {
    if (b.length < 12 || !_hasText(b, 4, "ftyp")) return _sniffQuickTime(b);

    final major = _latin1(b, 8, 4);
    final boxEnd = min(_uint32be(b, 0), b.length);
    final brands = {
      major,
      for (var i = 16; i + 4 <= boxEnd; i += 4) _latin1(b, i, 4),
    };

    return switch (major) {
      "avif" || "avis" => _exact(AppMimeTypes.avif),
      "heic" || "heix" || "heim" || "heis" => _exact(AppMimeTypes.heic),
      "hevc" || "hevx" || "hevm" || "hevs" => _exact("image/heic-sequence"),
      "mif1" || "msf1"
          when brands.contains("avif") || brands.contains("avis") =>
        _exact(AppMimeTypes.avif),
      "mif1" || "msf1"
          when brands.contains("heic") || brands.contains("heix") =>
        _exact(AppMimeTypes.heic),
      "mif1" => _exact(AppMimeTypes.heif),
      "msf1" => _exact("image/heif-sequence"),
      "crx " => _exact("image/x-canon-cr3"),
      "qt  " => _exact(AppMimeTypes.mov),
      "f4v " => _exact("video/x-f4v"),
      _ when major.startsWith("M4V") || brands.contains("M4V ") => _exact(
        "video/x-m4v",
      ),
      _ when const ["M4A", "M4B", "F4A", "F4B"].any(major.startsWith) => _exact(
        AppMimeTypes.m4a,
      ),
      _ when brands.contains("M4A ") => _exact(AppMimeTypes.m4a),
      _ when major.startsWith("3g2") => _exact("video/3gpp2"),
      _ when major.startsWith("3g") => _exact("video/3gpp"),
      _ => _container(AppMimeTypes.mp4),
    };
  }

  /// QuickTime files predating `ftyp` open with a movie or media atom whose
  /// size field, unlike text, holds non-printable bytes.
  static _Sniffed? _sniffQuickTime(Uint8List b) {
    if (b.length < 8) return null;
    const atoms = {"moov", "mdat", "wide", "free", "skip", "pnot"};
    if (!atoms.contains(_latin1(b, 4, 4))) return null;
    if (b.take(4).every((byte) => byte >= 0x20 && byte < 0x7F)) return null;
    return _exact(AppMimeTypes.mov);
  }

  static _Sniffed? _sniffAudio(_Sample sample) {
    final b = sample.head;
    if (_hasText(b, 0, "ID3")) return _sniffId3(sample);
    if (_isRiff(b, "WAVE")) return _exact(AppMimeTypes.wav);
    if (_hasText(b, 0, "FORM") &&
        (_hasText(b, 8, "AIFF") || _hasText(b, 8, "AIFC"))) {
      return _exact("audio/x-aiff");
    }
    if (_hasText(b, 0, "OggS") && _has(b, 4, const [0x00])) {
      return _sniffOgg(b);
    }
    if (_hasText(b, 0, "#!AMR-WB\n")) return _exact("audio/amr-wb");
    if (_hasText(b, 0, "#!AMR\n")) return _exact(AppMimeTypes.amr);
    if (_hasText(b, 0, "MThd") && _has(b, 4, const [0, 0, 0, 6])) {
      return _exact("audio/midi");
    }
    if (_hasText(b, 0, "caff") && _has(b, 4, const [0, 1])) {
      return _exact("audio/x-caf");
    }
    return _sniffAudioFrame(b);
  }

  /// Skips an ID3v2 tag to identify the audio that follows it.
  static _Sniffed? _sniffId3(_Sample sample) {
    final b = sample.head;
    if (b.length < 10 || b[3] > 4) return null;

    // The tag size is a 28-bit "syncsafe" integer, plus a 10-byte footer when
    // flagged.
    final size =
        (b[6] & 0x7F) << 21 |
        (b[7] & 0x7F) << 14 |
        (b[8] & 0x7F) << 7 |
        (b[9] & 0x7F);
    final footer = (b[5] & 0x10) != 0 ? 10 : 0;
    final frame = sample.read(10 + size + footer, 5);
    if (frame == null) return _exact(AppMimeTypes.mp3);
    return _sniffAudioFrame(frame) ?? _exact(AppMimeTypes.mp3);
  }

  static _Sniffed? _sniffAudioFrame(Uint8List b) {
    // FLAC's first metadata block is STREAMINFO (type 0), maybe flagged last.
    if (_hasText(b, 0, "fLaC") && b.length > 4 && (b[4] & 0x7F) == 0) {
      return _exact("audio/x-flac");
    }
    if (b.length < 3 || b[0] != 0xFF) return null;

    // ADTS: 12 sync bits, layer 00, then a valid sampling frequency index.
    if ((b[1] & 0xF6) == 0xF0 && ((b[2] >> 2) & 0x0F) < 13) {
      return _exact(AppMimeTypes.aac);
    }
    // MPEG audio: 11 sync bits, a defined version, layer II or III, and a
    // valid bitrate and sample rate.
    final version = (b[1] >> 3) & 0x03;
    final layer = (b[1] >> 1) & 0x03;
    if ((b[1] & 0xE0) == 0xE0 &&
        version != 1 &&
        (layer == 1 || layer == 2) &&
        (b[2] >> 4) != 0x0F &&
        ((b[2] >> 2) & 0x03) != 3) {
      return _exact(AppMimeTypes.mp3);
    }
    return null;
  }

  /// The first Ogg page carries the codec's identification header, after the
  /// 27-byte page header and its segment table.
  static _Sniffed _sniffOgg(Uint8List b) {
    final start = b.length > 26 ? 27 + b[26] : 28;
    if (_hasText(b, start, "\x80theora")) return _exact("video/ogg");
    if (_hasText(b, start, "OpusHead") ||
        _hasText(b, start, "\x01vorbis") ||
        _hasText(b, start, "Speex   ") ||
        _hasText(b, start, "\x7FFLAC")) {
      return _exact(AppMimeTypes.ogg);
    }
    return _container(AppMimeTypes.ogg);
  }

  static _Sniffed? _sniffVideo(Uint8List b) {
    if (_has(b, 0, const [0x1A, 0x45, 0xDF, 0xA3])) return _sniffEbml(b);
    if (_isRiff(b, "AVI ")) return _exact("video/x-msvideo");
    if (_hasText(b, 0, "FLV\x01")) return _exact("video/x-flv");
    if (_has(b, 0, const [
      0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, //
      0xA6, 0xD9, 0x00, 0xAA, 0x00, 0x62, 0xCE, 0x6C,
    ])) {
      return _container(_asf);
    }
    if (_has(b, 0, const [0x00, 0x00, 0x01, 0xBA]) ||
        _has(b, 0, const [0x00, 0x00, 0x01, 0xB3])) {
      return _exact("video/mpeg");
    }
    return null;
  }

  /// EBML: the DocType element near the start names the flavour.
  static _Sniffed _sniffEbml(Uint8List b) {
    if (_latin1(b, 4, 60).contains("webm")) {
      return _container(AppMimeTypes.webm);
    }
    return _container(_matroska);
  }

  /// MPEG transport streams repeat a `0x47` sync byte every 188 bytes, or
  /// every 192 in M2TS after a 4-byte timecode. Checked after text, since
  /// `0x47` is a printable `G`.
  static _Sniffed? _sniffTransportStream(Uint8List b) {
    bool syncs(int offset, int packet) {
      return b.length > offset + packet * 2 &&
          b[offset] == 0x47 &&
          b[offset + packet] == 0x47 &&
          b[offset + packet * 2] == 0x47;
    }

    if (syncs(0, 188) || syncs(4, 192)) return _exact("video/mp2t");
    return null;
  }

  static _Sniffed? _sniffDocument(_Sample sample) {
    final b = sample.head;
    if (_hasText(b, 0, "%PDF-")) return _exact(AppMimeTypes.pdf);
    if (_hasText(b, 0, r"{\rtf")) return _exact(AppMimeTypes.rtf);
    if (_hasText(b, 0, "%!PS")) return _exact("application/postscript");
    if (_has(b, 0, _zipEntry) || _has(b, 0, _zipEnd)) return _sniffZip(sample);
    if (_has(b, 0, const [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1])) {
      return _sniffCompoundFile(sample);
    }
    return null;
  }

  static const _zipEntry = [0x50, 0x4B, 0x03, 0x04];
  static const _zipDirectoryEntry = [0x50, 0x4B, 0x01, 0x02];
  static const _zipEnd = [0x50, 0x4B, 0x05, 0x06];

  static _Sniffed _sniffZip(_Sample sample) {
    final b = sample.head;
    final declared = _zipDeclaredType(b);
    if (declared != null) return _exact(declared);

    final names = _zipDirectoryNames(sample) ?? _zipLocalNames(b);
    for (final name in names) {
      if (name.startsWith("word/")) return _container(AppMimeTypes.docx);
      if (name.startsWith("xl/")) return _container(AppMimeTypes.xlsx);
      if (name.startsWith("ppt/")) return _container(AppMimeTypes.pptx);
    }
    return _container(AppMimeTypes.zip);
  }

  /// The type ODF and EPUB store, uncompressed, as the first entry.
  static String? _zipDeclaredType(Uint8List b) {
    if (!_has(b, 0, _zipEntry) || _uint16le(b, 8) != 0) return null;
    final nameLength = _uint16le(b, 26);
    if (_latin1(b, 30, nameLength) != "mimetype") return null;

    final start = 30 + nameLength + _uint16le(b, 28);
    final type = _latin1(b, start, min(_uint32le(b, 18), 128)).trim();
    return _typeRegex.hasMatch(type) ? type.lower : null;
  }

  /// Entry names from the central directory at the end of the archive, or
  /// `null` when it can't be read.
  static List<String>? _zipDirectoryNames(_Sample sample) {
    final length = sample.length;
    if (length == null) return null;
    final tailStart = max(0, length - _zipTailLength);
    final tail = sample.read(tailStart, length - tailStart);
    if (tail == null) return null;

    // The end-of-central-directory record is the last one in the archive.
    final end = _lastIndexOf(tail, _zipEnd, tail.length - 22);
    if (end < 0) return null;
    final size = _uint32le(tail, end + 12);
    final offset = _uint32le(tail, end + 16);
    // ZIP64 archives mark these fields 0xFFFFFFFF, which fails this check.
    if (size < 0 || offset < 0 || offset + size > length) return null;

    final directory = sample.read(offset, min(size, _zipDirectoryLimit));
    if (directory == null) return null;

    final names = <String>[];
    var entry = 0;
    while (entry + 46 <= directory.length &&
        _has(directory, entry, _zipDirectoryEntry)) {
      final nameLength = _uint16le(directory, entry + 28);
      names.add(_latin1(directory, entry + 46, nameLength));
      entry +=
          46 +
          nameLength +
          _uint16le(directory, entry + 30) +
          _uint16le(directory, entry + 32);
    }
    return names;
  }

  /// Entry names from the local headers in [b], for sources whose end can't
  /// be read.
  static List<String> _zipLocalNames(Uint8List b) {
    final names = <String>[];
    var entry = 0;
    while (entry + 30 <= b.length && _has(b, entry, _zipEntry)) {
      final nameLength = _uint16le(b, entry + 26);
      names.add(_latin1(b, entry + 30, nameLength));

      final dataStart = entry + 30 + nameLength + _uint16le(b, entry + 28);
      final hasDescriptor = (_uint16le(b, entry + 6) & 0x08) != 0;
      final compressedSize = _uint32le(b, entry + 18);
      // With a data descriptor the size follows the data, so the next entry
      // is found by its signature instead.
      final int next = hasDescriptor && compressedSize <= 0
          ? _indexOf(b, _zipEntry, dataStart)
          : dataStart + max(compressedSize, 0);
      if (next < 0) break;
      entry = next;
    }
    return names;
  }

  /// Legacy Office files are compound files; the stream names in their
  /// directory identify the application.
  static _Sniffed _sniffCompoundFile(_Sample sample) {
    final b = sample.head;
    final sectorShift = _uint16le(b, 30);
    final directorySector = _uint32le(b, 48);
    if ((sectorShift != 9 && sectorShift != 12) || directorySector < 0) {
      return _container(_cfb);
    }

    final sectorSize = 1 << sectorShift;
    final directory = sample.read(
      (directorySector + 1) * sectorSize,
      sectorSize * 4,
    );
    if (directory == null) return _container(_cfb);

    // Directory entries are 128 bytes long.
    final names = <String>{
      for (var entry = 0; entry + 128 <= directory.length; entry += 128)
        _directoryEntryName(directory, entry),
    };
    if (names.contains("WordDocument")) return _exact(AppMimeTypes.doc);
    if (names.contains("Workbook") || names.contains("Book")) {
      return _exact(AppMimeTypes.xls);
    }
    if (names.contains("PowerPoint Document")) return _exact(AppMimeTypes.ppt);
    if (names.any((name) => name.startsWith("__substg1.0_"))) {
      return _exact("application/vnd.ms-outlook");
    }
    return _container(_cfb);
  }

  /// A directory entry's UTF-16 name, whose byte length (including the
  /// terminator) follows the 64-byte name field.
  static String _directoryEntryName(Uint8List directory, int entry) {
    final nameEnd = min(_uint16le(directory, entry + 64), 64) - 2;
    return String.fromCharCodes([
      for (var i = 0; i < nameEnd; i += 2) _uint16le(directory, entry + i),
    ]);
  }

  static _Sniffed? _sniffArchive(Uint8List b) {
    if (_has(b, 0, const [0x1F, 0x8B, 0x08])) {
      return _exact("application/gzip");
    }
    if (_has(b, 0, const [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C])) {
      return _exact("application/x-7z-compressed");
    }
    if (_hasText(b, 0, "Rar!\x1A\x07")) {
      return _exact("application/x-rar-compressed");
    }
    // "BZh", a block size digit, then the block magic (BCD pi).
    if (_hasText(b, 0, "BZh") &&
        _has(b, 4, const [0x31, 0x41, 0x59, 0x26, 0x53, 0x59])) {
      return _exact("application/x-bzip2");
    }
    return null;
  }

  static _Sniffed? _sniffFont(Uint8List b) {
    // WOFF headers end their first 16 bytes with a reserved zero field.
    if ((_hasText(b, 0, "wOFF") || _hasText(b, 0, "wOF2")) &&
        _has(b, 14, const [0, 0])) {
      return _exact(b[3] == 0x32 ? "font/woff2" : "font/woff");
    }
    // Table counts and collection versions sit well below 256.
    if (b.length < 12 || b[4] != 0 || b[5] == 0) return null;
    if (_hasText(b, 0, "OTTO")) return _exact("font/otf");
    if (_hasText(b, 0, "ttcf")) return _exact("font/collection");
    if (_has(b, 0, const [0x00, 0x01, 0x00, 0x00])) return _exact("font/ttf");
    return null;
  }

  static _Sniffed? _sniffText(Uint8List bytes) {
    final b = Uint8List.sublistView(bytes, 0, min(bytes.length, _textWindow));
    if (_has(b, 0, const [0xFE, 0xFF]) || _has(b, 0, const [0xFF, 0xFE])) {
      return _container(AppMimeTypes.txt);
    }
    final start = _has(b, 0, const [0xEF, 0xBB, 0xBF]) ? 3 : 0;
    if (!_isUtf8Text(b, start)) return null;

    final text = utf8
        .decode(Uint8List.sublistView(b, start), allowMalformed: true)
        .trimLeft()
        .lower;
    final isMarkup =
        text.startsWith("<?xml") ||
        text.startsWith("<!--") ||
        text.startsWith("<!doctype svg");
    if (text.startsWith("<svg") || (isMarkup && text.contains("<svg"))) {
      return _exact(AppMimeTypes.svg);
    }
    if (text.startsWith("<!doctype html") || text.startsWith("<html")) {
      return _exact(AppMimeTypes.html);
    }
    if (text.startsWith("<?xml")) return _container(AppMimeTypes.xml);
    return _container(AppMimeTypes.txt);
  }

  /// Whether [b] from [start] is UTF-8 without the control characters that
  /// fill binary data. A sequence cut off at the end is accepted, as [b] may
  /// be the start of a longer source.
  static bool _isUtf8Text(Uint8List b, int start) {
    if (start >= b.length) return false;
    var i = start;
    while (i < b.length) {
      final length = _textCharacterLength(b, i);
      if (length < 0) return false;
      if (length == 0) return true;
      i += length;
    }
    return true;
  }

  /// The byte length of the text character at [i]: -1 for a control
  /// character or invalid UTF-8, and 0 when [b] ends mid-character.
  static int _textCharacterLength(Uint8List b, int i) {
    final byte = b[i];
    if (byte == 0x7F) return -1;
    if (byte < 0x20) return _textControls.contains(byte) ? 1 : -1;
    if (byte < 0x80) return 1;

    final trailing = switch (byte) {
      >= 0xC2 && <= 0xDF => 1,
      >= 0xE0 && <= 0xEF => 2,
      >= 0xF0 && <= 0xF4 => 3,
      _ => -1,
    };
    if (trailing < 0) return -1;

    final available = min(trailing, b.length - 1 - i);
    for (var k = 1; k <= available; k++) {
      if ((b[i + k] & 0xC0) != 0x80) return -1;
    }
    return available < trailing ? 0 : trailing + 1;
  }

  /// Tab, line feed, form feed, carriage return and escape.
  static const _textControls = {0x09, 0x0A, 0x0C, 0x0D, 0x1B};

  // Byte helpers. Out-of-range reads return -1 or `false` rather than throw.

  static bool _has(Uint8List b, int offset, List<int> signature) {
    if (offset < 0 || b.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (b[offset + i] != signature[i]) return false;
    }
    return true;
  }

  static bool _hasText(Uint8List b, int offset, String signature) {
    return _has(b, offset, signature.codeUnits);
  }

  static bool _isRiff(Uint8List b, String format) {
    return _hasText(b, 0, "RIFF") && _hasText(b, 8, format);
  }

  static int _lastIndexOf(Uint8List b, List<int> signature, int start) {
    for (var i = min(start, b.length - signature.length); i >= 0; i--) {
      if (_has(b, i, signature)) return i;
    }
    return -1;
  }

  static int _indexOf(Uint8List b, List<int> signature, int start) {
    for (var i = max(start, 0); i + signature.length <= b.length; i++) {
      if (_has(b, i, signature)) return i;
    }
    return -1;
  }

  static String _latin1(Uint8List b, int offset, int count) {
    if (offset < 0 || count <= 0 || offset >= b.length) return "";
    return String.fromCharCodes(b, offset, min(offset + count, b.length));
  }

  static int _uint16le(Uint8List b, int offset) {
    if (offset < 0 || offset + 2 > b.length) return -1;
    return b[offset] | b[offset + 1] << 8;
  }

  static int _uint32le(Uint8List b, int offset) {
    if (offset < 0 || offset + 4 > b.length) return -1;
    return ByteData.sublistView(b).getUint32(offset, Endian.little);
  }

  static int _uint32be(Uint8List b, int offset) {
    if (offset < 0 || offset + 4 > b.length) return -1;
    return ByteData.sublistView(b).getUint32(offset, Endian.big);
  }
}

/// What is known of a source: the ranges read so far and, when known, its
/// total [length].
final class _Sample {
  _Sample(this.length);

  _Sample.of(List<int> bytes) : length = bytes.length {
    add(0, bytes);
  }

  final int? length;
  final _ranges = <(int, Uint8List)>[];
  (int, int)? _missing;

  /// The bytes read from the start of the source.
  Uint8List get head {
    for (final (offset, bytes) in _ranges) {
      if (offset == 0) return bytes;
    }
    return Uint8List(0);
  }

  void add(int offset, List<int> bytes) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    _ranges.add((offset, data));
  }

  /// Returns [count] bytes from [offset], clipped to the source's length.
  ///
  /// Returns `null` when they haven't been read, and records the range so an
  /// asynchronous caller can fetch it and sniff again.
  Uint8List? read(int offset, int count) {
    if (offset < 0 || count < 0) return null;
    final total = length;
    final end = total == null ? offset + count : min(offset + count, total);
    if (end <= offset) return Uint8List(0);

    for (final (start, bytes) in _ranges) {
      if (offset >= start && end <= start + bytes.length) {
        return Uint8List.sublistView(bytes, offset - start, end - start);
      }
    }
    _missing ??= (offset, end - offset);
    return null;
  }

  (int, int)? takeMissing() {
    final missing = _missing;
    _missing = null;
    return missing;
  }
}
