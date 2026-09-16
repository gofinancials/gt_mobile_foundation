import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// Defines the structure of generic media data containing its type and metadata.
abstract class AppMediaData<T> {
  /// Returns `true` if the media data is valid and accessible.
  bool get isValid;

  /// Returns `true` if the media is hosted on a remote URL.
  bool get isUrl;

  /// Returns `true` if the underlying data is a string (e.g., URL or asset path).
  bool get isString;

  /// Returns `true` if the underlying data is a local file.
  bool get isFile;

  /// Returns `true` if the media has a unique identifier.
  bool get hasId;

  /// Returns `true` if the media has an assigned name.
  bool get hasName;

  /// Returns the name of the file, parsing it from the path or URL if not explicitly set.
  String get fileName;

  /// Returns the file URL if [isUrl] is true, otherwise `null`.
  String? get fileUrl;

  /// Returns the local file path or asset path if applicable, otherwise `null`.
  String? get filePath;

  /// Returns the [File] object if [isFile] is true, otherwise `null`.
  File? get file;

  /// Returns the MIME type (e.g., 'video/mp4', 'image/png') of the media data.
  String get mimeType;
}

/// Represents audio and video media data, including YouTube links.
///
/// This model encapsulates a media payload ([document]), which can be a URL string,
/// a local [File], or raw bytes, along with relevant metadata such as [contentType]
/// and [mediaType].
class AppAvData<T> extends Equatable implements AppMediaData<T> {
  final T document;
  final String? id;
  final String? name;
  final String? contentType;
  final String? createdAt;
  final AppMediaType? mediaType;

  const AppAvData({
    required this.document,
    this.contentType,
    this.name,
    this.createdAt,
    this.id,
    this.mediaType,
  });

  /// Creates in-memory audio or video from raw [bytes].
  ///
  /// The media kind is detected from [mediaType], a specific [contentType],
  /// the bytes' content, then [name].
  const AppAvData.memory(
    Uint8List bytes, {
    this.contentType,
    this.name,
    this.createdAt,
    this.id,
    this.mediaType,
  }) : document = bytes as T;

  @override
  bool get hasName => name != null || (name?.isNotEmpty ?? false);

  bool get _hasData => document != null;

  @override
  bool get hasId => id != null;

  @override
  bool get isValid {
    if (!_hasData) return false;
    return isString || isUrl || isFile || isBytes;
  }

  @override
  bool get isString {
    if (!_hasData) return false;
    if ("$document".startsWith("data:")) return false;
    return document is String;
  }

  @override
  bool get isUrl {
    if (!isString) return false;
    return AppRegex.urlRegex.hasMatch(document as String);
  }

  @override
  bool get isFile {
    if (!_hasData) return false;
    return document is File;
  }

  /// Returns `true` if the media is held in memory as raw bytes.
  bool get isBytes {
    if (!_hasData) return false;
    return document is Uint8List;
  }

  /// Returns the in-memory media bytes if [isBytes] is true, otherwise `null`.
  Uint8List? get bytesData {
    if (!isBytes) return null;
    return document as Uint8List;
  }

  @override
  String get fileName {
    if (hasName) return name!;
    if (!isValid) return "";
    if (isString) {
      return (document as String);
    }
    return file?.path.split('/').tryLast ?? "";
  }

  @override
  File? get file {
    if (!isFile) return null;
    return document as File;
  }

  @override
  String? get filePath {
    if (!isString) return null;
    return document as String;
  }

  @override
  String? get fileUrl {
    if (!isUrl) return null;
    return document as String;
  }

  bool get isAudio {
    if (mediaType != null) return mediaType == .audio;
    if (isBytes) return _isBytesOfType("audio", AppRegex.audioFileRegex);
    return AppRegex.audioFileRegex.hasMatch(file?.path ?? fileUrl ?? "");
  }

  bool get isVideo {
    if (mediaType != null) return mediaType == .video;
    if (isBytes) return _isBytesOfType("video", AppRegex.videoFileRegex);
    return AppRegex.videoFileRegex.hasMatch(file?.path ?? fileUrl ?? "");
  }

  /// Detects in-memory media of [type] from a specific [contentType], then
  /// the bytes' content (narrowed by [name]), then [name] alone.
  bool _isBytesOfType(String type, RegExp nameRegex) {
    if (!AppMimeResolver.isGeneric(contentType)) {
      return contentType!.startsWith("$type/");
    }
    if (AppMimeResolver.sniff(bytesData!) == null) {
      return nameRegex.hasMatch(name ?? "");
    }
    final resolved = AppMimeResolver.resolve(bytes: bytesData, name: name);
    return resolved!.startsWith("$type/");
  }

  bool get isYoutube {
    if (mediaType != null) return mediaType == .youtube;
    return AppRegex.youtubeRegex.hasMatch(file?.path ?? fileUrl ?? "");
  }

  /// Resolves the MIME type without I/O: a specific [contentType], then
  /// in-memory bytes' content, then the extension of [name], the file path or
  /// the URL. Unresolved media falls back to `video/*`, `audio/*` or `*/*`.
  ///
  /// Use [resolveMimeType] to identify files, assets and URLs by content.
  @override
  String get mimeType {
    return _settleMimeType(
      AppMimeResolver.resolve(
        bytes: bytesData,
        name: name,
        path: file?.path ?? filePath,
        declared: contentType,
      ),
    );
  }

  /// Resolves the MIME type from the media's content rather than its name.
  ///
  /// Reads in-memory bytes, the file's header or the bundled asset from
  /// [bundle]. URLs are fetched only when [fetchRemote] is `true`, using
  /// [dio], which is then required. A specific [contentType] still wins, and
  /// anything unresolved falls back to [mimeType].
  Future<String> resolveMimeType({
    bool fetchRemote = false,
    AssetBundle? bundle,
    Dio? dio,
  }) async {
    if (isYoutube) return mimeType;
    final resolved = await AppMimeResolver.fromSource(
      document,
      name: name,
      declared: contentType,
      bundle: bundle,
      dio: dio,
      fetchRemote: fetchRemote,
    );
    if (AppMimeResolver.isGeneric(resolved)) return mimeType;
    return _settleMimeType(resolved);
  }

  /// Audio in a container shared with video, such as MP4, is typed as audio
  /// when [mediaType] says so.
  static const _audioContainers = {
    "audio/mp4",
    "audio/webm",
    "audio/ogg",
    "audio/3gpp",
    "audio/3gpp2",
    "audio/x-matroska",
  };

  String _settleMimeType(String? resolved) {
    if (!AppMimeResolver.isGeneric(contentType)) return contentType!;
    if (!AppMimeResolver.isGeneric(resolved)) return _asMediaType(resolved!);
    if (isVideo || isYoutube) return AppMimeTypes.video;
    if (isAudio) return AppMimeTypes.audio;
    return resolved ?? AppMimeTypes.any;
  }

  String _asMediaType(String type) {
    if (mediaType != .audio || !type.startsWith("video/")) return type;
    final audio = type.replaceFirst("video/", "audio/");
    return _audioContainers.contains(audio) ? audio : type;
  }

  AppMediaOrigin get mediaOrigin {
    if (document is File) return .file;
    if (document is Uint8List) return .memory;
    if (document is String) {
      if (AppRegex.urlRegex.hasMatch(document as String)) {
        return .network;
      }
      return .asset;
    }

    return .invalid;
  }

  @override
  List<Object?> get props => [
    id,
    document,
    name,
    createdAt,
    file,
    fileName,
    filePath,
    fileUrl,
    isAudio,
    isVideo,
    isYoutube,
    mimeType,
  ];
}

/// Represents standard document media data, such as PDFs, Word documents, or CSV files.
///
/// This model encapsulates the document payload, which can be accessed from a network URL,
/// a local [File], or raw bytes, and provides utility methods for resolving its MIME type.
class AppDocumentData<T> extends Equatable implements AppMediaData<T> {
  final T document;
  final String? id;
  final String? name;
  final String? contentType;
  final String? createdAt;
  final AppMediaType? mediaType;

  const AppDocumentData(
    this.document, {
    this.contentType,
    this.name,
    this.createdAt,
    this.id,
    this.mediaType,
  });

  /// Creates an in-memory document from raw [bytes].
  const AppDocumentData.memory(
    Uint8List bytes, {
    this.contentType,
    this.name,
    this.createdAt,
    this.id,
    this.mediaType,
  }) : document = bytes as T;

  @override
  bool get hasName => name != null || (name?.isNotEmpty ?? false);

  bool get _hasData => document != null;

  @override
  bool get hasId => id != null;

  @override
  bool get isValid {
    if (!_hasData) return false;
    return isString || isUrl || isFile || isBytes;
  }

  @override
  bool get isString {
    if (!_hasData) return false;
    if ("$document".startsWith("data:")) return false;
    return document is String;
  }

  @override
  bool get isUrl {
    if (!isString) return false;
    return AppRegex.urlRegex.hasMatch(document as String);
  }

  @override
  bool get isFile {
    if (!_hasData) return false;
    return document is File;
  }

  /// Returns `true` if the document is held in memory as raw bytes.
  bool get isBytes {
    if (!_hasData) return false;
    return document is Uint8List;
  }

  /// Returns the in-memory document bytes if [isBytes] is true, otherwise
  /// `null`.
  Uint8List? get bytesData {
    if (!isBytes) return null;
    return document as Uint8List;
  }

  @override
  String get fileName {
    if (hasName) return name!;
    if (!isValid) return "";
    if (isString) {
      return (document as String);
    }
    return file?.path.split('/').tryLast ?? "";
  }

  @override
  File? get file {
    if (!isFile) return null;
    return document as File;
  }

  @override
  String? get filePath {
    if (!isString) return null;
    return document as String;
  }

  @override
  String? get fileUrl {
    if (!isUrl) return null;
    return document as String;
  }

  /// Resolves the MIME type without I/O: a specific [contentType], then
  /// in-memory bytes' content, then the extension of [name], the file path or
  /// the URL, falling back to `*/*`.
  ///
  /// Use [resolveMimeType] to identify files, assets and URLs by content.
  @override
  String get mimeType {
    final mime = AppMimeResolver.resolve(
      bytes: bytesData,
      name: name,
      path: file?.path ?? filePath,
      declared: contentType,
    );
    return mime ?? AppMimeTypes.any;
  }

  /// Resolves the MIME type from the document's content rather than its name.
  ///
  /// Reads in-memory bytes, the file's header or the bundled asset from
  /// [bundle]. URLs are fetched only when [fetchRemote] is `true`, using
  /// [dio], which is then required. A specific [contentType] still wins, and
  /// anything unresolved falls back to [mimeType].
  Future<String> resolveMimeType({
    bool fetchRemote = false,
    AssetBundle? bundle,
    Dio? dio,
  }) async {
    final resolved = await AppMimeResolver.fromSource(
      document,
      name: name,
      declared: contentType,
      bundle: bundle,
      dio: dio,
      fetchRemote: fetchRemote,
    );
    return AppMimeResolver.isGeneric(resolved) ? mimeType : resolved!;
  }

  AppMediaOrigin get mediaOrigin {
    if (document is File) return .file;
    if (document is Uint8List) return .memory;
    if (document is String) {
      if (AppRegex.urlRegex.hasMatch(document as String)) {
        return .network;
      }
      return .asset;
    }

    return .invalid;
  }

  @override
  List<Object?> get props => [
    id,
    document,
    name,
    createdAt,
    file,
    fileName,
    filePath,
    fileUrl,
    mimeType,
  ];
}

/// Represents image media data.
///
/// This model supports a wide variety of image sources including network URLs,
/// local assets, file system images, raw bytes, and Flutter [IconData].
/// It provides utility getters to seamlessly convert the raw data into Flutter
/// image providers (e.g., [NetworkImage], [FileImage], [AssetImage], [MemoryImage]).
class AppImageData<T> extends Equatable implements AppMediaData<T> {
  final T imageData;
  final String? id;
  final String? name;
  final String? createdAt;
  final String? contentType;

  const AppImageData(
    this.imageData, {
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  });

  const AppImageData.asset(
    String assetPath, {
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  }) : imageData = assetPath as T;

  const AppImageData.network(
    String imageUrl, {
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  }) : imageData = imageUrl as T;

  const AppImageData.bytes(
    Uint8List bytes, {
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  }) : imageData = bytes as T;

  const AppImageData.file(
    File file, {
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  }) : imageData = file as T;

  const AppImageData.icon(
    IconData iconData, {
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  }) : imageData = iconData as T;

  @override
  bool get hasId => id != null;

  @override
  bool get hasName => name != null || (name?.isNotEmpty ?? false);

  bool get _hasData => imageData != null;

  @override
  bool get isValid {
    if (!_hasData) return false;
    return isString || isUrl || isFile || isIcon || isBytes;
  }

  @override
  bool get isString {
    if (!_hasData) return false;
    return imageData is String;
  }

  @override
  @override
  bool get isUrl {
    if (!isString) return false;
    String imageUrl = imageData as String;
    if (imageUrl.startsWith("assets")) return false;
    if (imageUrl.startsWith("data:")) return true;
    return AppRegex.urlRegex.hasMatch(imageData as String);
  }

  @override
  bool get isFile {
    if (!_hasData) return false;
    return imageData is File;
  }

  bool get isBytes {
    if (!_hasData) return false;
    return imageData is Uint8List;
  }

  @override
  String get fileName {
    if (hasName) return name!;
    if (!isValid) return "";
    if (isString) {
      return (imageData as String);
    }
    return file?.path.split('/').tryLast ?? "";
  }

  @override
  File? get file {
    if (!isFile) return null;
    return imageData as File;
  }

  @override
  String? get filePath {
    if (!isString) return null;
    return imageData as String;
  }

  @override
  String? get fileUrl {
    if (!isUrl) return null;
    return imageData as String;
  }

  IconData? get iconData {
    if (!isIcon) return null;
    return imageData as IconData;
  }

  Uint8List? get bytesData {
    if (!isBytes) return null;
    return imageData as Uint8List;
  }

  MemoryImage? get bytesImageData {
    if (!isBytes) return null;
    return MemoryImage(bytesData!);
  }

  AssetImage? get stringImageData {
    if (!isString) return null;
    return AssetImage(filePath!);
  }

  NetworkImage? get urlImageData {
    if (!isUrl) return null;
    return NetworkImage(fileUrl!);
  }

  FileImage? get fileImageData {
    if (file == null) return null;
    return FileImage(file!);
  }

  /// Returns `true` when [mimeType] resolves to an image type.
  bool get isImage {
    if (isIcon) return false;
    return mimeType.startsWith("image/");
  }

  bool get isIcon {
    if (!_hasData) return false;
    return imageData is IconData;
  }

  /// Resolves the MIME type without I/O: a specific [contentType], then
  /// in-memory bytes' content, then the extension of [name], the file path,
  /// the asset key or the URL (or a `data:` URI's declared type), falling
  /// back to `*/*`.
  ///
  /// Use [resolveMimeType] to identify files, assets and URLs by content.
  @override
  String get mimeType {
    final mime = AppMimeResolver.resolve(
      bytes: bytesData,
      name: name,
      path: file?.path ?? filePath,
      declared: contentType,
    );
    return mime ?? AppMimeTypes.any;
  }

  /// Resolves the MIME type from the image's content rather than its name.
  ///
  /// Reads in-memory bytes, the file's header or the bundled asset from
  /// [bundle]. URLs are fetched only when [fetchRemote] is `true`, using
  /// [dio], which is then required. A specific [contentType] still wins, and
  /// anything unresolved, including icons, falls back to [mimeType].
  Future<String> resolveMimeType({
    bool fetchRemote = false,
    AssetBundle? bundle,
    Dio? dio,
  }) async {
    if (isIcon) return mimeType;
    final resolved = await AppMimeResolver.fromSource(
      imageData,
      name: name,
      declared: contentType,
      bundle: bundle,
      dio: dio,
      fetchRemote: fetchRemote,
    );
    return AppMimeResolver.isGeneric(resolved) ? mimeType : resolved!;
  }

  @override
  List<Object?> get props => [
    filePath,
    id,
    imageData,
    name,
    createdAt,
    file,
    fileName,
    fileUrl,
    iconData,
  ];
}
