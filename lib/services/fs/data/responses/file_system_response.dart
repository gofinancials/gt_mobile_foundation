import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

class FsError {
  final FsErrorType type;
  final Object? error;
  final StackTrace? stackTrace;

  const FsError({required this.type, this.error, this.stackTrace});

  bool get isTooLarge => type == .oversized;
  bool get isEmpty => type == .empty;
  bool get isUnknown => type == .unknown;
}

class FsResponse extends Equatable {
  final File? file;
  final String? name;
  final String? mimeType;
  final FsError? error;
  final FsDocumentType type;

  const FsResponse({
    this.error,
    this.file,
    this.name,
    required this.type,
    this.mimeType,
  });

  bool get hasError => error != null;
  bool get hasFile => file != null;
  bool get isImage => type == .image;

  Uri? get uri => file?.uri;

  @override
  List<Object?> get props => [file, name, error, type, mimeType];
}
