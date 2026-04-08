import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

enum MediaOrigin { network, asset, file, memory, invalid }

enum MediaType {
  audio,
  video,
  youtube;

  const MediaType();

  bool get isYoutubeMedia => this == MediaType.youtube;
  bool get isAudioMedia => this == MediaType.audio;
  bool get isVideoMedia => this == MediaType.video;

  static MediaType fromString(String? value) {
    return switch (value) {
      "youtube" => youtube,
      "video" => video,
      _ => audio,
    };
  }
}

abstract class MediaData<T> {
  bool get isValid;
  bool get isUrl;
  bool get isString;
  bool get isFile;
  bool get hasId;
  bool get hasName;

  String get fileName;

  String? get fileUrl;
  String? get filePath;
  File? get file;

  String get mimeType;
}

class AppMediaData<T> extends Equatable implements MediaData<T> {
  final T document;
  final String? id;
  final String? name;
  final String? contentType;
  final String? createdAt;
  final MediaType? mediaType;

  const AppMediaData({
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

  @override
  String get mimeType {
    if (contentType.hasValue) return contentType!;

    final ext = fileName.split(".").tryLast?.lower;
    String prefix = "*";

    return "$prefix/${ext ?? "*"}";
  }

  MediaOrigin get mediaOrigin {
    if (document is File) return MediaOrigin.file;
    if (document is Uint8List) return MediaOrigin.memory;
    if (document is String) {
      if (AppRegex.urlRegex.hasMatch(document as String)) {
        return MediaOrigin.network;
      }
      return MediaOrigin.asset;
    }

    return MediaOrigin.invalid;
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

class AppImageData<T> extends Equatable implements MediaData<T> {
  final T imageData;
  final String? id;
  final String? name;
  final String? createdAt;
  final String? contentType;

  const AppImageData({
    required this.imageData,
    this.name,
    this.id,
    this.createdAt,
    this.contentType,
  });

  @override
  bool get hasId => id != null;

  @override
  bool get hasName => name != null || (name?.isNotEmpty ?? false);

  bool get _hasData => imageData != null;

  @override
  bool get isValid {
    if (!_hasData) return false;
    return isString || isUrl || isFile;
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
  ];
}
