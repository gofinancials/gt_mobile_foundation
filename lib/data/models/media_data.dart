import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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

  @override
  bool get hasName => name != null || (name?.isNotEmpty ?? false);

  bool get _hasData => document != null;

  @override
  bool get hasId => id != null;

  @override
  bool get isValid {
    if (!_hasData) return false;
    return isString || isUrl || isFile;
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
    if ("$document".startsWith("data:")) return true;
    return document is File;
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
    if ("$document".startsWith("data:")) {
      final base64 = "$document".replaceAll("data:", "");
      final data = base64Decode(base64);
      return File.fromRawPath(data);
    }
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
    return AppRegex.audioFileRegex.hasMatch(file?.path ?? fileUrl ?? "");
  }

  bool get isVideo {
    if (mediaType != null) return mediaType == .video;
    return AppRegex.videoFileRegex.hasMatch(file?.path ?? fileUrl ?? "");
  }

  bool get isYoutube {
    if (mediaType != null) return mediaType == .youtube;
    return AppRegex.youtubeRegex.hasMatch(file?.path ?? fileUrl ?? "");
  }

  @override
  String get mimeType {
    if (contentType.hasValue) return contentType!;

    final ext = fileName.split(".").tryLast?.lower;
    String prefix = "*";

    if (isAudio) prefix = "audio";
    if (isVideo) prefix = "video";

    return "$prefix/${ext ?? "*"}";
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

  @override
  bool get hasName => name != null || (name?.isNotEmpty ?? false);

  bool get _hasData => document != null;

  @override
  bool get hasId => id != null;

  @override
  bool get isValid {
    if (!_hasData) return false;
    return isString || isUrl || isFile;
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
    if ("$document".startsWith("data:")) return true;
    return document is File;
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
    if ("$document".startsWith("data:")) {
      final base64 = "$document".replaceAll("data:", "");
      final data = base64Decode(base64);
      return File.fromRawPath(data);
    }
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

  @override
  String get mimeType {
    if (contentType.hasValue) return contentType!;

    final ext = fileName.split(".").tryLast?.lower;
    String prefix = "*";

    return "$prefix/${ext ?? "*"}";
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

  bool get isImage {
    return AppRegex.imageRegex.hasMatch(file?.path ?? "");
  }

  bool get _isPng {
    return file?.path.lower.endsWith('.png') ?? false;
  }

  bool get _isWebp {
    return file?.path.lower.endsWith('.webp') ?? false;
  }

  bool get _isJpeg {
    return file?.path.lower.endsWith(r'.jp(e)?g') ?? false;
  }

  bool get isIcon {
    if (!_hasData) return false;
    return imageData is IconData;
  }

  @override
  String get mimeType {
    if (contentType.hasValue) return contentType!;

    if (_isPng) return AppMimeTypes.png;
    if (_isJpeg) return AppMimeTypes.jpeg;
    if (_isWebp) return AppMimeTypes.webp;
    if (isImage) return AppMimeTypes.image;

    return "*/*";
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
